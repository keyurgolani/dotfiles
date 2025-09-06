#!/usr/bin/env bash

set -euo pipefail

# Source core utilities if available
if [[ -n "${DOTFILES_ROOT:-}" ]] && [[ -f "$DOTFILES_ROOT/core/logger.sh" ]]; then
    source "$DOTFILES_ROOT/core/logger.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warn() { echo "[WARN] $*"; }
fi

log_info "Installing git module..."

# Check if git is available
if ! command -v git >/dev/null 2>&1; then
    log_warn "Git is not installed. Please install git first."
    exit 1
fi

# The actual file installation is handled by the module system
# This script just provides additional setup if needed

log_success "Git module installed successfully"

# Check if user configuration is set
if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
    local git_name git_email
    git_name=$(git config --global user.name)
    git_email=$(git config --global user.email)
    log_info "Git user configuration:"
    log_info "  Name: $git_name"
    log_info "  Email: $git_email"
else
    log_info "Remember to configure your git user information:"
    log_info "  git config --global user.name 'Your Name'"
    log_info "  git config --global user.email 'your.email@example.com'"
fi