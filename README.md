    <p align="center">
        <img src="public/N.png" alt="">
    </p>

> A Rust-based AUR helper inspired by yay.

`nay` is a fast, lightweight, pure AUR helper written in Rust. It aims to provide a simple CLI for searching, installing, and managing packages from the **AUR**.

---

## Features

- Search for packages in the AUR and official repos
- Install packages with automatic dependency resolution
- Written in Rust for speed and safety

---

## Installation

### From the AUR (recommended)

```bash
curl -sSL https://raw.githubusercontent.com/Honey2339/nay/main/install.sh | bash
```

### Manual build

Clone and build with `install.sh`:

```bash
git clone https://github.com/Honey2339/nay.git
cd nay
./install.sh
```

---

## Usage

```bash
nay install <package>
```

Examples:

```bash
nay install neovim
nay install google-chrome
```

You can also check the version and help:

```bash
nay --version
nay --help
```
