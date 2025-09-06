#!/bin/bash

# Fix Dotfiles Paths Script
# This script updates shell configuration files to use the correct dotfiles directory path

set -euo pipefail

# Source core utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/core"

if [[ -f "$CORE_DIR/logger.sh" ]]; then
    source "$CORE_DIR/logger.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*"; }
fi

# Get the actual dotfiles directory
ACTUAL_DOTFILES_DIR="${DOTFILES_ROOT:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

log_info "Fixing dotfiles paths in shell configurations..."
log_info "Using dotfiles directory: $ACTUAL_DOTFILES_DIR"

# Function to update paths in a file
update_paths_in_file() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        log_warn "$description not found: $file"
        return 0
    fi
    
    log_info "Updating paths in $description: $file"
    
    # Create a backup
    cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Update the paths using sed
    # Replace ~/dotfiles with the actual dotfiles directory
    sed -i.tmp "s|~/dotfiles|$ACTUAL_DOTFILES_DIR|g" "$file" 2>/dev/null || {
        # Fallback for systems where sed -i behaves differently
        sed "s|~/dotfiles|$ACTUAL_DOTFILES_DIR|g" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    }
    
    # Clean up temporary file if it exists
    [[ -f "$file.tmp" ]] && rm -f "$file.tmp"
    
    log_success "Updated paths in $description"
}

# Function to add dotfiles directory detection to shell configs
add_dotfiles_detection() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        log_warn "$description not found: $file"
        return 0
    fi
    
    # Check if detection is already added
    if grep -q "DOTFILES_DIR" "$file" 2>/dev/null; then
        log_info "$description already has dotfiles detection"
        return 0
    fi
    
    log_info "Adding dotfiles detection to $description: $file"
    
    # Create a backup
    cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Add detection at the beginning of the file (after shebang if present)
    local temp_file="$file.dotfiles_detection.tmp"
    
    {
        # Copy shebang if present
        if head -1 "$file" | grep -q "^#!"; then
            head -1 "$file"
            echo ""
        fi
        
        # Add dotfiles detection
        cat << 'EOF'
# Dotfiles directory detection (auto-generated)
if [[ -z "${DOTFILES_DIR:-}" ]]; then
    # Try to detect dotfiles directory
    if [[ -n "${DOTFILES_ROOT:-}" ]] && [[ -d "$DOTFILES_ROOT" ]]; then
        export DOTFILES_DIR="$DOTFILES_ROOT"
    elif [[ -f "$HOME/.dotfiles-root" ]]; then
        export DOTFILES_DIR="$(cat "$HOME/.dotfiles-root" 2>/dev/null || echo "$HOME/dotfiles")"
    else
        export DOTFILES_DIR="$HOME/dotfiles"
    fi
fi

EOF
        
        # Copy the rest of the file (skip shebang if we already copied it)
        if head -1 "$file" | grep -q "^#!"; then
            tail -n +2 "$file"
        else
            cat "$file"
        fi
        
    } > "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$file"
    
    log_success "Added dotfiles detection to $description"
}

# Main function
main() {
    log_info "Starting dotfiles path fixes..."
    
    # Update shell configuration files
    local shell_configs=(
        "$HOME/.zshrc:ZSH configuration"
        "$HOME/.bashrc:Bash configuration"
        "$HOME/.bash_profile:Bash profile"
    )
    
    for config_info in "${shell_configs[@]}"; do
        local file="${config_info%:*}"
        local description="${config_info#*:}"
        
        if [[ -f "$file" ]]; then
            update_paths_in_file "$file" "$description"
            add_dotfiles_detection "$file" "$description"
        fi
    done
    
    # Create a marker file with the actual dotfiles location
    if [[ "$ACTUAL_DOTFILES_DIR" != "$HOME/dotfiles" ]]; then
        echo "$ACTUAL_DOTFILES_DIR" > "$HOME/.dotfiles-root"
        log_success "Created dotfiles location marker: $HOME/.dotfiles-root"
    fi
    
    log_success "Dotfiles path fixes completed!"
    log_info "Shell configurations now use: $ACTUAL_DOTFILES_DIR"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi