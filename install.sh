#!/bin/bash
set -e

echo "Installing dependencies..."

sudo pacman -S --needed base-devel git

if ! command -v cargo &> /dev/null; then
    echo "cargo not found. Installing rust (from pacman)..."
    sudo pacman -S --needed rust
else
    echo "cargo already available, checking rustup toolchain..."
    if command -v rustup &> /dev/null; then
        if ! rustup show active-toolchain &> /dev/null; then
            echo "No rustup toolchain configured. Setting to stable..."
            rustup default stable
        fi
    fi
fi

echo "Building nay..."
cargo build --release

echo "Installing nay to /usr/bin..."
sudo install -Dm755 target/release/nay /usr/bin/nay

echo "Done! You can now run nay."
