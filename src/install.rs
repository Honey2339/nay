use crate::{cache::get_package_cache, repo::check_official_package};
use std::io;

pub fn install_package(pkg: &str) -> io::Result<()> {
    println!("Checking if `{}` exists in repo", pkg);

    if check_official_package(pkg)? {
        println!("{} found in official repo", pkg);
        return Ok(())
    }

    println!("{} not in repo, falling back to AUR", pkg);

    let _cache = get_package_cache(pkg)?;

    Ok(())
}