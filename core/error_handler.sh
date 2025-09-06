#!/bin/bash

# Unified Dotfiles Framework - Error Handler
# Provides graceful error handling and user-friendly messages

# Global error handler function
handle_error() {
    local exit_code=$?
    local line_number=$1
    local command="$2"
    
    echo ""
    log_error "An error occurred during installation:"
    log_error "  Exit code: $exit_code"
    log_error "  Line: $line_number"
    log_error "  Command: $command"
    echo ""
    
    log_info "Troubleshooting suggestions:"
    log_info "1. Check if you have proper permissions"
    log_info "2. Ensure all required tools are installed"
    log_info "3. Try running with --verbose for more details"
    log_info "4. Check the logs for more information"
    echo ""
    
    log_info "For help, run: ./install.sh help troubleshooting"
    
    exit $exit_code
}

# Set up error trapping
setup_error_handling() {
    # Only set up if not already done
    if [[ "${ERROR_HANDLING_SETUP:-}" != "true" ]]; then
        trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR
        export ERROR_HANDLING_SETUP="true"
    fi
}

# Graceful warning handler
handle_warning() {
    local message="$1"
    local suggestion="${2:-}"
    
    log_warn "$message"
    if [[ -n "$suggestion" ]]; then
        log_info "Suggestion: $suggestion"
    fi
}

# Check for common issues and provide helpful messages
check_common_issues() {
    # Check for network connectivity
    if ! curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1; then
        handle_warning "Network connectivity issues detected" "Check your internet connection"
    fi
    
    # Check for disk space
    local available_space
    available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [[ "$available_space" -lt 1000000 ]]; then  # Less than ~1GB
        handle_warning "Low disk space detected" "Ensure you have enough free space"
    fi
    
    # Check for required tools
    local required_tools=("git" "curl" "bash")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            handle_warning "$tool is not installed" "Install $tool before continuing"
        fi
    done
}