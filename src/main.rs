use clap::{Parser, Subcommand};

use crate::install::install_package;

mod install;
mod cache;
mod aur;

#[derive(Parser)]
#[command(name = "nay", version, about = "A lightweight AUR helper written in Rust")]
struct Cli{
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Install {
        package: String,
    }
}

fn main(){
    let cli = Cli::parse();

    match cli.command {
        Commands::Install { package } => {
            if let Err(e) = install_package(&package) {
                eprintln!("Failed to install {}: {}", package, e);
            }
        }
    }

}
