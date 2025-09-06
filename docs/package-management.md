# Package Management Integration

The Unified Dotfiles Framework includes a comprehensive package management abstraction layer that provides cross-platform package installation, management, and integration capabilities.

## Overview

The package management system provides:

- **Cross-platform compatibility**: Works on macOS, Ubuntu, WSL, and Amazon Linux 2
- **Automatic package manager detection**: Detects and uses the appropriate package manager for each platform
- **Package manager auto-installation**: Automatically installs Homebrew on macOS if not present
- **Module integration**: Seamlessly integrates with the module system for declarative package management
- **Caching**: Improves performance through intelligent caching of package manager information
- **WSL support**: Special handling for Windows Subsystem for Linux environments

## Supported Platforms and Package Managers

| Platform | Package Manager | Auto-Install | Notes |
|----------|----------------|--------------|-------|
| macOS | Homebrew (`brew`) | ✅ Yes | Installs Homebrew automatically if not present |
| Ubuntu | APT (`apt`) | ❌ No | Pre-installed on Ubuntu systems |
| WSL | Varies by distro | ❌ No | Detects underlying Linux distribution |
| Amazon Linux 2 | YUM/DNF (`yum`/`dnf`) | ❌ No | Pre-installed on Amazon Linux |

## Core Functions

### Platform Detection

```bash
# Detect current platform
platform=$(detect_platform)
echo "Platform: $platform"  # Output: macos, ubuntu, wsl, amazon-linux, or unsupported

# Get package manager for platform
pkg_mgr=$(get_package_manager)
echo "Package Manager: $pkg_mgr"  # Output: brew, apt, yum, dnf, or unknown
```

### Package Manager Validation

```bash
# Check if package manager is available
if is_package_manager_available; then
    echo "Package manager is ready"
else
    echo "Package manager needs installation"
fi

# Validate and install package manager if needed
if validate_package_manager; then
    echo "Package manager is ready for use"
fi
```

### Package Operations

```bash
# Check if a package is installed
if is_package_installed "git"; then
    echo "Git is installed"
fi

# Install a single package
install_single_package "curl"

# Install multiple packages
install_packages "git" "vim" "tmux"

# Remove a package
remove_package "old-package"

# Search for packages
search_packages "text-editor"

# Get package information
get_package_info "git"

# Upgrade all packages
upgrade_packages
```

### Repository Management

```bash
# Update package repositories
update_package_repositories

# This runs:
# - brew update (macOS)
# - sudo apt-get update (Ubuntu/WSL)
# - sudo yum makecache (Amazon Linux with YUM)
# - sudo dnf makecache (Amazon Linux with DNF)
```

## Module Integration

Modules can declare their package dependencies in their `module.yaml` configuration:

```yaml
name: "git"
description: "Git version control system"
packages:
  macos:
    - git
    - git-lfs
    - git-flow-avh
  ubuntu:
    - git
    - git-lfs
    - git-flow
  wsl:
    - git
    - git-lfs
    - git-flow
  amazon-linux:
    - git
    - git-lfs
```

### Installing Module Packages

```bash
# Install packages defined in a module configuration
install_module_packages "/path/to/module.yaml"
```

The function automatically:
1. Detects the current platform
2. Extracts packages for that platform from the YAML configuration
3. Validates the package manager is available
4. Installs all packages using the appropriate package manager

## WSL Support

The system provides special handling for Windows Subsystem for Linux:

```bash
# Detect WSL package manager based on distribution
wsl_pkg_mgr=$(detect_wsl_package_manager)

# Set up WSL-specific package manager configuration
setup_wsl_package_manager
```

Supported WSL distributions:
- Ubuntu/Debian → APT
- Fedora → DNF/YUM
- Arch → Pacman (detection only, not yet implemented)
- openSUSE → Zypper (detection only, not yet implemented)

## Homebrew Auto-Installation

On macOS, if Homebrew is not installed, the system can automatically install it:

```bash
# Install Homebrew if needed
install_homebrew_if_needed

# This will:
# 1. Check if Homebrew is already installed
# 2. Verify Xcode Command Line Tools are installed
# 3. Download and run the official Homebrew installer
# 4. Add Homebrew to PATH for the current session
# 5. Verify the installation was successful
```

## Caching System

The package management system uses caching to improve performance:

```bash
# Cache is automatically managed, but you can control it:

# Clear all package manager cache
clear_pkg_cache

# Set a cached value
set_pkg_cached_value "key" "value"

# Get a cached value
value=$(get_pkg_cached_value "key")
```

Cached information includes:
- Package manager availability status
- Package installation status (short-term)
- Platform detection results
- Package manager capabilities

## Error Handling

The system provides comprehensive error handling:

