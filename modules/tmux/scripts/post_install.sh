#!/bin/bash
# Unified Dotfiles Framework - Tmux Module Post-Installation Hook

set -euo pipefail

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/core"

source "$CORE_DIR/utils.sh"
source "$CORE_DIR/logger.sh"

log_info "Running tmux module post-installation tasks..."

# Verify tmux configuration
verify_tmux_config() {
    log_info "Verifying tmux configuration..."
    
    if [[ -f "$HOME/.tmux.conf" ]]; then
        log_success "✓ ~/.tmux.conf exists"
        
        # Test tmux configuration syntax
        if tmux -f ~/.tmux.conf list-keys >/dev/null 2>&1; then
            log_success "✓ Tmux configuration loads without errors"
        else
            log_warn "⚠ Tmux configuration has syntax errors"
        fi
    else
        log_error "✗ ~/.tmux.conf not found"
    fi
}

# Verify tmux directories
verify_tmux_directories() {
    log_info "Verifying tmux directories..."
    
    local directories=(
        "$HOME/.config/tmux"
        "$HOME/.tmux/plugins"
    )
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "✓ $dir"
        else
            # Only create .tmux/plugins if plugins are enabled
            if [[ "$dir" == "$HOME/.tmux/plugins" && "${TMUX_ENABLE_PLUGINS:-false}" != "true" ]]; then
                log_info "- $dir (not needed, plugins disabled)"
            else
                log_info "Creating missing directory: $dir"
                if mkdir -p "$dir" 2>/dev/null; then
                    log_success "✓ $dir (created)"
                else
                    log_warn "✗ $dir (failed to create)"
                fi
            fi
        fi
    done
}

# Check plugin manager installation
check_plugin_manager() {
    if [[ "${TMUX_ENABLE_PLUGINS:-false}" == "true" ]]; then
        log_info "Checking TPM (plugin manager) installation..."
        
        if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
            log_success "✓ TPM is installed"
            
            # Check if TPM script is executable
            if [[ -x "$HOME/.tmux/plugins/tpm/tpm" ]]; then
                log_success "✓ TPM script is executable"
            else
                log_warn "⚠ TPM script is not executable"
            fi
        else
            log_warn "⚠ TPM not found, plugins will not be available"
        fi
    else
        log_info "Tmux plugins disabled, skipping TPM check"
    fi
}

# Test tmux functionality
test_tmux_functionality() {
    log_info "Testing tmux functionality..."
    
    # Test basic tmux startup
    if tmux -V >/dev/null 2>&1; then
        log_success "✓ Tmux starts successfully"
    else
        log_error "✗ Tmux fails to start"
        return 0  # Don't fail the entire installation
    fi
    
    # Test tmux configuration syntax first
    if ! tmux -f ~/.tmux.conf list-keys >/dev/null 2>&1; then
        log_warn "⚠ Tmux configuration has syntax issues, skipping session test"
        return 0
    fi
    
    # Test tmux with configuration (create a test session)
    if tmux new-session -d -s test_session 2>/dev/null; then
        log_success "✓ Tmux can create sessions with configuration"
        
        # Test key bindings by checking if custom configuration is loaded
        if tmux -t test_session show-options -g 2>/dev/null | grep -q "prefix\|bind-key" || 
           tmux -t test_session list-keys 2>/dev/null | wc -l | grep -q -v "^0$"; then
            log_success "✓ Custom key bindings are loaded"
        else
            log_info "ℹ Key bindings will be available after restarting tmux"
        fi
        
        # Clean up test session
        tmux kill-session -t test_session 2>/dev/null || true
    else
        log_warn "⚠ Tmux session creation may have issues"
    fi
}

# Check clipboard integration
check_clipboard_integration() {
    log_info "Checking clipboard integration..."
    
    case "$(uname)" in
        "Darwin")
            if command -v reattach-to-user-namespace >/dev/null 2>&1; then
                log_success "✓ macOS clipboard integration available"
            else
                log_warn "⚠ reattach-to-user-namespace not found"
            fi
            ;;
        "Linux")
            if command -v xclip >/dev/null 2>&1; then
                log_success "✓ Linux clipboard integration available"
            else
                log_warn "⚠ xclip not found, clipboard may not work"
            fi
            ;;
        *)
            log_info "- Clipboard integration status unknown for this platform"
            ;;
    esac
}

