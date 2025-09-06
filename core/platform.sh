#!/bin/bash

# Unified Dotfiles Framework - Platform Detection and Management
# Handles platform-specific functionality and detection

# Platform detection cache
PLATFORM_CACHE_FILE="${HOME}/.dotfiles/cache/platform_info"
PLATFORM_CACHE_TTL=3600  # 1 hour

# Initialize platform detection system
init_platform_system() {
    local cache_dir
    cache_dir="$(dirname "$PLATFORM_CACHE_FILE")"
    
    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir"
    fi
    
    # Detect platform if not cached or cache is stale
    if ! is_platform_cache_valid; then
        detect_platform_info
        cache_platform_info
    else
        load_cached_platform_info
    fi
}

# Check if platform cache is valid
is_platform_cache_valid() {
    if [[ ! -f "$PLATFORM_CACHE_FILE" ]]; then
        return 1
    fi
    
    local cache_age
    cache_age=$(get_file_mtime "$PLATFORM_CACHE_FILE")
    local current_time
    current_time=$(date +%s)
    
    [[ $((current_time - cache_age)) -lt $PLATFORM_CACHE_TTL ]]
}

# Detect comprehensive platform information
detect_platform_info() {
    log_debug "Detecting platform information..."
    
    # Basic OS detection
    export DETECTED_OS="$(detect_os)"
    export DETECTED_DISTRO="$(detect_distro)"
    export DETECTED_VERSION="$(detect_version)"
    export DETECTED_ARCH="$(detect_architecture)"
    export DETECTED_SHELL="$(detect_shell)"
    export DETECTED_PACKAGE_MANAGER="$(detect_package_manager)"
    
    # Platform capabilities
    export HAS_HOMEBREW="$(has_homebrew)"
    export HAS_APT="$(has_apt)"
    export HAS_YUM="$(has_yum)"
    export HAS_PACMAN="$(has_pacman)"
    export HAS_GIT="$(has_git)"
    export HAS_CURL="$(has_curl)"
    export HAS_WGET="$(has_wget)"
    
    # Environment detection
    export IS_WSL="$(is_wsl_environment)"
    export IS_DOCKER="$(is_docker_environment)"
    export IS_CI="$(is_ci_environment)"
    export IS_SSH="$(is_ssh_session)"
    
    log_debug "Platform detection completed: $DETECTED_OS/$DETECTED_DISTRO"
}

# Detect operating system
detect_os() {
    case "$OSTYPE" in
        darwin*)
            echo "macos"
            ;;
        linux-gnu*)
            echo "linux"
            ;;
        msys*|cygwin*)
            echo "windows"
            ;;
        freebsd*)
            echo "freebsd"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect Linux distribution
detect_distro() {
    if [[ "$DETECTED_OS" != "linux" ]]; then
        echo "n/a"
        return
    fi
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Detect OS version
detect_version() {
    case "$DETECTED_OS" in
        macos)
            sw_vers -productVersion 2>/dev/null || echo "unknown"
            ;;
        linux)
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                echo "${VERSION_ID:-unknown}"
            else
                echo "unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect system architecture
detect_architecture() {
    local arch
    arch="$(uname -m)"
    
    case "$arch" in
        x86_64|amd64)
            echo "x64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        armv7l)
            echo "arm"
            ;;
        i386|i686)
            echo "x86"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# Detect current shell
detect_shell() {
    local shell_name
    shell_name="$(basename "${SHELL:-/bin/bash}")"
    echo "$shell_name"
}

# Detect primary package manager
detect_package_manager() {
    case "$DETECTED_OS" in
        macos)
            if command_exists brew; then
                echo "homebrew"
            else
                echo "none"
            fi
            ;;
        linux)
            if command_exists apt; then
                echo "apt"
            elif command_exists yum; then
                echo "yum"
            elif command_exists dnf; then
                echo "dnf"
            elif command_exists pacman; then
                echo "pacman"
            elif command_exists zypper; then
                echo "zypper"
            else
                echo "unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check for specific tools
has_homebrew() {
    command_exists brew && echo "true" || echo "false"
}

has_apt() {
    command_exists apt && echo "true" || echo "false"
}

has_yum() {
    command_exists yum && echo "true" || echo "false"
}

has_pacman() {
    command_exists pacman && echo "true" || echo "false"
}

has_git() {
    command_exists git && echo "true" || echo "false"
}

has_curl() {
    command_exists curl && echo "true" || echo "false"
}

has_wget() {
    command_exists wget && echo "true" || echo "false"
}

# Environment detection functions
is_wsl_environment() {
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ "$(uname -r)" == *microsoft* ]]; then
        echo "true"
    else
        echo "false"
    fi
}

