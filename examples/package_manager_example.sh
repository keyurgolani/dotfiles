#!/bin/bash

# Example script demonstrating package management integration usage
# Shows how to use the cross-platform package manager abstraction layer

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source required modules
source "$SCRIPT_DIR/core/logger.sh"
source "$SCRIPT_DIR/core/utils.sh"
source "$SCRIPT_DIR/core/platform.sh"
source "$SCRIPT_DIR/core/package_manager.sh"

# Example: Basic platform and package manager detection
example_basic_detection() {
    log_section "Basic Platform and Package Manager Detection"
    
    echo "Detecting current platform..."
    local platform
    platform=$(detect_platform)
    echo "Platform: $platform"
    
    echo "Detecting package manager..."
    local pkg_mgr
    pkg_mgr=$(get_package_manager)
    echo "Package Manager: $pkg_mgr"
    
    echo "Checking if package manager is available..."
    if is_package_manager_available "$pkg_mgr"; then
        echo "✓ Package manager is available"
    else
        echo "✗ Package manager is not available"
    fi
    
    echo ""
}

# Example: Package installation check
example_package_check() {
    log_section "Package Installation Check"
    
    local test_packages=("git" "curl" "nonexistent-package-12345")
    
    for package in "${test_packages[@]}"; do
        echo "Checking if $package is installed..."
        if is_package_installed "$package"; then
            echo "✓ $package is installed"
        else
            echo "✗ $package is not installed"
        fi
    done
    
    echo ""
}

# Example: Platform-specific package mapping
example_package_mapping() {
    log_section "Platform-Specific Package Mapping"
    
    local generic_packages=("git" "vim" "tmux" "curl")
    local platform
    platform=$(detect_platform)
    
    echo "Platform: $platform"
    echo "Package mappings:"
    
    for package in "${generic_packages[@]}"; do
        local mapped_package
        mapped_package=$(get_platform_package "$package")
        echo "  $package -> $mapped_package"
    done
    
    echo ""
}

# Example: WSL detection (if applicable)
example_wsl_detection() {
    log_section "WSL Detection"
    
    local platform
    platform=$(detect_platform)
    
    if [[ "$platform" == "$PLATFORM_WSL" ]]; then
        echo "Running on WSL"
        echo "WSL Distribution: ${WSL_DISTRO_NAME:-unknown}"
        
        local wsl_pkg_mgr
        wsl_pkg_mgr=$(detect_wsl_package_manager)
        echo "WSL Package Manager: $wsl_pkg_mgr"
    else
        echo "Not running on WSL"
        echo "Testing WSL detection function anyway..."
        
        local wsl_pkg_mgr
        wsl_pkg_mgr=$(detect_wsl_package_manager)
        echo "WSL detection result: $wsl_pkg_mgr"
    fi
    
    echo ""
}

# Example: Module package installation (dry run)
example_module_packages() {
    log_section "Module Package Installation Example"
    
    # Create a temporary example module configuration
    local temp_config
    temp_config=$(create_temp_file "example_module" "yaml")
    
    local platform
    platform=$(detect_platform)
    
    cat > "$temp_config" << EOF
name: "example-module"
description: "Example module for demonstration"
packages:
  macos:
    - git
    - curl
    - vim
  ubuntu:
    - git
    - curl
    - vim
  wsl:
    - git
    - curl
    - vim
  amazon-linux:
    - git
    - curl
    - vim-enhanced
EOF
    
    echo "Example module configuration:"
    cat "$temp_config"
    echo ""
    
    echo "This would install the following packages for platform '$platform':"
    
    # Parse the packages (using the same logic as install_module_packages)
    local packages=()
    local in_platform_section=false
    
    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        
        if [[ "$line" == "packages:" ]]; then
            continue
        fi
        
        if [[ "$line" == "$platform:" ]]; then
            in_platform_section=true
            continue
        fi
        
        if [[ "$line" =~ ^[a-z-]+:$ ]] && [[ "$in_platform_section" == "true" ]]; then
            break
        fi
        
        if [[ "$in_platform_section" == "true" ]] && [[ "$line" =~ ^-[[:space:]]+ ]]; then
            local package
            package=$(echo "$line" | sed 's/^-[[:space:]]*//')
            packages+=("$package")
        fi
    done < "$temp_config"
    
    if [[ ${#packages[@]} -gt 0 ]]; then
        echo "Packages: ${packages[*]}"
    else
        echo "No packages defined for platform $platform"
    fi
    
    cleanup_temp "$temp_config"
    echo ""
}

# Example: Package manager validation
example_validation() {
    log_section "Package Manager Validation"
    
    echo "Validating package manager setup..."
    if validate_package_manager; then
        echo "✓ Package manager validation passed"
    else
        echo "✗ Package manager validation failed"
    fi
    
    echo ""
}

# Example: Cache functionality
example_cache() {
    log_section "Cache Functionality"
    
    echo "Testing cache functionality..."
    
    # Clear cache
    clear_pkg_cache
    echo "Cache cleared"
    
    # Set some test values
    set_pkg_cached_value "example_key1" "example_value1"
    set_pkg_cached_value "example_key2" "example_value2"
    echo "Set cache values"
    
    # Retrieve values
    local value1
    value1=$(get_pkg_cached_value "example_key1")
    local value2
    value2=$(get_pkg_cached_value "example_key2")
    
    echo "Retrieved values:"
    echo "  example_key1: $value1"
    echo "  example_key2: $value2"
    
    # Clean up
    clear_pkg_cache
    echo "Cache cleared"
    
    echo ""
}

# Example: Homebrew installation (macOS only)
example_homebrew() {
    log_section "Homebrew Installation Example"
    
    local platform
    platform=$(detect_platform)
    
    if [[ "$platform" == "$PLATFORM_MACOS" ]]; then
        echo "Running on macOS - checking Homebrew installation"
        
        if is_package_manager_available "$PKG_MGR_BREW"; then
            echo "✓ Homebrew is already installed"
            echo "Version: $(brew --version | head -n1)"
            echo "Prefix: $(brew --prefix)"
        else
            echo "✗ Homebrew is not installed"
            echo "To install Homebrew, you would run: install_homebrew_if_needed"
            echo "(This example doesn't actually install it)"
        fi
    else
        echo "Not running on macOS - Homebrew installation not applicable"
    fi
    
    echo ""
}

# Main example execution
main() {
    log_section "Package Manager Integration Examples"
    
    echo "This script demonstrates the package management integration functionality"
    echo "without actually installing or modifying packages."
    echo ""
    
    # Run examples
    example_basic_detection
    example_package_check
    example_package_mapping
    example_wsl_detection
    example_module_packages
    example_validation
    example_cache
    example_homebrew
    
    log_section "Summary"
    echo "Package management integration provides:"
    echo "• Cross-platform package manager detection and abstraction"
    echo "• Automatic package manager installation (Homebrew on macOS)"
    echo "• Package installation, removal, and status checking"
    echo "• WSL-specific package manager detection"
    echo "• Module-based package installation from YAML configuration"
    echo "• Caching for improved performance"
    echo "• Platform-specific package name mapping"
    echo ""
    echo "All functionality is available through the unified API regardless of platform."
}

# Run examples if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi