use regex::{Captures, Regex};
use std::cell::RefCell;
use std::collections::{BTreeMap, HashMap};
use std::env;
use std::fs::{self, File};
use std::io::{Read, Seek, SeekFrom};
use std::path::{Component, Path, PathBuf};
use std::process::ExitCode;

fn usage() {
    eprintln!("Usage: is-avif [--dry-run] [--rename] [--update-notes] <vault>");
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

fn collect_files(root: &Path, out: &mut Vec<PathBuf>) {
    let Ok(entries) = fs::read_dir(root) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let Ok(kind) = entry.file_type() else {
            continue;
        };
        if kind.is_dir() {
            if entry.file_name() != ".git" {
                collect_files(&path, out);
            }
        } else if kind.is_file() {
            out.push(path);
        }
    }
}

fn is_real_avif(path: &Path) -> bool {
    let Ok(mut file) = File::open(path) else {
        return false;
    };
    let mut header = [0_u8; 16];
    if file.read_exact(&mut header).is_err() || &header[4..8] != b"ftyp" {
        return false;
    }
    let box_size = u32::from_be_bytes(header[0..4].try_into().unwrap()) as usize;
    if !(16..=1024 * 1024).contains(&box_size) {
        return false;
    }
    let mut payload = vec![0_u8; box_size - 8];
    if file.seek(SeekFrom::Start(8)).is_err() || file.read_exact(&mut payload).is_err() {
        return false;
    }
    let is_avif_brand = |brand: &[u8]| brand == b"avif" || brand == b"avis";
    is_avif_brand(&payload[0..4]) || payload[8..].chunks_exact(4).any(is_avif_brand)
}

fn has_avif_extension(path: &Path) -> bool {
    matches!(
        path.extension().and_then(|value| value.to_str()).map(str::to_ascii_lowercase),
        Some(ext) if ext == "avif" || ext == "avifs"
    )
}

fn unique_avif_path(path: &Path) -> PathBuf {
    let target = path.with_extension("avif");
    if !target.exists() || target == path {
        return target;
    }
    let stem = path.file_stem().unwrap_or_default().to_string_lossy();
    for counter in 1.. {
        let candidate = path.with_file_name(format!("{stem}-{counter}.avif"));
        if !candidate.exists() {
            return candidate;
        }
    }
    unreachable!()
}

fn normalize(path: &Path) -> PathBuf {
    let mut result = PathBuf::new();
    for component in path.components() {
        match component {
            Component::CurDir => {}
            Component::ParentDir => {
                result.pop();
            }
            other => result.push(other.as_os_str()),
        }
    }
    result
}

fn relative_path(path: &Path, base: &Path) -> PathBuf {
    let path_parts: Vec<_> = path.components().collect();
    let base_parts: Vec<_> = base.components().collect();
    let common = path_parts
        .iter()
        .zip(&base_parts)
        .take_while(|(left, right)| left == right)
        .count();
    let mut result = PathBuf::new();
    for _ in common..base_parts.len() {
        result.push("..");
    }
    for component in &path_parts[common..] {
        result.push(component.as_os_str());
    }
    result
}

fn slash(path: &Path) -> String {
    path.to_string_lossy().replace('\\', "/")
}

fn percent_decode(input: &str) -> String {
    let bytes = input.as_bytes();
    let mut output = Vec::with_capacity(bytes.len());
    let mut index = 0;
    while index < bytes.len() {
        if bytes[index] == b'%' && index + 2 < bytes.len() {
            if let Ok(value) = u8::from_str_radix(&input[index + 1..index + 3], 16) {
                output.push(value);
                index += 3;
                continue;
            }
        }
        output.push(bytes[index]);
        index += 1;
    }
    String::from_utf8_lossy(&output).into_owned()
}

fn percent_encode_path(input: &str) -> String {
    let mut output = String::new();
    for byte in input.bytes() {
        if byte.is_ascii_alphanumeric()
            || matches!(byte, b'-' | b'_' | b'.' | b'~' | b'/' | b'#' | b'^' | b'|')
        {
            output.push(byte as char);
        } else {
            output.push_str(&format!("%{byte:02X}"));
        }
    }
    output
}

fn split_wiki_target(value: &str) -> (&str, &str) {
    let index = ['|', '#', '^']
        .iter()
        .filter_map(|separator| value.find(*separator))
        .min();
    index.map_or((value, ""), |index| value.split_at(index))
}

