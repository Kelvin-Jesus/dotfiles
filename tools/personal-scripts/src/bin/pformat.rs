use std::env;
use std::path::PathBuf;
use std::process::{Command, ExitCode};

fn usage() {
    eprintln!("Usage: pformat [--dry-run] <file>");
}

fn main() -> ExitCode {
    let mut dry_run = false;
    let mut path: Option<PathBuf> = None;

    for arg in env::args().skip(1) {
        match arg.as_str() {
            "-h" | "--help" => {
                usage();
                return ExitCode::SUCCESS;
            }
            "--dry-run" => dry_run = true,
            _ if arg.starts_with('-') => {
                eprintln!("error: unknown option: {arg}");
                return ExitCode::from(2);
            }
            _ if path.is_none() => path = Some(PathBuf::from(arg)),
            _ => {
                eprintln!("error: only one file can be provided");
                return ExitCode::from(2);
            }
        }
    }

    let Some(path) = path else {
        println!("unknown");
        usage();
        return ExitCode::from(1);
    };

    if !path.is_file() {
        println!("unknown");
        return ExitCode::SUCCESS;
    }

    if dry_run {
        eprintln!("dry-run: read-only MIME inspection; no files will be changed");
    }

    match Command::new("file")
        .args(["--mime-type", "--brief"])
        .arg(path)
        .output()
    {
        Ok(output) if output.status.success() => {
            let mime = String::from_utf8_lossy(&output.stdout);
            let mime = mime.trim();
            println!("{}", if mime.is_empty() { "unknown" } else { mime });
            ExitCode::SUCCESS
        }
        _ => {
            println!("unknown");
            ExitCode::SUCCESS
        }
    }
}
