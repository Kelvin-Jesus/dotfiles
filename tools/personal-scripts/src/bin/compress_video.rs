use std::collections::BTreeMap;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode, Stdio};

const VIDEO_EXTENSIONS: &[&str] = &["mp4", "mkv", "avi", "mov", "flv", "webm", "ts", "m4v"];

#[derive(Default)]
struct FolderStats {
    count: usize,
    bytes: u64,
}

fn usage() {
    eprintln!("Usage: compress-video [--dry-run] [--crf <20-28>] [--preset <name>] [path]");
    eprintln!("Defaults: --crf 24 --preset faster, path is current directory");
}

fn expand_tilde(input: &str) -> PathBuf {
    if input == "~" {
        return env::var_os("HOME").map_or_else(|| input.into(), PathBuf::from);
    }
    if let Some(rest) = input.strip_prefix("~/") {
        if let Some(home) = env::var_os("HOME") {
            return PathBuf::from(home).join(rest);
        }
    }
    input.into()
}

fn is_video(path: &Path) -> bool {
    path.extension()
        .and_then(|value| value.to_str())
        .map(str::to_ascii_lowercase)
        .is_some_and(|ext| VIDEO_EXTENSIONS.contains(&ext.as_str()))
}

fn collect_videos(root: &Path, out: &mut Vec<PathBuf>) {
    let Ok(entries) = fs::read_dir(root) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let Ok(kind) = entry.file_type() else {
            continue;
        };
        if kind.is_dir() {
            if !entry.file_name().to_string_lossy().starts_with('.') {
                collect_videos(&path, out);
            }
        } else if kind.is_file() && is_video(&path) {
            out.push(path);
        }
    }
}

fn command_exists(name: &str) -> bool {
    Command::new(name)
        .arg("-version")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|status| status.success())
}

fn probe(path: &Path, entry: &str) -> Option<String> {
    let output = Command::new("ffprobe")
        .args([
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            entry,
            "-of",
            "default=noprint_wrappers=1:nokey=1",
        ])
        .arg(path)
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    let value = String::from_utf8_lossy(&output.stdout).trim().to_owned();
    (!value.is_empty() && value != "N/A").then_some(value)
}

fn format_size(bytes: i128) -> String {
    let sign = if bytes < 0 { "-" } else { "" };
    let bytes = bytes.unsigned_abs() as f64;
    let (value, unit) = if bytes >= 1_073_741_824.0 {
        (bytes / 1_073_741_824.0, "GB")
    } else if bytes >= 1_048_576.0 {
        (bytes / 1_048_576.0, "MB")
    } else if bytes >= 1024.0 {
        (bytes / 1024.0, "KB")
    } else {
        return format!("{sign}{} B", bytes as u64);
    };
    format!("{sign}{value:.2} {unit}")
}

fn relative_folder(path: &Path, base: &Path) -> String {
    path.parent()
        .and_then(|parent| parent.strip_prefix(base).ok())
        .filter(|relative| !relative.as_os_str().is_empty())
        .map_or_else(|| ".".to_owned(), |relative| relative.display().to_string())
}

fn temporary_path(path: &Path) -> PathBuf {
    let stem = path.file_stem().unwrap_or_default().to_string_lossy();
    let extension = path.extension().unwrap_or_default().to_string_lossy();
    path.with_file_name(format!("{stem}_tmp_compressed.{extension}"))
}

