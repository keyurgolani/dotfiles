#!/bin/bash
# Unified Dotfiles Framework - Tmux Module Uninstallation

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

# Module information
MODULE_NAME="tmux"

log_info "Uninstalling tmux module..."

# Remove configuration files
remove_config_files() {
    log_info "Removing tmux configuration files..."
    
    local files=(
        "$HOME/.tmux.conf"
        "$HOME/.tmux.conf.local"
        "$HOME/.tmux_module_info"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "Removing $file..."
            rm -f "$file"
        fi
    done
}

# Clean up tmux directories
cleanup_tmux_directories() {
    log_info "Cleaning up tmux directories..."
    
    # Ask user if they want to remove tmux directories
    echo "The following tmux directories contain plugins and data:"
    echo "  ~/.tmux/plugins (installed plugins)"
    echo "  ~/.config/tmux (configuration data)"
    echo ""
    
    read -p "Do you want to remove these directories? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local directories=(
            "$HOME/.tmux/plugins"
            "$HOME/.config/tmux"
        )
        
        for dir in "${directories[@]}"; do
            if [[ -d "$dir" ]]; then
                log_info "Removing directory: $dir"
                rm -rf "$dir"
            fi
        done
        
        # Remove .tmux directory if it's empty
        if [[ -d "$HOME/.tmux" ]]; then
            rmdir "$HOME/.tmux" 2>/dev/null && log_info "Removed empty ~/.tmux directory" || log_info "~/.tmux directory not empty, keeping it"
        fi
    else
        log_info "Keeping tmux directories"
    fi
}

# Remove auto-start configuration
remove_auto_start() {
    log_info "Removing tmux auto-start configuration..."
    
    local shell_configs=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
    )
    
    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]] && grep -q "Auto-start tmux" "$config"; then
            # Remove the auto-start block
            sed -i.bak '/# Auto-start tmux/,/^fi$/d' "$config" 2>/dev/null || {
                log_warn "Could not automatically remove auto-start from $config"
                log_info "Please manually remove the tmux auto-start block from $config"
            }
            log_info "Removed tmux auto-start from $config"
        fi
    done
}

# Kill running tmux sessions
kill_tmux_sessions() {
    if command -v tmux >/dev/null 2>&1; then
        local sessions=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        
        if [[ "${sessions:-0}" -gt 0 ]]; then
            echo "Found $sessions active tmux session(s)."
            read -p "Do you want to kill all tmux sessions? [y/N]: " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                tmux kill-server 2>/dev/null || log_warn "Could not kill tmux sessions"
                log_info "Killed all tmux sessions"
            else
                log_info "Keeping active tmux sessions"
            fi
        fi
    fi
}

# Main uninstallation
main() {
    log_info "Starting tmux module uninstallation..."
    
    kill_tmux_sessions
    remove_config_files
    cleanup_tmux_directories
    remove_auto_start
    
    log_success "Tmux module uninstallation completed!"
    log_info "Note: Tmux packages were not removed (remove manually if desired)"
    
    echo ""
    echo "Tmux Module Uninstallation Summary:"
    echo "==================================="
    echo "• Configuration files removed"
    echo "• Tmux directories handled based on user choice"
    echo "• Auto-start configuration removed from shell configs"
    echo "• Tmux sessions handled based on user choice"
    echo "• Tmux packages left intact"
    echo ""
    echo "To completely remove tmux:"
    case "$(uname)" in
        "Darwin")
            echo "  brew uninstall tmux reattach-to-user-namespace"
            ;;
        "Linux")
            if command -v apt >/dev/null 2>&1; then
                echo "  sudo apt remove tmux xclip"
            elif command -v yum >/dev/null 2>&1; then
                echo "  sudo yum remove tmux"
            elif command -v dnf >/dev/null 2>&1; then
                echo "  sudo dnf remove tmux"
            fi
            ;;
    esac
    echo ""
}

# Run main function
main "$@"