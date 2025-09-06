#!/bin/bash
# Unified Dotfiles Framework - Shell Module Uninstallation

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

# Module information
MODULE_NAME="shell"

log_info "Uninstalling shell module..."

# Remove configuration files
remove_config_files() {
    log_info "Removing shell configuration files..."
    
    local files=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.bash_aliases"
        "$HOME/.bash_functions"
        "$HOME/.bash_exports"
        "$HOME/.zsh_aliases"
        "$HOME/.zsh_functions"
        "$HOME/.zsh_exports"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "Removing $file..."
            rm -f "$file"
        fi
    done
}

# Restore original shell if it was changed
restore_shell() {
    log_info "Note: Default shell was not changed during uninstallation"
    log_info "If you want to change back to bash, run: chsh -s /bin/bash"
}

# Clean up directories
cleanup_directories() {
    log_info "Cleaning up shell-related directories..."
    
    # Remove temporary directories created by shell functions
    [[ -d "/tmp/log" ]] && rm -rf "/tmp/log"
    
    # Note: We don't remove ~/.oh-my-zsh as user might want to keep it
    log_info "Note: Oh My Zsh installation was not removed (if present)"
    log_info "To remove Oh My Zsh manually, run: rm -rf ~/.oh-my-zsh"
}

# Main uninstallation
main() {
    log_info "Starting shell module uninstallation..."
    
    remove_config_files
    cleanup_directories
    restore_shell
    
    log_success "Shell module uninstallation completed!"
    log_info "Note: You may need to restart your terminal to see changes"
    
    echo ""
    echo "Shell Module Uninstallation Summary:"
    echo "===================================="
    echo "• Configuration files removed"
    echo "• Temporary directories cleaned"
    echo "• Oh My Zsh left intact (remove manually if desired)"
    echo "• Default shell unchanged (change manually if desired)"
    echo ""
}

# Run main function
main "$@"