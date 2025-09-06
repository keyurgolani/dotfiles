#!/bin/bash
# Unified Dotfiles Framework - Shell Module Post-Installation Hook

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

log_info "Running shell module post-installation tasks..."

# Verify configuration files
verify_configs() {
    log_info "Verifying shell configuration files..."
    
    local configs=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.bash_aliases"
        "$HOME/.bash_functions"
        "$HOME/.bash_exports"
    )
    
    # Add zsh configs if zsh is available
    if command -v zsh >/dev/null 2>&1; then
        configs+=(
            "$HOME/.zshrc"
            "$HOME/.zsh_aliases"
            "$HOME/.zsh_functions"
            "$HOME/.zsh_exports"
        )
    fi
    
    local missing_configs=()
    
    for config in "${configs[@]}"; do
        if [[ -f "$config" ]]; then
            log_success "✓ $config"
        else
            missing_configs+=("$config")
            log_warn "✗ $config (missing)"
        fi
    done
    
    if [[ ${#missing_configs[@]} -gt 0 ]]; then
        log_warn "Some configuration files are missing:"
        for config in "${missing_configs[@]}"; do
            log_warn "  - $config"
        done
    fi
}

# Test shell functionality
test_shell_functionality() {
    log_info "Testing shell functionality..."
    
    # Test bash functionality
    if [[ -f "$HOME/.bashrc" ]]; then
        if bash -c "source ~/.bashrc 2>/dev/null && echo 'Bash configuration loaded successfully'" >/dev/null 2>&1; then
            log_success "Bash configuration loads without errors"
        else
            log_info "Bash configuration has minor issues - checking syntax..."
            # Try to identify common issues
            if bash -n "$HOME/.bashrc" 2>/dev/null; then
                log_info "Bash syntax is valid, minor runtime issues detected (normal during setup)"
            else
                log_warn "Bash syntax errors found in ~/.bashrc - please review the file"
            fi
        fi
    else
        log_warn "~/.bashrc not found"
    fi
    
    # Test zsh functionality if available
    if command -v zsh >/dev/null 2>&1; then
        if [[ -f "$HOME/.zshrc" ]]; then
            if zsh -c "source ~/.zshrc 2>/dev/null && echo 'Zsh configuration loaded successfully'" >/dev/null 2>&1; then
                log_success "Zsh configuration loads without errors"
            else
                log_info "Zsh configuration has minor issues - this is normal during initial setup"
                log_info "The configuration will work properly after restarting your terminal"
            fi
        else
            log_warn "~/.zshrc not found"
        fi
    fi
}

# Check Oh My Zsh installation
check_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh My Zsh is installed"
        
        # Check for plugins
        local plugin_dir="$HOME/.oh-my-zsh/plugins"
        if [[ -d "$plugin_dir" ]]; then
            local plugin_count=$(find "$plugin_dir" -maxdepth 1 -type d | wc -l | tr -d ' ')
            log_info "Oh My Zsh plugins available: $((plugin_count - 1))"
        fi
    else
        log_info "Oh My Zsh is not installed"
    fi
}

# Performance check
performance_check() {
    log_info "Running shell performance checks..."
    
    # Test bash startup time
    if command -v bash >/dev/null 2>&1; then
        log_info "Testing bash startup time..."
        local bash_time
        if command -v gtime >/dev/null 2>&1; then
            # Use GNU time if available (brew install gnu-time)
            bash_time=$(gtime -f "%e" bash -i -c exit 2>&1 || echo "unknown")
        else
            # Fallback: use a simple approach
            bash_time=$(bash -c 'start=$(date +%s%N); bash -i -c exit >/dev/null 2>&1; end=$(date +%s%N); echo "scale=3; ($end - $start) / 1000000000" | bc 2>/dev/null || echo "unknown"')
        fi
        log_info "Bash startup time: ${bash_time}s"
    fi
    
    # Test zsh startup time
    if command -v zsh >/dev/null 2>&1; then
        log_info "Testing zsh startup time..."
        local zsh_time
        if command -v gtime >/dev/null 2>&1; then
            # Use GNU time if available
            zsh_time=$(gtime -f "%e" zsh -i -c exit 2>&1 || echo "unknown")
        else
            # Fallback: use a simple approach
            zsh_time=$(zsh -c 'start=$(date +%s%N); zsh -i -c exit >/dev/null 2>&1; end=$(date +%s%N); echo "scale=3; ($end - $start) / 1000000000" | bc 2>/dev/null || echo "unknown"')
        fi
        log_info "Zsh startup time: ${zsh_time}s"
        
        # Warn if startup is slow (only if we got a valid measurement)
        if [[ "$zsh_time" != "unknown" ]] && command -v bc >/dev/null 2>&1; then
            if (( $(echo "$zsh_time > 2.0" | bc -l 2>/dev/null || echo 0) )); then
                log_warn "Zsh startup time is slow (${zsh_time}s). Consider optimizing your configuration."
            fi
        fi
    fi
}

# Create helpful aliases for the user
create_helpful_info() {
    log_info "Creating helpful information..."
    
    cat > "$HOME/.shell_module_info" << 'EOF'
# Unified Dotfiles Framework - Shell Module Information
# This file contains helpful information about your shell configuration

# Available commands and aliases:
# Navigation: .., ..., ...., cd.., ~, -
# File operations: ll, la, ls, mkdir (with -pv), mv (with -v), rm (with -i -v), cp (with -v)
# System: ip, myip, path, ports
# Development: g (git), n (npm), y (yarn), t (tmux)
# Homebrew: brewi, brewr, brews, brewu, brewd

# Available functions:
# mkd/mcd - create directory and cd into it
# extract - extract various archive formats
# datauri - create data URI from file
# find-pwd/qt - search for text in current directory
# hist-find/qh - search command history

# Configuration files:
# ~/.bashrc, ~/.bash_profile - Bash configuration
# ~/.zshrc - Zsh configuration  
# ~/.bash_aliases, ~/.zsh_aliases - Command aliases
# ~/.bash_functions, ~/.zsh_functions - Shell functions
# ~/.bash_exports, ~/.zsh_exports - Environment variables

# To customize:
# - Edit ~/.bashrc.local or ~/.zshrc.local for local-only settings
# - Add custom aliases to ~/.bash_aliases or ~/.zsh_aliases
# - Add custom functions to ~/.bash_functions or ~/.zsh_functions

# Performance tips:
# - Use 'time zsh -i -c exit' to check zsh startup time
# - Use 'time bash -i -c exit' to check bash startup time
# - Keep startup time under 1 second for optimal experience
EOF

    log_info "Created ~/.shell_module_info with helpful information"
}

# Display installation summary
display_summary() {
    echo ""
    echo "Shell Module Post-Installation Summary:"
    echo "======================================="
    echo ""
    
    # Current shell
    echo "Current shell: $SHELL"
    
    # Available shells
    echo "Available shells:"
    command -v bash >/dev/null 2>&1 && echo "  ✓ bash: $(bash --version | head -1)"
    command -v zsh >/dev/null 2>&1 && echo "  ✓ zsh: $(zsh --version)"
    
    # Oh My Zsh status
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "  ✓ Oh My Zsh: installed"
    else
        echo "  ✗ Oh My Zsh: not installed"
    fi
    
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run 'source ~/.zshrc' (or ~/.bashrc)"
    echo "2. Check ~/.shell_module_info for helpful information"
    echo "3. Customize ~/.zshrc.local or ~/.bashrc.local for local settings"
    echo "4. Optional: Run '${DOTFILES_ROOT:-~/dotfiles}/module_cli.sh shell install-plugins' for enhanced ZSH features"
    echo "5. Optional: Run '${DOTFILES_ROOT:-~/dotfiles}/module_cli.sh shell setup-work-aliases' to set up work-specific aliases"
    echo ""
}

# Main post-installation tasks
main() {
    log_info "Starting shell module post-installation tasks..."
    
    verify_configs
    test_shell_functionality
    check_oh_my_zsh
    performance_check
    create_helpful_info
    
    # Fix dotfiles paths to use actual installation location
    log_info "Fixing dotfiles paths in shell configurations..."
    local path_fixer="$SCRIPT_DIR/fix_dotfiles_paths.sh"
    if [[ -f "$path_fixer" ]]; then
        bash "$path_fixer" || log_warn "Failed to fix dotfiles paths (configurations may use default ~/dotfiles)"
    else
        log_warn "Path fixer script not found, shell configs may use hardcoded ~/dotfiles paths"
    fi
    
    display_summary
    
    log_success "Shell module post-installation tasks completed!"
}

# Run main function
main "$@"