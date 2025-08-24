use crate::{aur, cache::get_package_cache};
use std::io;

pub fn install_package(pkg: &str) -> io::Result<()> {
    println!("Checking if `{}` exists in repo", pkg);

    let info = aur::fetch_package_info(pkg)?
        .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Package not found in AUR"))?;

    println!("Found {} {} - {}",
        info.name,
        info.version,
        info.description
    );

    let pkg_dir = get_package_cache(pkg)?;
    let src_dir = pkg_dir.join("src");

    aur::clone_package(pkg, &src_dir)?;
    aur::build_package(&src_dir)?;

    Ok(())
}