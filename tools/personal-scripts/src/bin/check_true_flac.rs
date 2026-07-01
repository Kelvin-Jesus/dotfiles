use std::env;
use std::fs::{self, File};
use std::io::{self, Read};
use std::path::{Path, PathBuf};
use std::process::ExitCode;

const FLAC_MAGIC: &[u8; 4] = b"fLaC";

fn usage() {
    eprintln!("Usage: check_true_flac [--dry-run] [--no-recursive] [--relative] <folder>");
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

fn collect_files(root: &Path, recursive: bool, out: &mut Vec<PathBuf>) {
    let Ok(entries) = fs::read_dir(root) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        match entry.file_type() {
            Ok(kind) if kind.is_file() => out.push(path),
            Ok(kind) if kind.is_dir() && recursive => collect_files(&path, true, out),
            _ => {}
        }
    }
}

fn is_true_flac(path: &Path) -> Option<bool> {
    let mut file = File::open(path).ok()?;
    let mut header = [0_u8; 4];
    match file.read_exact(&mut header) {
        Ok(()) => Some(&header == FLAC_MAGIC),
        Err(error) if error.kind() == io::ErrorKind::UnexpectedEof => Some(false),
        Err(_) => None,
    }
}

fn main() -> ExitCode {
    let mut folder = None;
    let mut recursive = true;
    let mut relative = false;
    let mut dry_run = false;

    for arg in env::args().skip(1) {
        match arg.as_str() {
            "-h" | "--help" => {
                usage();
                return ExitCode::SUCCESS;
            }
            "--dry-run" => dry_run = true,
            "--no-recursive" => recursive = false,
            "--relative" => relative = true,
            _ if arg.starts_with('-') => {
                eprintln!("error: unknown option: {arg}");
                return ExitCode::from(1);
            }
            _ if folder.is_none() => folder = Some(expand_tilde(&arg)),
            _ => {
                eprintln!("error: only one folder can be provided");
                return ExitCode::from(1);
            }
        }
    }

    let Some(folder) = folder else {
        usage();
        return ExitCode::from(1);
    };
    let Ok(root) = folder.canonicalize() else {
        eprintln!(
            "error: folder does not exist or is not accessible: {}",
            folder.display()
        );
        return ExitCode::from(2);
    };
    if !root.is_dir() {
        eprintln!("error: not a folder: {}", root.display());
        return ExitCode::from(2);
    }
    if dry_run {
        eprintln!("dry-run: read-only FLAC inspection; no files will be changed");
    }

    let mut files = Vec::new();
    collect_files(&root, recursive, &mut files);
    files.sort();
    let mut true_flac = Vec::new();
    let mut unreadable = 0;
    for path in &files {
        match is_true_flac(path) {
            Some(true) => true_flac.push(path),
            Some(false) => {}
            None => unreadable += 1,
        }
    }
    for path in &true_flac {
        let shown = if relative {
            path.strip_prefix(&root).unwrap_or(path)
        } else {
            path
        };
        println!("{}", shown.display());
    }
    eprintln!(
        "scanned={} true_flac={} unreadable={unreadable}",
        files.len(),
        true_flac.len()
    );
    ExitCode::SUCCESS
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    #[test]
    fn checks_flac_magic_without_using_extensions() {
        let path = env::temp_dir().join(format!("check-flac-test-{}", std::process::id()));
        let mut file = File::create(&path).unwrap();
        file.write_all(b"fLaCmore bytes").unwrap();
        drop(file);

        assert_eq!(is_true_flac(&path), Some(true));
        fs::remove_file(path).unwrap();
    }
}