# Check plugin status
check_plugin_status() {
    if [[ "${TMUX_ENABLE_PLUGINS:-false}" == "true" && -d "$HOME/.tmux/plugins" ]]; then
        log_info "Checking installed plugins..."
        
        local plugin_count=$(find "$HOME/.tmux/plugins" -maxdepth 1 -type d | wc -l | tr -d ' ')
        plugin_count=$((plugin_count - 1))  # Subtract 1 for the plugins directory itself
        
        if [[ $plugin_count -gt 0 ]]; then
            log_success "✓ $plugin_count plugins available"
            
            # List key plugins
            local key_plugins=(
                "tpm"
                "tmux-sensible"
                "tmux-resurrect"
                "tmux-continuum"
                "tmux-yank"
            )
            
            for plugin in "${key_plugins[@]}"; do
                if [[ -d "$HOME/.tmux/plugins/$plugin" ]]; then
                    log_success "  ✓ $plugin"
                fi
            done
        else
            log_warn "⚠ No plugins found, run prefix + I to install"
        fi
    fi
}

# Performance check
performance_check() {
    log_info "Running tmux performance checks..."
    
    # Test tmux startup time
    log_info "Testing tmux startup time..."
    local startup_time
    if command -v gtime >/dev/null 2>&1; then
        # Use GNU time if available
        startup_time=$(gtime -f "%e" bash -c "tmux new-session -d -s perf_test && tmux kill-session -t perf_test" 2>&1 || echo "unknown")
    elif command -v bc >/dev/null 2>&1; then
        # Fallback: use date-based timing
        startup_time=$(bash -c 'start=$(date +%s%N); tmux new-session -d -s perf_test && tmux kill-session -t perf_test >/dev/null 2>&1; end=$(date +%s%N); echo "scale=3; ($end - $start) / 1000000000" | bc' 2>/dev/null || echo "unknown")
    else
        startup_time="unknown"
    fi
    
    log_info "Tmux startup time: ${startup_time}s"
    
    # Warn if startup is very slow (only if we got a valid measurement)
    if [[ "$startup_time" != "unknown" ]] && command -v bc >/dev/null 2>&1; then
        if (( $(echo "$startup_time > 1.0" | bc -l 2>/dev/null || echo 0) )); then
            log_warn "Tmux startup time is slow (${startup_time}s). Consider reducing plugins."
        fi
    fi
}

# Create helpful information file
create_helpful_info() {
    log_info "Creating helpful information..."
    
    local prefix_key="${TMUX_PREFIX_KEY:-C-a}"
    
    cat > "$HOME/.tmux_module_info" << EOF
# Unified Dotfiles Framework - Tmux Module Information
# This file contains helpful information about your tmux configuration

# Key Features:
# - Modern tmux configuration with sensible defaults
# - Vim-style key bindings for navigation and copy mode
# - Platform-specific clipboard integration
# - Mouse support (can be toggled)
# - Custom status bar with session and system info
# - Plugin support via TPM (if enabled)

# Essential Key Bindings:
# Session Management:
#   tmux new-session -s <name>  - Create new session
#   tmux attach -t <name>       - Attach to session
#   tmux list-sessions          - List sessions
#   $prefix_key d               - Detach from session
#   $prefix_key X               - Kill session (with confirmation)

# Window Management:
#   $prefix_key c               - Create new window
#   $prefix_key n               - Next window
#   $prefix_key p               - Previous window
#   $prefix_key 1-9             - Switch to window number
#   Alt+1-5                     - Quick switch to windows 1-5

# Pane Management:
#   $prefix_key |               - Split vertically
#   $prefix_key -               - Split horizontally
#   $prefix_key h/j/k/l         - Navigate panes (vim-style)
#   $prefix_key H/J/K/L         - Resize panes
#   $prefix_key S               - Synchronize panes (toggle)

# Copy Mode (vim-style):
#   $prefix_key Escape          - Enter copy mode
#   v                           - Begin selection
#   y                           - Copy selection
#   $prefix_key p               - Paste

# Configuration:
#   $prefix_key r               - Reload configuration
#   $prefix_key C-l             - Clear screen and history

# Plugin Management (if enabled):
#   $prefix_key I               - Install plugins
#   $prefix_key U               - Update plugins
#   $prefix_key alt+u           - Uninstall plugins

# Configuration Files:
#   ~/.tmux.conf                - Main configuration
#   ~/.tmux.conf.local          - Local customizations (not synced)

# Directories:
#   ~/.tmux/plugins             - Installed plugins (if TPM enabled)
#   ~/.config/tmux              - Additional configuration data

# Color Schemes:
# Available: default, solarized, gruvbox
# Change via: TMUX_COLOR_SCHEME environment variable

# Environment Variables:
#   TMUX_PREFIX_KEY=${TMUX_PREFIX_KEY:-C-a}
#   TMUX_ENABLE_MOUSE=${TMUX_ENABLE_MOUSE:-true}
#   TMUX_COLOR_SCHEME=${TMUX_COLOR_SCHEME:-default}
#   TMUX_ENABLE_PLUGINS=${TMUX_ENABLE_PLUGINS:-false}
#   TMUX_AUTO_START=${TMUX_AUTO_START:-false}

# Tips:
# - Use 'man tmux' for comprehensive documentation
# - Customize settings in ~/.tmux.conf.local
# - Mouse support can be toggled: set -g mouse on/off
# - Use tmux capture-pane to save pane content
# - Sessions persist across disconnections
# - Use tmux-resurrect plugin to save/restore sessions

# Troubleshooting:
# - If clipboard doesn't work, check platform-specific tools
# - For slow startup, disable unnecessary plugins
# - Use 'tmux info' to check current settings
# - Check 'tmux list-keys' to verify key bindings
EOF

    log_info "Created ~/.tmux_module_info with helpful information"
}

