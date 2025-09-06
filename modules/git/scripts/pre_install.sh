#!/bin/bash
# Unified Dotfiles Framework - Git Module Pre-Installation Hook

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

log_info "Running git module pre-installation checks..."

# Check for existing git configurations
check_existing_configs() {
    log_info "Checking for existing git configurations..."
    
    local configs=(
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
        "$HOME/.gitconfig.local"
    )
    
    local found_configs=()
    
    for config in "${configs[@]}"; do
        if [[ -f "$config" ]]; then
            found_configs+=("$config")
        fi
    done
    
    if [[ ${#found_configs[@]} -gt 0 ]]; then
        log_info "Found existing git configurations:"
        for config in "${found_configs[@]}"; do
            log_info "  ✓ $config"
        done
        log_info "These will be backed up before installation"
    else
        log_info "No existing git configurations found"
    fi
}

# Check git availability
check_git_availability() {
    log_info "Checking git availability..."
    
    if command -v git >/dev/null 2>&1; then
        local git_version=$(git --version)
        log_success "git is available: $git_version"
        
        # Check git version (require at least 2.0)
        local version_number=$(git --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
        local major_version=$(echo "$version_number" | cut -d. -f1)
        
        if [[ "$major_version" -ge 2 ]]; then
            log_success "Git version is supported (>= 2.0)"
        else
            log_warn "Git version is old ($version_number), consider upgrading"
        fi
    else
        log_warn "git is not available, will be installed if possible"
    fi
    
    # Check for git-lfs
    if command -v git-lfs >/dev/null 2>&1; then
        log_success "git-lfs is available: $(git lfs version | head -1)"
    else
        log_warn "git-lfs is not available, will be installed if possible"
    fi
    
    # Check for git-flow
    if command -v git-flow >/dev/null 2>&1; then
        log_success "git-flow is available"
    else
        log_warn "git-flow is not available, will be installed if possible"
    fi
}

# Check current git configuration
check_current_git_config() {
    if command -v git >/dev/null 2>&1; then
        log_info "Checking current git configuration..."
        
        # Check user configuration
        if git config --global user.name >/dev/null 2>&1; then
            local current_name=$(git config --global user.name)
            log_info "Current git user name: $current_name"
        else
            log_warn "Git user name not configured"
        fi
        
        if git config --global user.email >/dev/null 2>&1; then
            local current_email=$(git config --global user.email)
            log_info "Current git user email: $current_email"
        else
            log_warn "Git user email not configured"
        fi
        
        # Check credential helper
        if git config --global credential.helper >/dev/null 2>&1; then
            local current_helper=$(git config --global credential.helper)
            log_info "Current credential helper: $current_helper"
        else
            log_warn "No credential helper configured"
        fi
        
        # Check global gitignore
        if git config --global core.excludesfile >/dev/null 2>&1; then
            local excludesfile=$(git config --global core.excludesfile)
            log_info "Current global gitignore: $excludesfile"
            
            # Expand tilde in path for checking
            local expanded_path="${excludesfile/#\~/$HOME}"
            
            if [[ -f "$expanded_path" ]]; then
                log_success "Global gitignore file exists"
            else
                log_warn "Global gitignore file configured but doesn't exist"
            fi
        else
            log_info "No global gitignore configured (this is optional)"
        fi
    fi
}

# Check environment variables
check_environment_variables() {
    log_info "Checking git-related environment variables..."
    
    # Check optional environment variables (these are not required)
    if [[ -n "${GIT_USER_NAME:-}" ]]; then
        log_info "GIT_USER_NAME is set: $GIT_USER_NAME"
    else
        log_debug "GIT_USER_NAME is not set (using git config instead)"
    fi
    
    if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
        log_info "GIT_USER_EMAIL is set: $GIT_USER_EMAIL"
    else
        log_debug "GIT_USER_EMAIL is not set (using git config instead)"
    fi
    
    if [[ -n "${GIT_EDITOR:-}" ]]; then
        log_info "GIT_EDITOR is set: $GIT_EDITOR"
    else
        log_debug "GIT_EDITOR is not set (will use git default)"
    fi
    
    if [[ -n "${GIT_CREDENTIAL_HELPER:-}" ]]; then
        log_info "GIT_CREDENTIAL_HELPER is set: $GIT_CREDENTIAL_HELPER"
    else
        log_debug "GIT_CREDENTIAL_HELPER is not set (using platform default)"
    fi
    
    if [[ -n "${GIT_SIGNING_KEY:-}" ]]; then
        log_info "GIT_SIGNING_KEY is set: [hidden]"
    else
        log_debug "GIT_SIGNING_KEY is not set (GPG signing disabled)"
    fi
    
    if [[ -n "${GIT_ENABLE_SIGNING:-}" ]]; then
        log_info "GIT_ENABLE_SIGNING is set: $GIT_ENABLE_SIGNING"
    else
        log_debug "GIT_ENABLE_SIGNING is not set (GPG signing disabled)"
    fi
}

# Check GPG availability if signing is enabled
check_gpg_availability() {
    if [[ "${GIT_ENABLE_SIGNING:-false}" == "true" ]]; then
        log_info "Checking GPG availability (signing enabled)..."
        
        if command -v gpg >/dev/null 2>&1; then
            log_success "GPG is available: $(gpg --version | head -1)"
            
            # Check for GPG keys
            if gpg --list-secret-keys >/dev/null 2>&1; then
                local key_count=$(gpg --list-secret-keys --keyid-format LONG | grep -c "^sec" || echo "0")
                log_info "GPG secret keys available: $key_count"
            else
                log_warn "No GPG secret keys found"
            fi
        else
            log_warn "GPG not available but signing is enabled"
        fi
    else
        log_info "GPG signing disabled, skipping GPG checks"
    fi
}

# Check permissions
check_permissions() {
    log_info "Checking permissions..."
    
    if [[ -w "$HOME" ]]; then
        log_success "Home directory is writable"
    else
        log_error "Home directory is not writable"
        return 1
    fi
    
    # Check if we can create .config directory
    if [[ ! -d "$HOME/.config" ]]; then
        if mkdir -p "$HOME/.config" 2>/dev/null; then
            log_success "Can create .config directory"
            rmdir "$HOME/.config" 2>/dev/null || true
        else
            log_error "Cannot create .config directory"
            return 1
        fi
    else
        log_success ".config directory exists and is accessible"
    fi
}

# Main pre-installation checks
main() {
    log_info "Starting git module pre-installation checks..."
    
    check_existing_configs
    check_git_availability
    check_current_git_config
    check_environment_variables
    check_gpg_availability
    check_permissions
    
    log_success "Git module pre-installation checks completed!"
}

# Run main function
main "$@"