```bash
# All functions return appropriate exit codes
if install_single_package "nonexistent-package"; then
    echo "Package installed successfully"
else
    echo "Package installation failed"
fi

# Detailed error messages are logged
# Retry mechanisms for network operations
# Graceful fallbacks when package managers are unavailable
```

## Platform-Specific Package Mapping

The system can map generic package names to platform-specific names:

```bash
# Get platform-specific package name
platform_package=$(get_platform_package "vim")

# Examples:
# - "vim" → "vim" (macOS, Ubuntu)
# - "vim" → "vim-enhanced" (Amazon Linux)
```

## Usage Examples

### Basic Package Installation

```bash
#!/bin/bash
source "core/package_manager.sh"

# Ensure package manager is ready
validate_package_manager

# Install development tools
install_packages "git" "vim" "tmux" "curl"
```

### Module Package Installation

```bash
#!/bin/bash
source "core/package_manager.sh"

# Install packages from module configuration
install_module_packages "modules/development/module.yaml"
```

### Platform-Specific Installation

```bash
#!/bin/bash
source "core/package_manager.sh"

platform=$(detect_platform)

case "$platform" in
    "macos")
        install_packages "git" "vim" "tmux"
        ;;
    "ubuntu"|"wsl")
        install_packages "git" "vim" "tmux" "build-essential"
        ;;
    "amazon-linux")
        install_packages "git" "vim-enhanced" "tmux" "gcc"
        ;;
esac
```

## Testing

The package management system includes comprehensive tests:

```bash
# Run dry-run tests (no actual package operations)
./test_package_manager_dry.sh

# Run full integration tests (may install packages)
./test_package_manager.sh

# Test module integration
./test_git_module_packages.sh
```

## Configuration

### Environment Variables

The package management system respects several environment variables:

- `PKG_MGR_CACHE_DIR`: Override cache directory location
- `HOMEBREW_PREFIX`: Override Homebrew installation prefix detection
- `WSL_DISTRO_NAME`: Override WSL distribution detection

### Module Configuration

Modules should define packages in their `module.yaml`:

```yaml
packages:
  macos:
    - package1
    - package2
  ubuntu:
    - package1
    - package2-dev
  wsl:
    - package1
    - package2-dev
  amazon-linux:
    - package1
    - package2-devel
```

## Troubleshooting

### Common Issues

1. **Package manager not found**
   ```bash
   # Solution: Install package manager or check PATH
   validate_package_manager
   ```

2. **Permission denied errors**
   ```bash
   # Solution: Ensure sudo access for Linux package managers
   # Homebrew should not require sudo
   ```

3. **Network connectivity issues**
   ```bash
   # Solution: Check internet connection
   # The system includes retry mechanisms for network operations
   ```

4. **WSL detection issues**
   ```bash
   # Solution: Set WSL_DISTRO_NAME environment variable
   export WSL_DISTRO_NAME="ubuntu"
   ```

### Debug Mode

Enable debug logging for troubleshooting:

```bash
export LOG_LEVEL="debug"
./your_script.sh
```

## API Reference

### Core Functions

- `detect_platform()` - Detect current platform
- `get_package_manager()` - Get package manager for platform
- `is_package_manager_available([pkg_mgr])` - Check if package manager is available
- `install_package_manager()` - Install package manager if possible
- `validate_package_manager()` - Validate and install package manager

### Package Operations

- `is_package_installed(package)` - Check if package is installed
- `install_single_package(package, [force])` - Install single package
- `install_packages(package...)` - Install multiple packages
- `remove_package(package)` - Remove package
- `search_packages(query)` - Search for packages
- `get_package_info(package)` - Get package information
- `upgrade_packages()` - Upgrade all packages

### Repository Management

- `update_package_repositories()` - Update package repositories

### Module Integration

- `install_module_packages(module_config)` - Install packages from module config

### WSL Support

- `detect_wsl_package_manager()` - Detect WSL package manager
- `setup_wsl_package_manager()` - Set up WSL package manager

### Homebrew Support

- `install_homebrew_if_needed()` - Install Homebrew on macOS if needed

### Utility Functions

- `show_package_manager_info()` - Display package manager information
- `get_platform_package(generic_package)` - Get platform-specific package name

### Cache Management

- `clear_pkg_cache()` - Clear package manager cache
- `get_pkg_cached_value(key)` - Get cached value
- `set_pkg_cached_value(key, value)` - Set cached value

## Integration with Other Systems

The package management system integrates seamlessly with:

- **Module System**: Automatic package installation from module configurations
- **Platform Detection**: Uses platform information for package manager selection
- **Logging System**: Comprehensive logging of all operations
- **Backup System**: Can backup package lists before major changes
- **Configuration System**: Respects user configuration overrides

This provides a unified, cross-platform package management experience that works consistently across all supported platforms.