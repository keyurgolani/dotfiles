#!/bin/bash

# Install vim-plug plugin manager
# This script ensures vim-plug is properly installed before attempting plugin installation

set -euo pipefail

# Source core utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/core"

if [[ -f "$CORE_DIR/logger.sh" ]]; then
    source "$CORE_DIR/logger.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*"; }
fi

install_vim_plug() {
    local plug_file="$HOME/.vim/autoload/plug.vim"
    local plug_url="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    
    if [[ -f "$plug_file" ]]; then
        log_success "vim-plug is already installed"
        return 0
    fi
    
    log_info "Installing vim-plug..."
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$plug_file")"
    
    # Try to download vim-plug with multiple methods
    if command -v curl >/dev/null 2>&1; then
        log_info "Downloading vim-plug using curl..."
        if curl -fLo "$plug_file" --create-dirs "$plug_url" 2>/dev/null; then
            log_success "vim-plug installed successfully with curl"
            return 0
        else
            log_warn "Failed to download vim-plug with curl"
        fi
    fi
    
    if command -v wget >/dev/null 2>&1; then
        log_info "Downloading vim-plug using wget..."
        if wget -O "$plug_file" "$plug_url" 2>/dev/null; then
            log_success "vim-plug installed successfully with wget"
            return 0
        else
            log_warn "Failed to download vim-plug with wget"
        fi
    fi
    
    log_error "Failed to install vim-plug. Please install curl or wget and try again."
    return 1
}

# Main function
main() {
    log_info "Starting vim-plug installation..."
    
    if install_vim_plug; then
        log_success "vim-plug installation completed successfully"
        return 0
    else
        log_error "vim-plug installation failed"
        return 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi