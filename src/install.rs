use std::path::PathBuf;
use std::process::Command;
use std::{fs, io};

use dirs::{cache_dir, home_dir};

fn get_cache_root() -> PathBuf {
    cache_dir()
    .unwrap_or_else(|| home_dir().unwrap_or_else(|| PathBuf::from(".")))
    .join("nay")
    .join("builds")
}

pub fn install_package(pkg: &str) -> io::Result<()>{
    println!("Checking if `{}` exists in repo or not", pkg);

    let status = Command::new("pacman")
        .args(["-Si", pkg])
        .status()
        .map_err(|e|{
            io::Error::new(
                io::ErrorKind::Other,
                format!("Failed to run pacman: {}", e),
            )
        });

    if status.is_ok(){
        println!("{}, found official pkg", pkg);
        return Ok(())
    }

    let cache_root = get_cache_root();
    let pkg_cache = cache_root.join(pkg);

    if pkg_cache.exists(){
        println!("Using existing cache at {}", pkg_cache.display());
    } else {
        println!("Creating cache dir: {}", pkg_cache.display());
        fs::create_dir_all(&pkg_cache);
    }

    Ok(())
}