fn resolve_target(
    raw_target: &str,
    note: &Path,
    vault: &Path,
    renames: &BTreeMap<PathBuf, PathBuf>,
    basename_index: &HashMap<String, Vec<PathBuf>>,
) -> Result<Option<PathBuf>, String> {
    let decoded = percent_decode(raw_target);
    let candidates = if decoded.starts_with('/') {
        vec![normalize(&vault.join(decoded.trim_start_matches('/')))]
    } else {
        vec![
            normalize(&note.parent().unwrap_or(vault).join(&decoded)),
            normalize(&vault.join(&decoded)),
        ]
    };
    for candidate in candidates {
        if renames.contains_key(&candidate) {
            return Ok(Some(candidate));
        }
    }
    if !decoded.contains('/') {
        if let Some(matches) = basename_index.get(&decoded) {
            return match matches.as_slice() {
                [only] => Ok(Some(only.clone())),
                [] => Ok(None),
                _ => Err(format!("AMBIGUOUS_BASENAME: {raw_target}")),
            };
        }
    }
    Ok(None)
}

fn replacement_for_target(
    raw_target: &str,
    old: &Path,
    new: &Path,
    note: &Path,
    vault: &Path,
) -> String {
    let decoded = percent_decode(raw_target);
    let old_vault = slash(old.strip_prefix(vault).unwrap_or(old));
    let new_vault = slash(new.strip_prefix(vault).unwrap_or(new));
    let note_parent = note.parent().unwrap_or(vault);
    let old_note = slash(&relative_path(old, note_parent));
    let new_note = slash(&relative_path(new, note_parent));
    let replacement = if decoded.starts_with('/') {
        format!("/{new_vault}")
    } else if decoded == old_vault {
        new_vault
    } else if decoded == old_note {
        new_note
    } else if !decoded.contains('/') {
        new.file_name()
            .unwrap_or_default()
            .to_string_lossy()
            .into_owned()
    } else {
        new_note
    };
    if raw_target.contains('%') {
        percent_encode_path(&replacement)
    } else {
        replacement
    }
}

fn update_note(
    note: &Path,
    vault: &Path,
    renames: &BTreeMap<PathBuf, PathBuf>,
    basename_index: &HashMap<String, Vec<PathBuf>>,
    dry_run: bool,
) -> Result<bool, String> {
    let original = fs::read_to_string(note)
        .map_err(|error| format!("cannot read {}: {error}", note.display()))?;
    let warnings = RefCell::new(Vec::new());
    let wiki = Regex::new(r"(!?)\[\[([^\]]+)\]\]").unwrap();
    let text = wiki
        .replace_all(&original, |caps: &Captures<'_>| {
            let (raw, suffix) = split_wiki_target(&caps[2]);
            match resolve_target(raw, note, vault, renames, basename_index) {
                Ok(Some(old)) => {
                    let new = &renames[&old];
                    format!(
                        "{}[[{}{}]]",
                        &caps[1],
                        replacement_for_target(raw, &old, new, note, vault),
                        suffix
                    )
                }
                Err(warning) => {
                    warnings.borrow_mut().push(warning);
                    caps[0].to_owned()
                }
                Ok(None) => caps[0].to_owned(),
            }
        })
        .into_owned();
    let markdown = Regex::new(r"(!?\[[^\]]*\]\()([^)]+)(\))").unwrap();
    let text = markdown
        .replace_all(&text, |caps: &Captures<'_>| {
            let target = caps[2].trim();
            let angle = target.starts_with('<') && target.ends_with('>');
            let raw = if angle {
                &target[1..target.len() - 1]
            } else {
                target
            };
            match resolve_target(raw, note, vault, renames, basename_index) {
                Ok(Some(old)) => {
                    let mut new_target =
                        replacement_for_target(raw, &old, &renames[&old], note, vault);
                    if angle {
                        new_target = format!("<{new_target}>");
                    }
                    format!("{}{new_target}{}", &caps[1], &caps[3])
                }
                Err(warning) => {
                    warnings.borrow_mut().push(warning);
                    caps[0].to_owned()
                }
                Ok(None) => caps[0].to_owned(),
            }
        })
        .into_owned();

    let mut warnings = warnings.into_inner();
    warnings.sort();
    warnings.dedup();
    for warning in warnings {
        println!(
            "WARNING: {}: {warning}",
            slash(note.strip_prefix(vault).unwrap_or(note))
        );
    }
    if text == original {
        return Ok(false);
    }
    let relative = slash(note.strip_prefix(vault).unwrap_or(note));
    if dry_run {
        println!("WOULD_UPDATE_MD: {relative}");
    } else {
        fs::write(note, text)
            .map_err(|error| format!("cannot write {}: {error}", note.display()))?;
        println!("UPDATED_MD: {relative}");
    }
    Ok(true)
}

