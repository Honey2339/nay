#!/usr/bin/env bash

set -eo pipefail

REPO="https://github.com/Honey2339/nay.git"
PROGRAM_NAME="nay"
INSTALL_DIR="/usr/local/bin"
TEMP_ROOT="/tmp"
BUILD_DIR="$TEMP_ROOT/nay-install-$$"

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
        log_info "Cleaning up temporary directory: $BUILD_DIR"
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
    log_info "Checking system dependencies..."
    
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
        
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    
    if ! command -v cargo &>/dev/null; then
        log_error "Cargo still not available after installation."
        log_info "Trying to source cargo environment..."
        if [[ -f "$HOME/.cargo/env" ]]; then
            source "$HOME/.cargo/env"
        fi
        
        if ! command -v cargo &>/dev/null; then
            log_error "Cargo setup failed. Please restart your shell and try again."
            exit 1
        fi
    fi
    
    log_success "Rust environment is ready."
}

create_temp_directory() {
    log_info "Creating temporary build directory: $BUILD_DIR"
    
    if ! mkdir -p "$BUILD_DIR"; then
        log_error "Failed to create temporary directory: $BUILD_DIR"
        exit 1
    fi
    
    log_success "Temporary directory created."
}

clone_repository() {
    log_info "Cloning repository from $REPO..."
    
    cd "$BUILD_DIR"
    
    if ! git clone --depth=1 "$REPO" "$PROGRAM_NAME"; then
        log_error "Failed to clone repository"
        exit 1
    fi
    
    log_success "Repository cloned successfully."
}

build_project() {
    local project_dir="$BUILD_DIR/$PROGRAM_NAME"
    
    log_info "Building $PROGRAM_NAME from source..."
    log_info "Build directory: $project_dir"
    
    cd "$project_dir"
    
    if [[ ! -f "Cargo.toml" ]]; then
        log_error "Cargo.toml not found in the project directory"
        log_info "Project structure:"
        ls -la
        exit 1
    fi
    
    log_info "Building release version (this may take a while)..."
    
    if ! cargo build --release; then
        log_error "Failed to build $PROGRAM_NAME"
        log_info "Build logs should be above. Common issues:"
        log_info "- Missing dependencies in Cargo.toml"
        log_info "- Network issues downloading crates"
        log_info "- Compilation errors in source code"
        exit 1
    fi
    
    if [[ ! -f "target/release/$PROGRAM_NAME" ]]; then
        log_error "Binary not found at target/release/$PROGRAM_NAME"
        log_info "Contents of target/release/:"
        ls -la target/release/ 2>/dev/null || echo "target/release/ directory not found"
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
        log_error "Installation verification failed - binary not found at $INSTALL_DIR/$PROGRAM_NAME"
        exit 1
    fi
    
    if [[ ! -x "$INSTALL_DIR/$PROGRAM_NAME" ]]; then
        log_error "Binary is not executable"
        exit 1
    fi
    
    log_success "$PROGRAM_NAME installed to $INSTALL_DIR"
}

verify_installation() {
    log_info "Verifying installation..."
    
    if command -v "$PROGRAM_NAME" &>/dev/null; then
        local version
        version=$("$PROGRAM_NAME" --version 2>/dev/null || echo "version check failed")
        log_success "$PROGRAM_NAME is installed and accessible (version: $version)"
        return 0
    else
        log_warning "$PROGRAM_NAME is installed but not immediately accessible via PATH."
        log_info "The binary is located at: $INSTALL_DIR/$PROGRAM_NAME"
        
        if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
            log_warning "$INSTALL_DIR is not in your PATH."
            log_info "Add it to your PATH by adding this line to your ~/.bashrc or ~/.zshrc:"
            log_info "  export PATH=\"$INSTALL_DIR:\$PATH\""
            log_info "Then restart your shell or run: source ~/.bashrc"
        else
            log_info "PATH looks correct. Try opening a new terminal window."
        fi
        
        return 1
    fi
}

show_usage_info() {
    echo
    log_info "Installation completed! Here's how to use $PROGRAM_NAME:"
    echo
    echo "  $PROGRAM_NAME install <package>  # Install an AUR package"
    echo "  $PROGRAM_NAME --help            # Show help information"
    echo
    log_info "Example usage:"
    echo "  $PROGRAM_NAME install yay"
    echo "  $PROGRAM_NAME install firefox-developer-edition"
    echo
    
    if [[ -d "$BUILD_DIR" ]]; then
        log_info "Build files are kept at: $BUILD_DIR"
        log_info "You can safely delete this directory if you want to free up space:"
        log_info "  sudo rm -rf $BUILD_DIR"
    fi
}

main() {
    echo "=========================================="
    log_info "Starting $PROGRAM_NAME installation..."
    echo "=========================================="
    echo
    
    check_root
    check_arch
    check_dependencies
    setup_rust
    create_temp_directory
    clone_repository
    build_project
    install_binary
    
    echo
    echo "=========================================="
    if verify_installation; then
        log_success "Installation completed successfully!"
        show_usage_info
    else
        log_success "Installation completed with PATH issues."
        show_usage_info
        echo
        log_info "If you have PATH issues, try:"
        log_info "1. Open a new terminal window"
        log_info "2. Or run: hash -r"
        log_info "3. Or add $INSTALL_DIR to your PATH manually"
    fi
    echo "=========================================="
}

main "$@"