fn run() -> Result<(), String> {
    let mut args = env::args().skip(1);
    let mut dry_run = false;
    let mut crf = 24_u8;
    let mut preset = "faster".to_owned();
    let mut target = None;
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "-h" | "--help" => {
                usage();
                return Ok(());
            }
            "--dry-run" => dry_run = true,
            "--crf" => {
                let value = args.next().ok_or("--crf requires an integer value")?;
                crf = value
                    .parse()
                    .map_err(|_| "--crf requires an integer value")?;
                if !(0..=51).contains(&crf) {
                    return Err("--crf must be between 0 and 51".into());
                }
            }
            "--preset" => preset = args.next().ok_or("--preset requires a value")?,
            _ if arg.starts_with('-') => return Err(format!("unknown option: {arg}")),
            _ if target.is_none() => target = Some(expand_tilde(&arg)),
            _ => return Err("only one file or directory can be provided".into()),
        }
    }

    let target = target.unwrap_or_else(|| PathBuf::from("."));
    let target = target
        .canonicalize()
        .map_err(|_| format!("path does not exist: {}", target.display()))?;
    if !command_exists("ffmpeg") || !command_exists("ffprobe") {
        return Err(
            "ffmpeg and ffprobe are required in PATH; this tool never installs packages".into(),
        );
    }

    let (mut files, base) = if target.is_file() {
        if !is_video(&target) {
            return Err(format!("unsupported video format: {}", target.display()));
        }
        (
            vec![target.clone()],
            target.parent().unwrap_or(Path::new(".")).to_path_buf(),
        )
    } else {
        let mut files = Vec::new();
        collect_videos(&target, &mut files);
        (files, target.clone())
    };
    files.sort();
    if files.is_empty() {
        println!("No compatible videos found in {}.", target.display());
        return Ok(());
    }

    let mut skipped = 0;
    let mut candidates = Vec::new();
    let mut folders: BTreeMap<String, FolderStats> = BTreeMap::new();
    for (index, file) in files.iter().enumerate() {
        eprint!("\rScanning codecs: {}/{}...", index + 1, files.len());
        if probe(file, "stream=codec_name").as_deref() == Some("hevc") {
            skipped += 1;
            continue;
        }
        let size = fs::metadata(file)
            .map(|metadata| metadata.len())
            .unwrap_or(0);
        let stats = folders.entry(relative_folder(file, &base)).or_default();
        stats.count += 1;
        stats.bytes += size;
        candidates.push(file.clone());
    }
    eprint!("\r\x1b[K");

    if dry_run {
        println!("Dry-run: {}", target.display());
        println!(
            "found={} already_hevc={} would_compress={}",
            files.len(),
            skipped,
            candidates.len()
        );
        for (folder, stats) in &folders {
            println!(
                "  {folder}: {} video(s), original={}, estimated_savings={}",
                stats.count,
                format_size(stats.bytes as i128),
                format_size((stats.bytes / 2) as i128)
            );
        }
        return Ok(());
    }
    if candidates.is_empty() {
        println!("All videos are already encoded as HEVC.");
        return Ok(());
    }

    let mut successes = 0;
    let mut failures = 0;
    let mut saved_total = 0_i128;
    let mut saved_by_folder: BTreeMap<String, FolderStats> = BTreeMap::new();
    for (index, file) in candidates.iter().enumerate() {
        println!(
            "[{}/{}] Compressing {}",
            index + 1,
            candidates.len(),
            file.display()
        );
        let temporary = temporary_path(file);
        let status = Command::new("ffmpeg")
            .arg("-y")
            .arg("-i")
            .arg(file)
            .args([
                "-c:v",
                "libx265",
                "-crf",
                &crf.to_string(),
                "-preset",
                &preset,
                "-c:a",
                "copy",
            ])
            .arg(&temporary)
            .stdin(Stdio::null())
            .status();
        if !status.is_ok_and(|status| status.success())
            || probe(&temporary, "format=duration").is_none()
        {
            eprintln!("  error: ffmpeg failed or generated an invalid video");
            let _ = fs::remove_file(&temporary);
            failures += 1;
            continue;
        }
        let old_size = fs::metadata(file)
            .map(|metadata| metadata.len())
            .unwrap_or(0);
        let new_size = fs::metadata(&temporary)
            .map(|metadata| metadata.len())
            .unwrap_or(0);
        let saved = old_size as i128 - new_size as i128;
        fs::rename(&temporary, file)
            .map_err(|error| format!("cannot replace {}: {error}", file.display()))?;
        println!("  saved {}", format_size(saved));
        successes += 1;
        saved_total += saved;
        let stats = saved_by_folder
            .entry(relative_folder(file, &base))
            .or_default();
        stats.count += 1;
        stats.bytes = (stats.bytes as i128 + saved).max(0) as u64;
    }
    println!(
        "Finished: compressed={successes} errors={failures} saved={}",
        format_size(saved_total)
    );
    for (folder, stats) in saved_by_folder {
        println!(
            "  {folder}: {} video(s), saved={}",
            stats.count,
            format_size(stats.bytes as i128)
        );
    }
    if failures > 0 {
        return Err(format!("{failures} video(s) failed"));
    }
    Ok(())
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("error: {error}");
            ExitCode::from(1)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn formats_positive_and_negative_sizes() {
        assert_eq!(format_size(512), "512 B");
        assert_eq!(format_size(1_048_576), "1.00 MB");
        assert_eq!(format_size(-1024), "-1.00 KB");
    }

    #[test]
    fn matches_video_extensions_case_insensitively() {
        assert!(is_video(Path::new("lesson.MP4")));
        assert!(is_video(Path::new("recording.ts")));
        assert!(!is_video(Path::new("notes.md")));
    }
}
