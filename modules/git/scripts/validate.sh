#!/bin/bash

# Git Module Validation Script
# Validates that the git module is properly installed and configured

set -euo pipefail

# Source the logger
source "$DOTFILES_ROOT/core/logger.sh"

log_info "Validating Git module installation"

validation_errors=0

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
    log_error "Git is not installed or not in PATH"
    ((validation_errors++))
else
    log_success "✓ Git is installed"
fi

# Check if gitconfig exists
if [[ -f "$HOME/.gitconfig" ]]; then
    log_success "✓ Git configuration file exists"
    
    # Check if basic configuration is present
    if git config --global user.name >/dev/null 2>&1; then
        local user_name
        user_name=$(git config --global user.name)
        log_success "✓ Git user.name is configured: $user_name"
    else
        log_warn "⚠ Git user.name is not configured"
    fi
    
    if git config --global user.email >/dev/null 2>&1; then
        local user_email
        user_email=$(git config --global user.email)
        log_success "✓ Git user.email is configured: $user_email"
    else
        log_warn "⚠ Git user.email is not configured"
    fi
else
    log_error "Git configuration file not found: $HOME/.gitconfig"
    ((validation_errors++))
fi

# Check if global gitignore exists
if [[ -f "$HOME/.gitignore_global" ]]; then
    log_success "✓ Global gitignore file exists"
    
    # Check if it's configured in git
    local excludesfile
    excludesfile=$(git config --global core.excludesfile 2>/dev/null || echo "")
    if [[ "$excludesfile" == "$HOME/.gitignore_global" ]]; then
        log_success "✓ Global gitignore is properly configured"
    else
        log_warn "⚠ Global gitignore file exists but may not be configured in git"
    fi
else
    log_error "Global gitignore file not found: $HOME/.gitignore_global"
    ((validation_errors++))
fi

# Check Git LFS if available
if command -v git-lfs >/dev/null 2>&1; then
    log_success "✓ Git LFS is available"
    
    # Check if Git LFS is initialized
    if git lfs env >/dev/null 2>&1; then
        log_success "✓ Git LFS is initialized"
    else
        log_warn "⚠ Git LFS is available but may not be initialized"
    fi
else
    log_info "ℹ Git LFS is not installed (optional)"
fi

# Check credential helper configuration
local credential_helper
credential_helper=$(git config --global credential.helper 2>/dev/null || echo "")
if [[ -n "$credential_helper" ]]; then
    log_success "✓ Git credential helper is configured: $credential_helper"
else
    log_warn "⚠ Git credential helper is not configured"
fi

# Summary
if [[ $validation_errors -eq 0 ]]; then
    log_success "Git module validation completed successfully"
    exit 0
else
    log_error "Git module validation failed with $validation_errors errors"
    exit 1
fi