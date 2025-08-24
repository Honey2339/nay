#!/usr/bin/env bash

set -euo pipefail

REPO="https://github.com/Honey2339/nay.git"
PROGRAM_NAME="nay"
INSTALL_DIR="/usr/local/bin"
BUILD_DIR="$(mktemp -d)"

SCRIPT_URL="https://raw.githubusercontent.com/Honey2339/nay/main/install.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'


log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
    if [[ -d "$BUILD_DIR" ]]; then
        log_info "Cleaning up build directory..."
        rm -rf "$BUILD_DIR"
    fi
}

trap cleanup EXIT

check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        log_error "This installer is designed for Arch Linux only."
        exit 1
    fi
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Don't run this script as root. It will ask for sudo when needed."
        exit 1
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_deps=()
    
    for cmd in git sudo; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install them first: sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi
    
    log_info "Installing base development tools..."
    if ! sudo pacman -S --needed --noconfirm base-devel; then
        log_error "Failed to install base-devel"
        exit 1
    fi
}

setup_rust() {
    log_info "Setting up Rust environment..."
    
    if command -v cargo &>/dev/null; then
        log_info "Cargo found, checking Rust toolchain..."
        
        if command -v rustup &>/dev/null; then
            if ! rustup show active-toolchain &>/dev/null 2>&1; then
                log_info "No active Rust toolchain found. Setting stable as default..."
                rustup default stable
            else
                log_info "Rust toolchain is already configured."
            fi
        else
            log_warning "Cargo found but rustup not available. This might work, but rustup is recommended."
        fi
    else
        log_info "Cargo not found. Installing Rust via rustup..."
        
        if ! sudo pacman -S --needed --noconfirm rustup; then
            log_error "Failed to install rustup"
            exit 1
        fi
        
        log_info "Initializing Rust stable toolchain..."
        rustup default stable
        
        source "$HOME/.cargo/env" 2>/dev/null || true
    fi
    
    if ! command -v cargo &>/dev/null; then
        log_error "Cargo still not available after installation. Please check your PATH."
        log_info "You may need to restart your shell or run: source ~/.bashrc"
        exit 1
    fi
    
    log_success "Rust environment is ready."
}

clone_and_build() {
    log_info "Cloning repository to $BUILD_DIR..."
    
    if ! git clone --depth=1 "$REPO" "$BUILD_DIR/$PROGRAM_NAME"; then
        log_error "Failed to clone repository"
        exit 1
    fi
    
    cd "$BUILD_DIR/$PROGRAM_NAME"
    
    log_info "Building $PROGRAM_NAME (this may take a while)..."
    
    if ! cargo build --release; then
        log_error "Failed to build $PROGRAM_NAME"
        exit 1
    fi
    
    if [[ ! -f "target/release/$PROGRAM_NAME" ]]; then
        log_error "Binary not found at target/release/$PROGRAM_NAME"
        exit 1
    fi
    
    log_success "Build completed successfully."
}

install_binary() {
    local binary_path="$BUILD_DIR/$PROGRAM_NAME/target/release/$PROGRAM_NAME"
    
    log_info "Installing $PROGRAM_NAME to $INSTALL_DIR..."
    
    sudo mkdir -p "$INSTALL_DIR"
    
    if ! sudo install -Dm755 "$binary_path" "$INSTALL_DIR/$PROGRAM_NAME"; then
        log_error "Failed to install binary to $INSTALL_DIR"
        exit 1
    fi
    
    if [[ ! -f "$INSTALL_DIR/$PROGRAM_NAME" ]]; then
        log_error "Installation verification failed"
        exit 1
    fi
    
    log_success "$PROGRAM_NAME installed to $INSTALL_DIR"
}

verify_installation() {
    log_info "Verifying installation..."
    
    if command -v "$PROGRAM_NAME" &>/dev/null; then
        local version
        version=$("$PROGRAM_NAME" --version 2>/dev/null || echo "unknown")
        log_success "$PROGRAM_NAME is installed and accessible (version: $version)"
        return 0
    else
        log_warning "$PROGRAM_NAME is not in PATH. You may need to:"
        log_info "1. Restart your shell, or"
        log_info "2. Add $INSTALL_DIR to your PATH by adding this to your ~/.bashrc or ~/.zshrc:"
        log_info "   export PATH=\"$INSTALL_DIR:\$PATH\""
        return 1
    fi
}

show_usage() {
    log_info "Installation completed! You can now use $PROGRAM_NAME:"
    echo
    echo "  $PROGRAM_NAME install <package>  # Install an AUR package"
    echo "  $PROGRAM_NAME --help            # Show help"
    echo
    log_info "Example: $PROGRAM_NAME install firefox-developer-edition"
    echo
    log_info "To share this installer with others:"
    echo "  curl -sSL $SCRIPT_URL | bash"
}

main() {
    log_info "Starting $PROGRAM_NAME installation..."
    echo
    
    check_root
    check_arch
    check_dependencies
    setup_rust
    clone_and_build
    install_binary
    
    echo
    if verify_installation; then
        echo
        show_usage
    else
        echo
        log_info "Installation completed, but $PROGRAM_NAME is not immediately available."
        log_info "Please follow the PATH instructions above."
    fi
    
    log_success "Installation process finished!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi