use clap::{Parser, Subcommand};

use crate::install::install_package;

mod install;
mod cache;
mod aur;

#[derive(Parser)]
#[command(name = "nay")]
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
            install_package(&package);
        }
    }

}
