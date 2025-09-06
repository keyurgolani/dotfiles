#!/bin/bash
# Unified Dotfiles Framework - Vim Module Uninstallation

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

# Module information
MODULE_NAME="vim"

log_info "Uninstalling vim module..."

# Remove configuration files
remove_config_files() {
    log_info "Removing vim configuration files..."
    
    local files=(
        "$HOME/.vimrc"
        "$HOME/.vimrc.local"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "Removing $file..."
            rm -f "$file"
        fi
    done
}

# Clean up vim directories
cleanup_vim_directories() {
    log_info "Cleaning up vim directories..."
    
    # Ask user if they want to remove vim directories
    echo "The following vim directories contain plugins and data:"
    echo "  ~/.vim/plugins (installed plugins)"
    echo "  ~/.vim/backups (backup files)"
    echo "  ~/.vim/swaps (swap files)"
    echo "  ~/.vim/undos (undo history)"
    echo ""
    
    read -p "Do you want to remove these directories? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local directories=(
            "$HOME/.vim/plugins"
            "$HOME/.vim/backups"
            "$HOME/.vim/swaps"
            "$HOME/.vim/undos"
            "$HOME/.vim/autoload"
        )
        
        for dir in "${directories[@]}"; do
            if [[ -d "$dir" ]]; then
                log_info "Removing directory: $dir"
                rm -rf "$dir"
            fi
        done
        
        # Remove .vim directory if it's empty
        if [[ -d "$HOME/.vim" ]]; then
            rmdir "$HOME/.vim" 2>/dev/null && log_info "Removed empty ~/.vim directory" || log_info "~/.vim directory not empty, keeping it"
        fi
    else
        log_info "Keeping vim directories"
    fi
}

# Reset editor environment variable
reset_editor() {
    log_info "Note: EDITOR environment variable was not modified"
    log_info "If you want to change your default editor, update your shell configuration"
}

# Main uninstallation
main() {
    log_info "Starting vim module uninstallation..."
    
    remove_config_files
    cleanup_vim_directories
    reset_editor
    
    log_success "Vim module uninstallation completed!"
    log_info "Note: Vim packages were not removed (remove manually if desired)"
    
    echo ""
    echo "Vim Module Uninstallation Summary:"
    echo "=================================="
    echo "• Configuration files removed"
    echo "• Vim directories handled based on user choice"
    echo "• Vim packages left intact"
    echo "• Editor environment variable unchanged"
    echo ""
    echo "To completely remove vim:"
    case "$(uname)" in
        "Darwin")
            echo "  brew uninstall vim"
            ;;
        "Linux")
            if command -v apt >/dev/null 2>&1; then
                echo "  sudo apt remove vim"
            elif command -v yum >/dev/null 2>&1; then
                echo "  sudo yum remove vim"
            elif command -v dnf >/dev/null 2>&1; then
                echo "  sudo dnf remove vim"
            fi
            ;;
    esac
    echo ""
}

# Run main function
main "$@"