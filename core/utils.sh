#!/bin/bash

# Unified Dotfiles Framework - Utility Functions
# Common utility functions used across the framework

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running on macOS
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

# Check if running on Linux
is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

# Check if running on WSL
is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ "$(uname -r)" == *microsoft* ]]
}

# Get the current platform
get_platform() {
    if is_macos; then
        echo "macos"
    elif is_wsl; then
        echo "wsl"
    elif is_linux; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            echo "${ID:-linux}"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

# Confirm user action
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="$message (Y/n): "
    else
        prompt="$message (y/N): "
    fi
    
    read -r -p "$prompt" response
    
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        [nN][oO]|[nN])
            return 1
            ;;
        "")
            [[ "$default" == "y" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# Create backup of a file
backup_file() {
    local file="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"
    
    if [[ -f "$file" ]]; then
        cp "$file" "${file}${backup_suffix}"
        log_debug "Created backup: ${file}${backup_suffix}"
        return 0
    fi
    
    return 1
}

# Create symbolic link with backup
create_symlink() {
    local source="$1"
    local target="$2"
    local backup="${3:-true}"
    
    # Expand tilde in target path
    target="${target/#\~/$HOME}"
    
    # Create target directory if it doesn't exist
    local target_dir
    target_dir="$(dirname "$target")"
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi
    
    # Backup existing file if requested
    if [[ "$backup" == "true" && -e "$target" && ! -L "$target" ]]; then
        backup_file "$target"
    fi
    
    # Remove existing symlink or file
    if [[ -L "$target" || -f "$target" ]]; then
        rm "$target"
    fi
    
    # Create symlink
    ln -s "$source" "$target"
    log_debug "Created symlink: $target -> $source"
}

# Copy file with backup
copy_file() {
    local source="$1"
    local target="$2"
    local backup="${3:-true}"
    
    # Expand tilde in target path
    target="${target/#\~/$HOME}"
    
    # Create target directory if it doesn't exist
    local target_dir
    target_dir="$(dirname "$target")"
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi
    
    # Backup existing file if requested
    if [[ "$backup" == "true" && -f "$target" ]]; then
        backup_file "$target"
    fi
    
    # Copy file
    cp "$source" "$target"
    log_debug "Copied file: $source -> $target"
}

# Download file with retry
download_file() {
    local url="$1"
    local output="$2"
    local max_retries="${3:-3}"
    
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        if command_exists curl; then
            if curl -fsSL "$url" -o "$output"; then
                return 0
            fi
        elif command_exists wget; then
            if wget -q "$url" -O "$output"; then
                return 0
            fi
        else
            log_error "Neither curl nor wget is available for downloading"
            return 1
        fi
        
        ((retry_count++))
        log_warn "Download failed, retrying... ($retry_count/$max_retries)"
        sleep 2
    done
    
    log_error "Failed to download $url after $max_retries attempts"
    return 1
}

# Check if directory is empty
is_directory_empty() {
    local dir="$1"
    [[ -d "$dir" && -z "$(ls -A "$dir")" ]]
}

# Preserve git user configuration
preserve_git_config() {
    local config_file="${1:-$HOME/.git_user_backup}"
    
    if command -v git >/dev/null 2>&1; then
        local git_name git_email
        git_name=$(git config --global user.name 2>/dev/null || echo "")
        git_email=$(git config --global user.email 2>/dev/null || echo "")
        
        if [[ -n "$git_name" && -n "$git_email" ]]; then
            echo "GIT_USER_NAME=\"$git_name\"" > "$config_file"
            echo "GIT_USER_EMAIL=\"$git_email\"" >> "$config_file"
            log_debug "Preserved git user configuration to $config_file"
            return 0
        fi
    fi
    
    return 1
}

# Restore git user configuration
restore_git_config() {
    local config_file="${1:-$HOME/.git_user_backup}"
    
    if [[ -f "$config_file" ]] && command -v git >/dev/null 2>&1; then
        source "$config_file"
        
        if [[ -n "${GIT_USER_NAME:-}" && -n "${GIT_USER_EMAIL:-}" ]]; then
            git config --global user.name "$GIT_USER_NAME"
            git config --global user.email "$GIT_USER_EMAIL"
            log_debug "Restored git user configuration from $config_file"
            rm -f "$config_file"  # Clean up backup file
            return 0
        fi
    fi
    
    return 1
}

# Get file modification time
get_file_mtime() {
    local file="$1"
    
    if is_macos; then
        stat -f "%m" "$file" 2>/dev/null
    else
        stat -c "%Y" "$file" 2>/dev/null
    fi
}

# Check if file is newer than another
is_file_newer() {
    local file1="$1"
    local file2="$2"
    
    local mtime1 mtime2
    mtime1=$(get_file_mtime "$file1")
    mtime2=$(get_file_mtime "$file2")
    
    [[ -n "$mtime1" && -n "$mtime2" && "$mtime1" -gt "$mtime2" ]]
}

# Generate random string
generate_random_string() {
    local length="${1:-8}"
    
    if command_exists openssl; then
        openssl rand -hex "$((length / 2))" | cut -c1-"$length"
    elif [[ -c /dev/urandom ]]; then
        LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
    else
        # Fallback using date and process ID
        echo "${RANDOM}$(date +%s)$$" | md5sum | cut -c1-"$length"
    fi
}

# Join array elements with delimiter
join_array() {
    local delimiter="$1"
    shift
    local first="$1"
    shift
    printf "%s" "$first" "${@/#/$delimiter}"
}

# Check if array contains element
array_contains() {
    local element="$1"
    shift
    local array=("$@")
    
    for item in "${array[@]}"; do
        [[ "$item" == "$element" ]] && return 0
    done
    
    return 1
}

# Remove duplicates from array
remove_duplicates() {
    local -A seen
    local result=()
    
    for item in "$@"; do
        if [[ -z "${seen[$item]:-}" ]]; then
            seen["$item"]=1
            result+=("$item")
        fi
    done
    
    printf "%s\n" "${result[@]}"
}

# Validate email address
is_valid_email() {
    local email="$1"
    [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

# Validate URL
is_valid_url() {
    local url="$1"
    [[ "$url" =~ ^https?://[A-Za-z0-9.-]+\.[A-Za-z]{2,}(/.*)?$ ]]
}

# Get script directory
get_script_dir() {
    local script_path="${BASH_SOURCE[1]}"
    cd "$(dirname "$script_path")" && pwd
}

# Cleanup function for trap
cleanup_on_exit() {
    local exit_code=$?
    
    # Remove temporary files if TEMP_FILES array is set
    if [[ -n "${TEMP_FILES:-}" ]]; then
        for temp_file in "${TEMP_FILES[@]}"; do
            [[ -f "$temp_file" ]] && rm -f "$temp_file"
        done
    fi
    
    # Remove temporary directories if TEMP_DIRS array is set
    if [[ -n "${TEMP_DIRS:-}" ]]; then
        for temp_dir in "${TEMP_DIRS[@]}"; do
            [[ -d "$temp_dir" ]] && rm -rf "$temp_dir"
        done
    fi
    
    exit $exit_code
}

# Register temporary file for cleanup
register_temp_file() {
    local temp_file="$1"
    TEMP_FILES+=("$temp_file")
}

# Register temporary directory for cleanup
register_temp_dir() {
    local temp_dir="$1"
    TEMP_DIRS+=("$temp_dir")
}

# Initialize cleanup trap
init_cleanup_trap() {
    trap cleanup_on_exit EXIT INT TERM
}

# Progress indicator functions
show_spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local delay=0.1
    local spinstr='|/-\'
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r%s %c" "$message" "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    
    printf "\r%s... Done\n" "$message"
}

# Simple progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"
    local message="${4:-Progress}"
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Clear the line first to avoid artifacts from previous output
    printf "\r\033[K"
    
    printf "%s: [" "$message"
    printf "%*s" "$filled" | tr ' ' '='
    printf "%*s" "$empty" | tr ' ' '-'
    printf "] %d%%" "$percentage"
    
    if [[ $current -eq $total ]]; then
        echo ""  # Final newline when complete
    fi
}

# Clear progress line (call this before printing other output after progress)
clear_progress_line() {
    printf "\r\033[K"
}
# Install missing dependencies automatically
install_dependencies() {
    local dependencies=("$@")
    local installed_any=false
    
    for dep in "${dependencies[@]}"; do
        if ! command_exists "$dep"; then
            log_info "Installing missing dependency: $dep"
            
            case "$(get_platform)" in
                "macos")
                    if command_exists brew; then
                        brew install "$dep" && installed_any=true
                    else
                        log_warn "Homebrew not available, cannot install $dep"
                    fi
                    ;;
                "ubuntu"|"debian")
                    if command_exists apt-get; then
                        sudo apt-get update -qq && sudo apt-get install -y "$dep" && installed_any=true
                    fi
                    ;;
                "centos"|"rhel"|"fedora")
                    if command_exists yum; then
                        sudo yum install -y "$dep" && installed_any=true
                    elif command_exists dnf; then
                        sudo dnf install -y "$dep" && installed_any=true
                    fi
                    ;;
                "arch")
                    if command_exists pacman; then
                        sudo pacman -S --noconfirm "$dep" && installed_any=true
                    fi
                    ;;
                *)
                    log_warn "Cannot install $dep on $(get_platform)"
                    ;;
            esac
        fi
    done
    
    return 0
}

# Check and install module dependencies
ensure_module_dependencies() {
    local module_name="$1"
    
    case "$module_name" in
        "tmux")
            install_dependencies tmux
            if is_macos; then
                install_dependencies reattach-to-user-namespace
            elif is_linux; then
                install_dependencies xclip
            fi
            ;;
        "vim")
            install_dependencies vim curl
            ;;
        "git")
            install_dependencies git
            ;;
        "shell")
            # Shell dependencies are usually already available
            ;;
        "developer-tools")
            install_dependencies curl wget git
            ;;
    esac
}