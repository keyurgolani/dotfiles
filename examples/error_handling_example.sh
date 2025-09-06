#!/bin/bash

# Example: Using the Comprehensive Error Handling System
# This example demonstrates how to integrate the error handling system
# into a typical dotfiles installation script

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$SCRIPT_DIR")/core"

# Source the error handling system
source "$CORE_DIR/logger.sh"
source "$CORE_DIR/error_handler.sh"
source "$CORE_DIR/utils.sh"

# Configuration
INTERACTIVE_MODE="${INTERACTIVE_MODE:-true}"
LOG_FILE="${LOG_FILE:-/tmp/dotfiles_example.log}"

# Example: Module installation with error handling
install_git_module() {
    # Set error context for better error reporting
    set_error_context "git_module" "install_git_config" "$HOME/.gitconfig"
    push_error_stack "install_git_module"
    
    log_info "Installing Git module..."
    
    # Example: Download git configuration with retry and checksum verification
    local git_config_url="https://raw.githubusercontent.com/user/dotfiles/main/gitconfig"
    local temp_config
    temp_config=$(create_temp_file "gitconfig" "tmp")
    register_temp_file "$temp_config"
    
    # Download with automatic retry on network errors
    if download_file "$git_config_url" "$temp_config" 3; then
        log_success "Git configuration downloaded successfully"
        
        # Safe file operation with backup
        if safe_file_operation "copy" "$temp_config" "$HOME/.gitconfig" true; then
            log_success "Git configuration installed successfully"
        else
            log_error "Failed to install git configuration"
            pop_error_stack
            return $ERROR_GENERAL
        fi
    else
        log_error "Failed to download git configuration"
        pop_error_stack
        return $ERROR_NETWORK
    fi
    
    pop_error_stack
    return $ERROR_SUCCESS
}

# Example: Package installation with error handling
install_system_packages() {
    set_error_context "package_installation" "install_packages"
    push_error_stack "install_system_packages"
    
    local packages=("git" "curl" "vim" "tmux")
    
    log_info "Installing system packages: ${packages[*]}"
    
    # Safe command execution with retry
    if safe_execute "brew install ${packages[*]}" "install packages via homebrew" 2 5; then
        log_success "System packages installed successfully"
    else
        log_error "Failed to install system packages"
        
        # Attempt recovery
        if [[ "$ERROR_INTERACTIVE_RECOVERY" == "true" ]]; then
            if confirm "Package installation failed. Try with sudo?" "n"; then
                if safe_execute "sudo apt-get install -y ${packages[*]}" "install packages via apt" 2 5; then
                    log_success "System packages installed successfully with apt"
                else
                    log_error "Package installation failed with both brew and apt"
                    pop_error_stack
                    return $ERROR_DEPENDENCY
                fi
            fi
        fi
    fi
    
    pop_error_stack
    return $ERROR_SUCCESS
}

# Example: Symlink creation with error handling
create_dotfile_symlinks() {
    set_error_context "symlink_creation" "create_symlinks"
    push_error_stack "create_dotfile_symlinks"
    
    local dotfiles_dir="$HOME/.dotfiles"
    local symlinks=(
        "$dotfiles_dir/vimrc:$HOME/.vimrc"
        "$dotfiles_dir/tmux.conf:$HOME/.tmux.conf"
        "$dotfiles_dir/zshrc:$HOME/.zshrc"
    )
    
    log_info "Creating dotfile symlinks..."
    
    local link_spec
    for link_spec in "${symlinks[@]}"; do
        local source="${link_spec%:*}"
        local target="${link_spec#*:}"
        
        if safe_symlink "$source" "$target" true; then
            log_debug "Created symlink: $source -> $target"
        else
            log_error "Failed to create symlink: $source -> $target"
            pop_error_stack
            return $ERROR_GENERAL
        fi
    done
    
    log_success "All dotfile symlinks created successfully"
    pop_error_stack
    return $ERROR_SUCCESS
}

# Example: Cleanup function
cleanup_installation() {
    log_debug "Performing installation cleanup..."
    
    # Remove any temporary files
    if [[ -d "/tmp/dotfiles_temp" ]]; then
        rm -rf "/tmp/dotfiles_temp"
    fi
    
    # Reset any temporary environment variables
    unset TEMP_INSTALL_DIR
}

# Main installation function
main() {
    echo "Dotfiles Installation with Error Handling Example"
    echo "================================================"
    
    # Initialize error handling system
    setup_logging true
    init_error_handling
    
    # Register cleanup function
    register_cleanup cleanup_installation
    
    # Validate system requirements first
    if ! validate_system_requirements; then
        log_error "System requirements not met"
        exit $ERROR_DEPENDENCY
    fi
    
    # Install components with error handling
    local components=(
        "install_system_packages"
        "install_git_module"
        "create_dotfile_symlinks"
    )
    
    local component
    for component in "${components[@]}"; do
        log_step "Running: $component"
        
        if "$component"; then
            log_success "Completed: $component"
        else
            local exit_code=$?
            log_error "Failed: $component (exit code: $exit_code)"
            
            # Create error report for debugging
            local error_report
            error_report=$(create_error_report)
            log_error "Error report created: $error_report"
            
            # Exit with the specific error code
            exit $exit_code
        fi
    done
    
    log_success "Installation completed successfully!"
    echo ""
    echo "🎉 All components installed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your shell or run: source ~/.zshrc"
    echo "  2. Verify git configuration: git config --list"
    echo "  3. Check vim configuration: vim --version"
    
    return $ERROR_SUCCESS
}

# Example: Error simulation for testing
simulate_error() {
    local error_type="${1:-network}"
    
    set_error_context "error_simulation" "simulate_$error_type"
    push_error_stack "simulate_error: $error_type"
    
    case "$error_type" in
        "network")
            log_info "Simulating network error..."
            download_file "https://invalid.domain/file.txt" "/tmp/test_file.txt" 1
            ;;
        "permission")
            log_info "Simulating permission error..."
            safe_file_operation "copy" "/etc/passwd" "/root/test_file" false
            ;;
        "disk_space")
            log_info "Simulating disk space error..."
            # This would normally check disk space and fail
            log_error "Insufficient disk space"
            pop_error_stack
            return $ERROR_DISK_SPACE
            ;;
        *)
            log_error "Unknown error type: $error_type"
            pop_error_stack
            return $ERROR_MISUSE
            ;;
    esac
    
    pop_error_stack
}

# Handle command line arguments
case "${1:-main}" in
    "main")
        main
        ;;
    "simulate")
        setup_logging true
        init_error_handling
        simulate_error "${2:-network}"
        ;;
    "test")
        setup_logging true
        init_error_handling
        
        echo "Testing error handling components..."
        
        # Test error context
        set_error_context "test" "example_test" "test_file.txt"
        log_info "Error context set: $ERROR_CONTEXT / $ERROR_OPERATION / $ERROR_FILE"
        
        # Test safe operations
        echo "test content" > /tmp/test_source.txt
        safe_file_operation "copy" "/tmp/test_source.txt" "/tmp/test_target.txt"
        
        # Test error report
        error_report=$(create_error_report)
        echo "Error report created: $error_report"
        
        echo "✓ Error handling test completed"
        ;;
    *)
        echo "Usage: $0 [main|simulate [network|permission|disk_space]|test]"
        echo ""
        echo "Commands:"
        echo "  main      - Run the main installation (default)"
        echo "  simulate  - Simulate different types of errors"
        echo "  test      - Test error handling components"
        exit $ERROR_MISUSE
        ;;
esac