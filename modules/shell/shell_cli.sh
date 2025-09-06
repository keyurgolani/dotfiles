#!/bin/bash

# =============================================================================
# Shell Module CLI
# =============================================================================
# Command-line interface for shell module utilities

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR"

# Source core utilities if available
CORE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/core"
if [[ -f "$CORE_DIR/logger.sh" ]]; then
    source "$CORE_DIR/logger.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*"; }
fi

# Show usage information
show_usage() {
    cat << EOF
Shell Module CLI - Dotfiles Framework

USAGE:
    $0 <command> [options]

COMMANDS:
    install-plugins     Install optional ZSH plugins (oh-my-zsh, autosuggestions, etc.)
    setup-work-aliases  Set up work-specific aliases (gitignored)
    migrate-aliases     Analyze and migrate from old alias system
    list-aliases        List all currently loaded aliases
    reload-aliases      Reload all alias configurations
    help               Show this help message

EXAMPLES:
    $0 install-plugins              # Install ZSH enhancements
    $0 setup-work-aliases          # Set up work aliases safely
    $0 migrate-aliases             # Check alias migration status
    $0 list-aliases | grep git     # Find git-related aliases

DESCRIPTION:
    This CLI provides access to shell module utilities for managing
    aliases, plugins, and shell configurations.

    All commands respect the framework's security guidelines and
    ensure personal information is properly protected.

EOF
}

# Install ZSH plugins
cmd_install_plugins() {
    log_info "Installing optional ZSH plugins..."
    
    local plugin_script="$MODULE_DIR/scripts/install_zsh_plugins.sh"
    if [[ -f "$plugin_script" ]]; then
        bash "$plugin_script" "$@"
    else
        log_error "Plugin installer not found: $plugin_script"
        return 1
    fi
}

# Set up work aliases
cmd_setup_work_aliases() {
    log_info "Setting up work-specific aliases..."
    
    local setup_script="$MODULE_DIR/scripts/setup_work_aliases.sh"
    if [[ -f "$setup_script" ]]; then
        bash "$setup_script" "$@"
    else
        log_error "Work aliases setup script not found: $setup_script"
        return 1
    fi
}

# Migrate aliases
cmd_migrate_aliases() {
    log_info "Analyzing alias migration..."
    
    local migrate_script="$MODULE_DIR/scripts/migrate_aliases.sh"
    if [[ -f "$migrate_script" ]]; then
        bash "$migrate_script" "$@"
    else
        log_error "Alias migration script not found: $migrate_script"
        return 1
    fi
}

# List aliases
cmd_list_aliases() {
    if command -v alias >/dev/null 2>&1; then
        alias | sort
    else
        log_error "Alias command not available"
        return 1
    fi
}

# Reload aliases
cmd_reload_aliases() {
    log_info "Reloading alias configurations..."
    
    # Try to reload based on current shell
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        if [[ -f "$HOME/.zshrc" ]]; then
            source "$HOME/.zshrc"
            log_success "ZSH aliases reloaded"
        else
            log_warn "~/.zshrc not found"
        fi
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        if [[ -f "$HOME/.bashrc" ]]; then
            source "$HOME/.bashrc"
            log_success "Bash aliases reloaded"
        else
            log_warn "~/.bashrc not found"
        fi
    else
        log_warn "Unknown shell, cannot reload automatically"
        log_info "Try: source ~/.zshrc or source ~/.bashrc"
    fi
}

# Main function
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        install-plugins)
            cmd_install_plugins "$@"
            ;;
        setup-work-aliases)
            cmd_setup_work_aliases "$@"
            ;;
        migrate-aliases)
            cmd_migrate_aliases "$@"
            ;;
        list-aliases)
            cmd_list_aliases "$@"
            ;;
        reload-aliases)
            cmd_reload_aliases "$@"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_usage
            return 1
            ;;
    esac
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi