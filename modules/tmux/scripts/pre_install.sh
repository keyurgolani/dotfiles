#!/bin/bash
# Unified Dotfiles Framework - Tmux Module Pre-Installation Hook

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

log_info "Running tmux module pre-installation checks..."

# Check for existing tmux configurations
check_existing_configs() {
    log_info "Checking for existing tmux configurations..."
    
    local configs=(
        "$HOME/.tmux.conf"
        "$HOME/.tmux.conf.local"
        "$HOME/.tmux"
        "$HOME/.config/tmux"
    )
    
    local found_configs=()
    
    for config in "${configs[@]}"; do
        if [[ -f "$config" || -d "$config" ]]; then
            found_configs+=("$config")
        fi
    done
    
    if [[ ${#found_configs[@]} -gt 0 ]]; then
        log_warn "Found existing tmux configurations:"
        for config in "${found_configs[@]}"; do
            log_warn "  - $config"
        done
        log_info "These will be backed up before installation"
    else
        log_info "No existing tmux configurations found"
    fi
}

# Check tmux availability
check_tmux_availability() {
    log_info "Checking tmux availability..."
    
    if command -v tmux >/dev/null 2>&1; then
        local tmux_version=$(tmux -V)
        log_success "tmux is available: $tmux_version"
        
        # Check tmux version (require at least 2.1 for mouse support)
        local version_number=$(echo "$tmux_version" | grep -oE '[0-9]+\.[0-9]+' | head -1)
        local major_version=$(echo "$version_number" | cut -d. -f1)
        local minor_version=$(echo "$version_number" | cut -d. -f2)
        
        if [[ "$major_version" -gt 2 ]] || [[ "$major_version" -eq 2 && "$minor_version" -ge 1 ]]; then
            log_success "Tmux version supports modern features (>= 2.1)"
        else
            log_warn "Tmux version is old ($version_number), some features may not work"
        fi
    else
        log_warn "tmux is not available, will be installed if possible"
    fi
}

# Check clipboard integration tools
check_clipboard_tools() {
    log_info "Checking clipboard integration tools..."
    
    case "$(uname)" in
        "Darwin")
            if command -v reattach-to-user-namespace >/dev/null 2>&1; then
                log_success "reattach-to-user-namespace is available (macOS clipboard)"
            else
                log_warn "reattach-to-user-namespace not found, will be installed for clipboard support"
            fi
            
            if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
                log_success "pbcopy/pbpaste available (macOS clipboard)"
            else
                log_warn "pbcopy/pbpaste not available"
            fi
            ;;
        "Linux")
            if command -v xclip >/dev/null 2>&1; then
                log_success "xclip is available (Linux clipboard)"
            else
                log_warn "xclip not found, will be installed for clipboard support"
            fi
            
            # Check for alternative clipboard tools
            if command -v xsel >/dev/null 2>&1; then
                log_info "xsel is also available as clipboard alternative"
            fi
            ;;
        *)
            log_warn "Unknown platform, clipboard integration may need manual setup"
            ;;
    esac
}

# Check git availability (for plugin manager)
check_git_availability() {
    log_info "Checking git availability (for plugin management)..."
    
    if command -v git >/dev/null 2>&1; then
        log_success "git is available: $(git --version)"
    else
        log_warn "git not available, plugin manager installation will be skipped"
    fi
}

# Check current tmux sessions
check_current_sessions() {
    if command -v tmux >/dev/null 2>&1; then
        log_info "Checking current tmux sessions..."
        
        local session_count=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        # Ensure session_count is a valid number by removing leading zeros and defaulting to 0
        session_count=$(echo "$session_count" | sed 's/^0*//' || echo "0")
        session_count=${session_count:-0}
        
        if [[ $session_count -gt 0 ]]; then
            log_warn "Found $session_count active tmux session(s)"
            log_info "You may need to reload tmux config or restart sessions after installation"
            
            # List sessions
            log_info "Active sessions:"
            tmux list-sessions 2>/dev/null | while read -r session; do
                log_info "  - $session"
            done
        else
            log_info "No active tmux sessions found"
        fi
    fi
}

# Check environment variables
check_environment_variables() {
    log_info "Checking tmux-related environment variables..."
    
    local env_vars=(
        "TMUX_PREFIX_KEY"
        "TMUX_ENABLE_MOUSE"
        "TMUX_COLOR_SCHEME"
        "TMUX_ENABLE_PLUGINS"
        "TMUX_AUTO_START"
    )
    
    local custom_vars=0
    for var in "${env_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            log_info "$var is set: ${!var}"
            ((custom_vars++))
        fi
    done
    
    if [[ $custom_vars -eq 0 ]]; then
        log_info "No custom tmux environment variables set (will use defaults)"
    else
        log_info "Found $custom_vars custom environment variable(s)"
    fi
    
    # Check TMUX variable (indicates if we're already in tmux)
    if [[ -n "${TMUX:-}" ]]; then
        log_warn "Currently running inside tmux session"
        log_info "Some configuration changes may require session restart"
    else
        log_info "Not currently in tmux session"
    fi
}

# Check terminal capabilities
check_terminal_capabilities() {
    log_info "Checking terminal capabilities..."
    
    # Check color support
    if [[ -n "${TERM:-}" ]]; then
        log_info "Terminal type: $TERM"
        
        case "$TERM" in
            *256color*)
                log_success "Terminal supports 256 colors"
                ;;
            *color*)
                log_info "Terminal supports basic colors"
                ;;
            *)
                log_warn "Terminal color support unknown"
                ;;
        esac
    else
        log_warn "TERM variable not set"
    fi
    
    # Check for screen/tmux terminal
    case "${TERM:-}" in
        screen*|tmux*)
            log_info "Terminal indicates tmux/screen environment"
            ;;
    esac
}

# Check shell compatibility
check_shell_compatibility() {
    log_info "Checking shell compatibility..."
    
    local current_shell=$(basename "${SHELL:-}")
    log_info "Current shell: $current_shell"
    
    case "$current_shell" in
        bash|zsh|fish)
            log_success "Shell is compatible with tmux auto-start"
            ;;
        *)
            log_warn "Shell compatibility with tmux auto-start unknown"
            ;;
    esac
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
    
    # Check if we can create .tmux directory
    if [[ ! -d "$HOME/.tmux" ]]; then
        if mkdir -p "$HOME/.tmux" 2>/dev/null; then
            log_success "Can create .tmux directory"
            rmdir "$HOME/.tmux" 2>/dev/null || true
        else
            log_error "Cannot create .tmux directory"
            return 1
        fi
    else
        log_success ".tmux directory exists and is accessible"
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
    log_info "Starting tmux module pre-installation checks..."
    
    check_existing_configs
    check_tmux_availability
    check_clipboard_tools
    check_git_availability
    check_current_sessions
    check_environment_variables
    check_terminal_capabilities
    check_shell_compatibility
    check_permissions
    
    log_success "Tmux module pre-installation checks completed!"
}

# Run main function
main "$@"