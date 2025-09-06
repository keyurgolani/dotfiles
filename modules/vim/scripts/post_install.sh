#!/bin/bash
# Unified Dotfiles Framework - Vim Module Post-Installation Hook

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

log_info "Running vim module post-installation tasks..."

# Verify vim configuration
verify_vim_config() {
    log_info "Verifying vim configuration..."
    
    if [[ -f "$HOME/.vimrc" ]]; then
        log_success "✓ ~/.vimrc exists"
        
        # Test vim configuration syntax
        if vim -T dumb --not-a-term -n -e -s -c "source ~/.vimrc" -c "qall" >/dev/null 2>&1; then
            log_success "✓ Vim configuration loads without errors"
        else
            log_warn "⚠ Vim configuration has syntax errors"
        fi
    else
        log_error "✗ ~/.vimrc not found"
    fi
}

# Verify vim directories
verify_vim_directories() {
    log_info "Verifying vim directories..."
    
    local directories=(
        "$HOME/.vim/backups"
        "$HOME/.vim/swaps"
        "$HOME/.vim/undos"
        "$HOME/.vim/plugins"
        "$HOME/.vim/autoload"
    )
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "✓ $dir"
        else
            log_info "Creating missing directory: $dir"
            if mkdir -p "$dir" 2>/dev/null; then
                log_success "✓ $dir (created)"
            else
                log_warn "✗ $dir (failed to create)"
            fi
        fi
    done
}

# Check plugin manager installation
check_plugin_manager() {
    log_info "Checking plugin manager installation..."
    
    if [[ -f "$HOME/.vim/autoload/plug.vim" ]]; then
        log_success "✓ vim-plug is installed"
    else
        log_warn "⚠ vim-plug not found, will be installed on first vim startup"
    fi
}

# Install vim-plug plugin manager
install_vim_plug() {
    log_info "Ensuring vim-plug is installed..."
    
    local plug_script="$SCRIPT_DIR/install_vim_plug.sh"
    if [[ -f "$plug_script" ]]; then
        if bash "$plug_script"; then
            log_success "✓ vim-plug installation verified"
        else
            log_warn "⚠ vim-plug installation failed, plugins will be installed on first vim startup"
            return 1
        fi
    else
        # Fallback installation
        if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
            log_info "Installing vim-plug directly..."
            mkdir -p "$HOME/.vim/autoload"
            if command -v curl >/dev/null 2>&1; then
                if curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
                   https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 2>/dev/null; then
                    log_success "✓ vim-plug installed successfully"
                else
                    log_warn "⚠ Failed to install vim-plug, plugins will be installed on first vim startup"
                    return 1
                fi
            else
                log_warn "⚠ curl not available, vim-plug will be installed on first vim startup"
                return 1
            fi
        else
            log_success "✓ vim-plug already installed"
        fi
    fi
    return 0
}

# Install vim plugins
install_plugins() {
    if [[ "${VIM_ENABLE_PLUGINS:-true}" == "true" ]]; then
        log_info "Setting up vim plugins..."
        
        # First ensure vim-plug is installed
        if ! install_vim_plug; then
            log_info "vim-plug not available, plugins will be installed on first vim startup"
            return 0
        fi
        
        if [[ ! -f "$HOME/.vimrc" ]]; then
            log_warn "⚠ vimrc not found, skipping plugin installation"
            return 0
        fi
        
        # Skip automatic plugin installation to avoid timeouts
        # Let vim handle it on first startup as designed
        log_info "Plugins will be automatically installed on first vim startup"
        log_info "You can also manually run: vim +PlugInstall +qall"
        
        return 0
    else
        log_info "Vim plugins disabled, skipping installation"
    fi
}

# Test vim functionality
test_vim_functionality() {
    log_info "Testing vim functionality..."
    
    # Test basic vim startup
    if vim --version >/dev/null 2>&1; then
        log_success "✓ Vim starts successfully"
    else
        log_error "✗ Vim fails to start"
        return 1
    fi
    
    # Test vim with configuration
    if vim -T dumb --not-a-term -n -e -s -c "echo 'test'" -c "qall" >/dev/null 2>&1; then
        log_success "✓ Vim loads configuration successfully"
    else
        log_warn "⚠ Vim configuration may have issues"
    fi
}

# Check plugin status
check_plugin_status() {
    if [[ "${VIM_ENABLE_PLUGINS:-true}" == "true" && -d "$HOME/.vim/plugins" ]]; then
        log_info "Checking installed plugins..."
        
        local plugin_count=$(find "$HOME/.vim/plugins" -maxdepth 1 -type d | wc -l | tr -d ' ')
        plugin_count=$((plugin_count - 1))  # Subtract 1 for the plugins directory itself
        
        if [[ $plugin_count -gt 0 ]]; then
            log_success "✓ $plugin_count plugins installed"
            
            # List some key plugins
            local key_plugins=(
                "nerdtree"
                "ctrlp.vim"
                "vim-fugitive"
                "vim-surround"
                "coc.nvim"
            )
            
            for plugin in "${key_plugins[@]}"; do
                if [[ -d "$HOME/.vim/plugins/$plugin" ]]; then
                    log_success "  ✓ $plugin"
                fi
            done
        else
            log_warn "⚠ No plugins found in ~/.vim/plugins"
        fi
    fi
}