fn run() -> Result<(), String> {
    let mut dry_run = false;
    let mut rename = false;
    let mut update_notes = false;
    let mut vault = None;
    for arg in env::args().skip(1) {
        match arg.as_str() {
            "-h" | "--help" => {
                usage();
                return Ok(());
            }
            "--dry-run" => dry_run = true,
            "--rename" => rename = true,
            "--update-notes" => update_notes = true,
            _ if arg.starts_with('-') => return Err(format!("unknown option: {arg}")),
            _ if vault.is_none() => vault = Some(expand_tilde(&arg)),
            _ => return Err("only one vault can be provided".into()),
        }
    }
    let vault = vault.ok_or_else(|| "vault path is required".to_owned())?;
    let vault = vault
        .canonicalize()
        .map_err(|_| format!("vault not found: {}", vault.display()))?;
    if !vault.is_dir() {
        return Err(format!("not a directory: {}", vault.display()));
    }

    let mut files = Vec::new();
    collect_files(&vault, &mut files);
    files.sort();
    let mut renames = BTreeMap::new();
    for path in &files {
        if !has_avif_extension(path) && is_real_avif(path) {
            renames.insert(path.clone(), unique_avif_path(path));
        }
    }
    if renames.is_empty() {
        println!("No real AVIF files with wrong extensions found.");
        return Ok(());
    }
    let mut basename_index: HashMap<String, Vec<PathBuf>> = HashMap::new();
    for old in renames.keys() {
        basename_index
            .entry(
                old.file_name()
                    .unwrap_or_default()
                    .to_string_lossy()
                    .into_owned(),
            )
            .or_default()
            .push(old.clone());
    }
    println!("Planned renames:");
    for (old, new) in &renames {
        println!(
            "  {} -> {}",
            slash(old.strip_prefix(&vault).unwrap_or(old)),
            slash(new.strip_prefix(&vault).unwrap_or(new))
        );
    }
    if update_notes {
        for note in files
            .iter()
            .filter(|path| path.extension().is_some_and(|ext| ext == "md"))
        {
            update_note(note, &vault, &renames, &basename_index, dry_run)?;
        }
    }
    if rename {
        for (old, new) in &renames {
            let old_rel = slash(old.strip_prefix(&vault).unwrap_or(old));
            let new_rel = slash(new.strip_prefix(&vault).unwrap_or(new));
            if dry_run {
                println!("WOULD_RENAME: {old_rel} -> {new_rel}");
            } else {
                fs::rename(old, new).map_err(|error| {
                    format!(
                        "cannot rename {} to {}: {error}",
                        old.display(),
                        new.display()
                    )
                })?;
                println!("RENAMED: {old_rel} -> {new_rel}");
            }
        }
    }
    Ok(())
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("error: {error}");
            usage();
            ExitCode::from(1)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_avif_compatible_brand() {
        let root = env::temp_dir().join(format!("is-avif-test-{}", std::process::id()));
        fs::create_dir_all(&root).unwrap();
        let path = root.join("image.jpg");
        let mut bytes = Vec::from(24_u32.to_be_bytes());
        bytes.extend_from_slice(b"ftyp");
        bytes.extend_from_slice(b"mif1");
        bytes.extend_from_slice(&[0, 0, 0, 0]);
        bytes.extend_from_slice(b"avif");
        bytes.extend_from_slice(b"mif1");
        fs::write(&path, bytes).unwrap();

        assert!(is_real_avif(&path));
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn preserves_percent_encoding_when_replacing_target() {
        let vault = Path::new("/vault");
        let note = vault.join("notes/note.md");
        let old = vault.join("assets/old image.jpg");
        let new = vault.join("assets/old image.avif");

        assert_eq!(
            replacement_for_target("assets/old%20image.jpg", &old, &new, &note, vault),
            "assets/old%20image.avif"
        );
    }
}