is_docker_environment() {
    if [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

is_ci_environment() {
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${TRAVIS:-}" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

is_ssh_session() {
    if [[ -n "${SSH_CLIENT:-}" ]] || [[ -n "${SSH_TTY:-}" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Cache platform information
cache_platform_info() {
    cat > "$PLATFORM_CACHE_FILE" << EOF
# Platform detection cache - $(date)
DETECTED_OS="$DETECTED_OS"
DETECTED_DISTRO="$DETECTED_DISTRO"
DETECTED_VERSION="$DETECTED_VERSION"
DETECTED_ARCH="$DETECTED_ARCH"
DETECTED_SHELL="$DETECTED_SHELL"
DETECTED_PACKAGE_MANAGER="$DETECTED_PACKAGE_MANAGER"
HAS_HOMEBREW="$HAS_HOMEBREW"
HAS_APT="$HAS_APT"
HAS_YUM="$HAS_YUM"
HAS_PACMAN="$HAS_PACMAN"
HAS_GIT="$HAS_GIT"
HAS_CURL="$HAS_CURL"
HAS_WGET="$HAS_WGET"
IS_WSL="$IS_WSL"
IS_DOCKER="$IS_DOCKER"
IS_CI="$IS_CI"
IS_SSH="$IS_SSH"
EOF
    
    log_debug "Platform information cached to $PLATFORM_CACHE_FILE"
}

# Load cached platform information
load_cached_platform_info() {
    if [[ -f "$PLATFORM_CACHE_FILE" ]]; then
        source "$PLATFORM_CACHE_FILE"
        log_debug "Loaded cached platform information"
    fi
}

# Clear platform cache
clear_platform_cache() {
    if [[ -f "$PLATFORM_CACHE_FILE" ]]; then
        rm "$PLATFORM_CACHE_FILE"
        log_debug "Platform cache cleared"
    fi
}

# Get platform-specific configuration directory
get_platform_config_dir() {
    local base_dir="$1"
    echo "$base_dir/platforms/$DETECTED_OS"
}

# Check if current platform is supported by module
is_platform_supported() {
    local module_dir="$1"
    local module_config="$module_dir/module.yaml"
    
    if [[ ! -f "$module_config" ]]; then
        log_warn "Module configuration not found: $module_config"
        return 1
    fi
    
    # Simple check for platform support (would need proper YAML parsing in production)
    if grep -q "platforms:" "$module_config"; then
        if grep -A 10 "platforms:" "$module_config" | grep -q -- "- $DETECTED_OS"; then
            return 0
        else
            return 1
        fi
    fi
    
    # If no platforms specified, assume supported
    return 0
}

# Install platform-specific system preferences
install_platform_preferences() {
    local dry_run="${1:-false}"
    
    log_info "Applying platform-specific preferences for $DETECTED_OS..."
    
    case "$DETECTED_OS" in
        macos)
            install_macos_preferences "$dry_run"
            ;;
        linux)
            install_linux_preferences "$dry_run"
            ;;
        *)
            log_debug "No platform-specific preferences for $DETECTED_OS"
            ;;
    esac
}

# Install macOS-specific preferences
install_macos_preferences() {
    local dry_run="$1"
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "Would apply macOS system preferences"
        return 0
    fi
    
    log_debug "Applying macOS system preferences..."
    
    # Example macOS preferences (customize as needed)
    # Show hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true 2>/dev/null || true
    
    # Show file extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true 2>/dev/null || true
    
    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false 2>/dev/null || true
    
    log_debug "macOS preferences applied"
}

# Install Linux-specific preferences
install_linux_preferences() {
    local dry_run="$1"
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "Would apply Linux system preferences"
        return 0
    fi
    
    log_debug "Applying Linux system preferences..."
    
    # Example Linux preferences (customize as needed)
    # Set up common aliases in bashrc if not already present
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# Dotfiles framework aliases" "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# Dotfiles framework aliases" >> "$bashrc"
        echo "alias ll='ls -alF'" >> "$bashrc"
        echo "alias la='ls -A'" >> "$bashrc"
        echo "alias l='ls -CF'" >> "$bashrc"
    fi
    
    log_debug "Linux preferences applied"
}

# Show platform information
show_platform_info() {
    echo "Platform Information:"
    echo "  OS: $DETECTED_OS"
    echo "  Distribution: $DETECTED_DISTRO"
    echo "  Version: $DETECTED_VERSION"
    echo "  Architecture: $DETECTED_ARCH"
    echo "  Shell: $DETECTED_SHELL"
    echo "  Package Manager: $DETECTED_PACKAGE_MANAGER"
    echo ""
    echo "Environment:"
    echo "  WSL: $IS_WSL"
    echo "  Docker: $IS_DOCKER"
    echo "  CI: $IS_CI"
    echo "  SSH: $IS_SSH"
    echo ""
    echo "Available Tools:"
    echo "  Homebrew: $HAS_HOMEBREW"
    echo "  APT: $HAS_APT"
    echo "  YUM: $HAS_YUM"
    echo "  Pacman: $HAS_PACMAN"
    echo "  Git: $HAS_GIT"
    echo "  cURL: $HAS_CURL"
    echo "  wget: $HAS_WGET"
}