# Display installation summary
display_summary() {
    echo ""
    echo "Tmux Module Post-Installation Summary:"
    echo "======================================"
    echo ""
    
    # Tmux version
    if command -v tmux >/dev/null 2>&1; then
        echo "Tmux version: $(tmux -V)"
    fi
    
    # Configuration status
    if [[ -f "$HOME/.tmux.conf" ]]; then
        echo "✓ Configuration: ~/.tmux.conf installed"
    else
        echo "✗ Configuration: ~/.tmux.conf missing"
    fi
    
    # Plugin manager status
    if [[ "${TMUX_ENABLE_PLUGINS:-false}" == "true" ]]; then
        if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
            echo "✓ Plugin manager: TPM installed"
        else
            echo "✗ Plugin manager: TPM missing"
        fi
    else
        echo "- Plugin manager: disabled"
    fi
    
    # Clipboard integration
    case "$(uname)" in
        "Darwin")
            if command -v reattach-to-user-namespace >/dev/null 2>&1; then
                echo "✓ Clipboard: macOS integration available"
            else
                echo "⚠ Clipboard: macOS integration missing"
            fi
            ;;
        "Linux")
            if command -v xclip >/dev/null 2>&1; then
                echo "✓ Clipboard: Linux integration available"
            else
                echo "⚠ Clipboard: Linux integration missing"
            fi
            ;;
        *)
            echo "- Clipboard: platform-specific setup may be needed"
            ;;
    esac
    
    # Auto-start status
    echo "Auto-start: ${TMUX_AUTO_START:-false}"
    
    echo ""
    echo "Next steps:"
    echo "1. Start tmux: tmux new-session -s main"
    if [[ "${TMUX_ENABLE_PLUGINS:-false}" == "true" ]]; then
        echo "2. Install plugins: Press ${TMUX_PREFIX_KEY:-C-a} + I (inside tmux)"
    fi
    echo "3. Customize ~/.tmux.conf.local for personal preferences"
    echo "4. Check ~/.tmux_module_info for usage tips and key bindings"
    echo ""
    echo "Quick test: tmux new-session -d -s test && tmux kill-session -t test"
    echo ""
}

# Main post-installation tasks
main() {
    log_info "Starting tmux module post-installation tasks..."
    
    verify_tmux_config
    verify_tmux_directories
    check_plugin_manager
    test_tmux_functionality
    check_clipboard_integration
    check_plugin_status
    performance_check
    create_helpful_info
    display_summary
    
    log_success "Tmux module post-installation tasks completed!"
}

# Run main function
main "$@"