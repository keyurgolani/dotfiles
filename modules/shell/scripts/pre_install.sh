#!/bin/bash
# Unified Dotfiles Framework - Shell Module Pre-Installation Hook

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

log_info "Running shell module pre-installation checks..."

# Check for existing shell configurations
check_existing_configs() {
    log_info "Checking for existing shell configurations..."
    
    local configs=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.bash_aliases"
        "$HOME/.bash_functions"
        "$HOME/.bash_exports"
    )
    
    local found_configs=()
    
    for config in "${configs[@]}"; do
        if [[ -f "$config" ]]; then
            found_configs+=("$config")
        fi
    done
    
    if [[ ${#found_configs[@]} -gt 0 ]]; then
        log_info "Found existing shell configurations:"
        for config in "${found_configs[@]}"; do
            log_info "  ✓ $config"
        done
        log_info "These will be backed up before installation"
    else
        log_info "No existing shell configurations found"
    fi
}

# Check shell availability
check_shell_availability() {
    log_info "Checking shell availability..."
    
    if command -v bash >/dev/null 2>&1; then
        log_success "bash is available: $(bash --version | head -1)"
    else
        log_error "bash is not available"
        return 1
    fi
    
    if command -v zsh >/dev/null 2>&1; then
        log_success "zsh is available: $(zsh --version)"
    else
        log_warn "zsh is not available, will be installed if possible"
    fi
}

# Check for required tools
check_required_tools() {
    log_info "Checking for required tools..."
    
    local tools=("curl" "git")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_success "$tool is available"
        else
            missing_tools+=("$tool")
            log_warn "$tool is not available"
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_warn "Missing tools: ${missing_tools[*]}"
        log_info "Some features may not work properly"
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
    
    # Check if we can modify /etc/shells (for changing default shell)
    if [[ -w "/etc/shells" ]] || sudo -n true 2>/dev/null; then
        log_success "Can modify /etc/shells (for shell changes)"
    else
        log_info "Cannot modify /etc/shells without sudo access"
        log_info "If you want to change your default shell later, you may need to run:"
        log_info "  sudo chsh -s /bin/zsh $USER"
        log_info "This is normal and doesn't affect the dotfiles installation"
    fi
}

# Main pre-installation checks
main() {
    log_info "Starting shell module pre-installation checks..."
    
    check_existing_configs
    check_shell_availability
    check_required_tools
    check_permissions
    
    log_success "Shell module pre-installation checks completed!"
}

# Run main function
main "$@"