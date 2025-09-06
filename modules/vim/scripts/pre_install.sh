#!/bin/bash
# Unified Dotfiles Framework - Vim Module Pre-Installation Hook

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

log_info "Running vim module pre-installation checks..."

# Check for existing vim configurations
check_existing_configs() {
    log_info "Checking for existing vim configurations..."
    
    local configs=(
        "$HOME/.vimrc"
        "$HOME/.vimrc.local"
        "$HOME/.vim"
    )
    
    local found_configs=()
    
    for config in "${configs[@]}"; do
        if [[ -f "$config" || -d "$config" ]]; then
            found_configs+=("$config")
        fi
    done
    
    if [[ ${#found_configs[@]} -gt 0 ]]; then
        log_warn "Found existing vim configurations:"
        for config in "${found_configs[@]}"; do
            log_warn "  - $config"
        done
        log_info "These will be backed up before installation"
    else
        log_info "No existing vim configurations found"
    fi
}

# Check vim availability
check_vim_availability() {
    log_info "Checking vim availability..."
    
    if command -v vim >/dev/null 2>&1; then
        local vim_version=$(vim --version | head -1)
        log_success "vim is available: $vim_version"
        
        # Check vim version (require at least 7.4)
        local version_number=$(vim --version | grep -oE 'VIM - Vi IMproved [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+')
        local major_version=$(echo "$version_number" | cut -d. -f1)
        local minor_version=$(echo "$version_number" | cut -d. -f2)
        
        if [[ "$major_version" -gt 7 ]] || [[ "$major_version" -eq 7 && "$minor_version" -ge 4 ]]; then
            log_success "Vim version is supported (>= 7.4)"
        else
            log_warn "Vim version is old ($version_number), some features may not work"
        fi
        
        # Check for essential vim features
        local essential_features=("+clipboard" "+autocmd" "+syntax")
        local optional_features=("+python" "+python3")
        
        log_info "Checking essential vim features..."
        for feature in "${essential_features[@]}"; do
            if vim --version | grep -q "$feature"; then
                log_success "Vim feature available: $feature"
            else
                log_warn "Vim feature not available: $feature"
            fi
        done
        
        log_info "Checking optional vim features..."
        local python_available=false
        for feature in "${optional_features[@]}"; do
            if vim --version | grep -q "$feature"; then
                log_success "Vim feature available: $feature"
                python_available=true
            fi
        done
        
        if [[ "$python_available" == "false" ]]; then
            log_info "Python support not available (normal on macOS default vim)"
            log_info "For Python support, consider: brew install vim or brew install macvim"
        fi
    else
        log_warn "vim is not available, will be installed if possible"
    fi
}

# Check Node.js availability (for CoC completion)
check_nodejs_availability() {
    log_info "Checking Node.js availability (for advanced completion)..."
    
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version)
        log_success "Node.js is available: $node_version"
        
        # Check Node.js version (require at least 10.12)
        local version_number=$(echo "$node_version" | sed 's/v//')
        local major_version=$(echo "$version_number" | cut -d. -f1)
        
        if [[ "$major_version" -ge 10 ]]; then
            log_success "Node.js version is supported (>= 10.12)"
        else
            log_warn "Node.js version is old ($node_version), CoC may not work properly"
        fi
        
        # Check npm
        if command -v npm >/dev/null 2>&1; then
            log_success "npm is available: $(npm --version)"
        else
            log_warn "npm not available, some vim plugins may not install properly"
        fi
    else
        log_warn "Node.js not available, advanced completion features will be limited"
    fi
}

# Check curl availability (for plugin manager installation)
check_curl_availability() {
    log_info "Checking curl availability (for plugin installation)..."
    
    if command -v curl >/dev/null 2>&1; then
        log_success "curl is available: $(curl --version | head -1)"
    else
        log_warn "curl not available, plugin manager installation may fail"
    fi
}

# Check git availability (for plugin management)
check_git_availability() {
    log_info "Checking git availability (for plugin management)..."
    
    if command -v git >/dev/null 2>&1; then
        log_success "git is available: $(git --version)"
    else
        log_warn "git not available, some vim plugins may not install properly"
    fi
}

# Check environment variables
check_environment_variables() {
    log_info "Checking vim-related environment variables..."
    
    local env_vars=(
        "VIM_PLUGIN_MANAGER"
        "VIM_COLOR_SCHEME"
        "VIM_LEADER_KEY"
        "VIM_ENABLE_PLUGINS"
        "VIM_ENABLE_WEB_PLUGINS"
    )
    
    local custom_vars=0
    for var in "${env_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            log_info "$var is set: ${!var}"
            ((custom_vars++))
        fi
    done
    
    if [[ $custom_vars -eq 0 ]]; then
        log_info "No custom vim environment variables set (will use defaults)"
    else
        log_info "Found $custom_vars custom environment variable(s)"
    fi
    
    # Check EDITOR variable
    if [[ -n "${EDITOR:-}" ]]; then
        log_info "EDITOR is set: $EDITOR"
    else
        log_info "EDITOR not set (will be set to vim)"
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
    
    # Check for tmux/screen
    if [[ -n "${TMUX:-}" ]]; then
        log_info "Running inside tmux"
    elif [[ -n "${STY:-}" ]]; then
        log_info "Running inside screen"
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
    
    # Check if we can create .vim directory
    if [[ ! -d "$HOME/.vim" ]]; then
        if mkdir -p "$HOME/.vim" 2>/dev/null; then
            log_success "Can create .vim directory"
            rmdir "$HOME/.vim" 2>/dev/null || true
        else
            log_error "Cannot create .vim directory"
            return 1
        fi
    else
        log_success ".vim directory exists and is accessible"
    fi
}

# Main pre-installation checks
main() {
    log_info "Starting vim module pre-installation checks..."
    
    check_existing_configs
    check_vim_availability
    check_nodejs_availability
    check_curl_availability
    check_git_availability
    check_environment_variables
    check_terminal_capabilities
    check_permissions
    
    # Pre-install vim-plug to avoid timeout issues later
    if [[ "${VIM_ENABLE_PLUGINS:-true}" == "true" ]]; then
        log_info "Pre-installing vim-plug to avoid timeout issues..."
        local plug_script="$SCRIPT_DIR/install_vim_plug.sh"
        if [[ -f "$plug_script" ]]; then
            bash "$plug_script" || log_warn "vim-plug pre-installation failed, will retry later"
        fi
    fi
    
    log_success "Vim module pre-installation checks completed!"
}

# Run main function
main "$@"