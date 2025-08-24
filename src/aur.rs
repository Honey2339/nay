use serde::Deserialize;
use std::{io, path::PathBuf, process::Command};

#[derive(Debug, Deserialize)]
struct AurResponse {
    results: Vec<AurPackage>,
}

#[derive(Debug, Deserialize)]
pub struct AurPackage {
    pub name: String,
    pub version: String,
    pub description: String,
}

pub fn fetch_package_info(pkg: &str) -> io::Result<Option<AurPackage>> {
    let url = format!("https://aur.archlinux.org/rpc/?v=5&type=info&arg={}", pkg);

    let resp = reqwest::blocking::get(&url)
        .map_err(|e| io::Error::new(io::ErrorKind::Other, format!("Failed to fetch AUR: {}", e)))?
        .json::<AurResponse>()
        .map_err(|e| io::Error::new(io::ErrorKind::Other, format!("Failed to parse JSON: {}", e)))?;

    Ok(resp.results.into_iter().next())
}

pub fn clone_package(pkg: &str, path: &PathBuf) -> io::Result<()> {
    if path.exists() {
        println!("Using existing clone at {}", path.display());
        return Ok(())
    }

    if path.exists() {
        std::fs::remove_dir_all(path)?;
    }

    println!("Cloning {} from AUR...", pkg);

    let status = Command::new("git")
        .args(["clone", &format!("https://aur.archlinux.org/{}.git", pkg), path.to_str().unwrap()])
        .status()
        .map_err(|e| io::Error::new(io::ErrorKind::Other, format!("git failed: {}", e)))?;

    if !status.success() {
        return Err(io::Error::new(io::ErrorKind::Other, "git clone failed"));
    }

    Ok(())
}

pub fn build_package(path: &PathBuf) -> io::Result<()> {
    println!("Buliding package in {}", path.display());

    let status = Command::new("makepkg")
        .args(["-si", "--noconfirm"])
        .current_dir(path)
        .status()
        .map_err(|e| io::Error::new(io::ErrorKind::Other, format!("makepkg failed : {}", e)))?;

    if !status.success() {
        return Err(io::Error::new(io::ErrorKind::Other, "makepkg returned error"));
    }

    Ok(())
}