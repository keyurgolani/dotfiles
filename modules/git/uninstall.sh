#!/bin/bash
# Unified Dotfiles Framework - Git Module Uninstallation

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

# Module information
MODULE_NAME="git"

log_info "Uninstalling git module..."

# Remove configuration files
remove_config_files() {
    log_info "Removing git configuration files..."
    
    local files=(
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "Removing $file..."
            rm -f "$file"
        fi
    done
}

# Reset git configuration
reset_git_config() {
    log_info "Resetting git global configuration..."
    
    # Note: We don't remove user.name and user.email as these are personal settings
    # that the user might want to keep
    
    local configs_to_remove=(
        "core.excludesfile"
        "core.editor"
        "core.pager"
        "init.defaultBranch"
        "push.followTags"
        "pull.rebase"
        "fetch.prune"
        "merge.conflictstyle"
        "diff.colorMoved"
        "color.ui"
        "commit.gpgsign"
        "tag.gpgsign"
    )
    
    for config in "${configs_to_remove[@]}"; do
        if git config --global --get "$config" >/dev/null 2>&1; then
            log_info "Removing git config: $config"
            git config --global --unset "$config" || log_warn "Failed to unset $config"
        fi
    done
}

# Clean up directories
cleanup_directories() {
    log_info "Cleaning up git-related directories..."
    
    # We don't remove ~/.config/git as it might contain other important files
    log_info "Note: ~/.config/git directory was not removed (may contain other files)"
}

# Main uninstallation
main() {
    log_info "Starting git module uninstallation..."
    
    remove_config_files
    reset_git_config
    cleanup_directories
    
    log_success "Git module uninstallation completed!"
    log_info "Note: Git packages were not removed (remove manually if desired)"
    log_info "Note: User name and email were preserved"
    
    echo ""
    echo "Git Module Uninstallation Summary:"
    echo "=================================="
    echo "• Configuration files removed"
    echo "• Global git settings reset"
    echo "• User identity preserved"
    echo "• Git packages left intact"
    echo ""
    echo "Remaining git configuration:"
    echo "• User name: $(git config --global user.name 2>/dev/null || echo 'Not set')"
    echo "• User email: $(git config --global user.email 2>/dev/null || echo 'Not set')"
    echo ""
}

# Run main function
main "$@"