# Performance check
performance_check() {
    log_info "Running vim performance checks..."
    
    # Test vim startup time
    log_info "Testing vim startup time..."
    local startup_time
    if command -v gtime >/dev/null 2>&1; then
        # Use GNU time if available
        startup_time=$(gtime -f "%e" vim --not-a-term -c "qall" 2>&1 || echo "unknown")
    elif command -v bc >/dev/null 2>&1; then
        # Fallback: use date-based timing
        startup_time=$(bash -c 'start=$(date +%s%N); vim --not-a-term -c "qall" >/dev/null 2>&1; end=$(date +%s%N); echo "scale=3; ($end - $start) / 1000000000" | bc' 2>/dev/null || echo "unknown")
    else
        startup_time="unknown"
    fi
    
    log_info "Vim startup time: ${startup_time}s"
    
    # Warn if startup is very slow (only if we got a valid measurement)
    if [[ "$startup_time" != "unknown" ]] && command -v bc >/dev/null 2>&1; then
        if (( $(echo "$startup_time > 1.0" | bc -l 2>/dev/null || echo 0) )); then
            log_warn "Vim startup time is slow (${startup_time}s). Consider reducing plugins."
        fi
    fi
}

# Create helpful information file
create_helpful_info() {
    log_info "Creating helpful information..."
    
    cat > "$HOME/.vim_module_info" << 'EOF'
# Unified Dotfiles Framework - Vim Module Information
# This file contains helpful information about your vim configuration

# Key Features:
# - Modern vim configuration with sensible defaults
# - Plugin management via vim-plug
# - Comprehensive key mappings with comma (,) as leader
# - Language-specific shortcuts and settings
# - Git integration via vim-fugitive
# - File explorer via NERDTree
# - Intelligent completion via CoC (if Node.js available)

# Essential Key Mappings:
# File Operations:
#   <leader>w  - Save file
#   <leader>q  - Quit
#   <leader>x  - Save and quit
#   <leader>W  - Sudo save

# Navigation:
#   H          - Go to beginning of line
#   L          - Go to end of line
#   J          - Go to bottom of file
#   K          - Go to top of file
#   <tab>      - Jump to matching bracket

# Plugins:
#   <leader>nt - Toggle NERDTree file explorer
#   <leader>gd - Toggle git diff signs
#   <C-p>      - Fuzzy file finder (CtrlP)

# Search and Replace:
#   <C-l>      - Clear search highlighting
#   <leader>*  - Search and replace word under cursor

# Window Management:
#   <leader>v  - Vertical split
#   <leader>s  - Horizontal split
#   <leader>t  - New tab

# Language Shortcuts:
#   <leader>sys  - System.out.println() (Java)
#   <leader>con  - console.log() (JavaScript)
#   <leader>cout - std::cout << (C++)
#   <leader>out  - printf() (C)

# Plugin Management:
#   :PlugInstall - Install plugins
#   :PlugUpdate  - Update plugins
#   :PlugClean   - Remove unused plugins

# CoC Commands (if available):
#   :CocInstall coc-json coc-tsserver coc-python
#   gd         - Go to definition
#   gy         - Go to type definition
#   gr         - Go to references

# Configuration Files:
#   ~/.vimrc       - Main configuration
#   ~/.vimrc.local - Local customizations (not synced)

# Directories:
#   ~/.vim/plugins - Installed plugins
#   ~/.vim/backups - Backup files
#   ~/.vim/swaps   - Swap files
#   ~/.vim/undos   - Undo history

# Color Schemes:
# Available: solarized, gruvbox, dracula
# Change via: let g:vim_color_scheme = "gruvbox" in ~/.vimrc.local

# Tips:
# - Use :help <command> for detailed help
# - Customize settings in ~/.vimrc.local
# - Install language servers for better completion
# - Use :PlugStatus to check plugin status
EOF

    log_info "Created ~/.vim_module_info with helpful information"
}

# Display installation summary
display_summary() {
    echo ""
    echo "Vim Module Post-Installation Summary:"
    echo "====================================="
    echo ""
    
    # Vim version
    if command -v vim >/dev/null 2>&1; then
        echo "Vim version: $(vim --version | head -1)"
    fi
    
    # Configuration status
    if [[ -f "$HOME/.vimrc" ]]; then
        echo "✓ Configuration: ~/.vimrc installed"
    else
        echo "✗ Configuration: ~/.vimrc missing"
    fi
    
    # Plugin manager status
    if [[ -f "$HOME/.vim/autoload/plug.vim" ]]; then
        echo "✓ Plugin manager: vim-plug installed"
    else
        echo "✗ Plugin manager: vim-plug missing"
    fi
    
    # Plugin status
    if [[ "${VIM_ENABLE_PLUGINS:-true}" == "true" ]]; then
        if [[ -d "$HOME/.vim/plugins" ]]; then
            local plugin_count=$(find "$HOME/.vim/plugins" -maxdepth 1 -type d | wc -l | tr -d ' ')
            plugin_count=$((plugin_count - 1))
            echo "✓ Plugins: $plugin_count installed"
        else
            echo "⚠ Plugins: directory not found"
        fi
    else
        echo "- Plugins: disabled"
    fi
    
    # Node.js status for CoC
    if command -v node >/dev/null 2>&1; then
        echo "✓ Node.js: $(node --version) (CoC available)"
    else
        echo "- Node.js: not available (limited completion)"
    fi
    
    echo ""
    echo "Next steps:"
    echo "1. Start vim - plugins will install automatically on first run"
    echo "2. If plugins don't install automatically, run: vim +PlugInstall +qall"
    echo "3. Install CoC language servers: :CocInstall coc-json coc-tsserver"
    echo "4. Customize ~/.vimrc.local for personal preferences"
    echo "5. Check ~/.vim_module_info for usage tips"
    echo ""
    echo "Quick test: vim --version"
    echo ""
}

# Main post-installation tasks
main() {
    log_info "Starting vim module post-installation tasks..."
    
    verify_vim_config
    verify_vim_directories
    install_plugins
    test_vim_functionality
    check_plugin_status
    performance_check
    create_helpful_info
    display_summary
    
    log_success "Vim module post-installation tasks completed!"
}

# Run main function
main "$@"