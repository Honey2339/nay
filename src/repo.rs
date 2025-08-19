use std::{io, process::Command};

pub fn check_official_package(pkg: &str) -> io::Result<bool>{
    let status = Command::new("pacman").args(["-Si", pkg]).status();

    match status {
        Ok(s) if s.success() => Ok(true),
        Ok(_) => Ok(false),
        Err(e) => Err(io::Error::new(io::ErrorKind::Other, format!("pacman failed : {}", e))),
    }
}