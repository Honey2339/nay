use std::{fs, io, path::PathBuf};

use dirs::{cache_dir, home_dir};


fn get_cache_root() -> PathBuf {
    cache_dir()
    .unwrap_or_else(|| home_dir().unwrap_or_else(|| PathBuf::from(".")))
    .join("nay")
    .join("builds")
}

pub fn get_package_cache(pkg: &str) -> io::Result<PathBuf> {
    let root = get_cache_root();
    let pkg_dir = root.join(pkg);

    if !pkg_dir.exists() {
        fs::create_dir_all(&pkg_dir)?;
        println!("Created cache dir : {}", pkg_dir.display());
    } else {
        println!("Using existing cache : {}", pkg_dir.display());
    }

    Ok(pkg_dir)
}