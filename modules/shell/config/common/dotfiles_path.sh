#!/bin/bash
# Dotfiles Path Detection
# This script detects the location of the dotfiles directory dynamically

# Function to detect dotfiles directory
detect_dotfiles_dir() {
    local dotfiles_dir=""
    
    # Method 1: Check if DOTFILES_ROOT is already set
    if [[ -n "${DOTFILES_ROOT:-}" ]] && [[ -d "$DOTFILES_ROOT" ]]; then
        dotfiles_dir="$DOTFILES_ROOT"
    
    # Method 2: Look for dotfiles directory in common locations
    elif [[ -d "$HOME/dotfiles" ]] && [[ -f "$HOME/dotfiles/install.sh" ]]; then
        dotfiles_dir="$HOME/dotfiles"
    
    # Method 3: Check current directory and parent directories
    elif [[ -f "./install.sh" ]] && [[ -d "./modules" ]]; then
        dotfiles_dir="$(pwd)"
    
    # Method 4: Look for dotfiles in parent directories (for sourced scripts)
    else
        local current_dir="$(pwd)"
        local search_dir="$current_dir"
        
        # Search up to 5 levels up
        for i in {1..5}; do
            if [[ -f "$search_dir/install.sh" ]] && [[ -d "$search_dir/modules" ]]; then
                dotfiles_dir="$search_dir"
                break
            fi
            search_dir="$(dirname "$search_dir")"
            [[ "$search_dir" == "/" ]] && break
        done
        
        # Method 5: Check if we're in a dotfiles subdirectory
        if [[ -z "$dotfiles_dir" ]]; then
            local check_dir="$current_dir"
            while [[ "$check_dir" != "/" ]]; do
                if [[ -f "$check_dir/install.sh" ]] && [[ -d "$check_dir/modules" ]]; then
                    dotfiles_dir="$check_dir"
                    break
                fi
                check_dir="$(dirname "$check_dir")"
            done
        fi
        
        # Method 6: Look for .dotfiles-root marker file
        if [[ -z "$dotfiles_dir" ]] && [[ -f "$HOME/.dotfiles-root" ]]; then
            local marker_path="$(cat "$HOME/.dotfiles-root" 2>/dev/null)"
            if [[ -n "$marker_path" ]] && [[ -d "$marker_path" ]] && [[ -f "$marker_path/install.sh" ]]; then
                dotfiles_dir="$marker_path"
            fi
        fi
    fi
    
    # Validate the detected directory
    if [[ -n "$dotfiles_dir" ]] && [[ -d "$dotfiles_dir/modules/shell" ]]; then
        echo "$dotfiles_dir"
        return 0
    else
        # Fallback to ~/dotfiles for backward compatibility
        echo "$HOME/dotfiles"
        return 1
    fi
}

# Set DOTFILES_DIR if not already set
if [[ -z "${DOTFILES_DIR:-}" ]]; then
    export DOTFILES_DIR="$(detect_dotfiles_dir)"
fi

# Create a marker file for future detection (optional)
create_dotfiles_marker() {
    if [[ -n "${DOTFILES_DIR:-}" ]] && [[ -d "$DOTFILES_DIR" ]] && [[ "$DOTFILES_DIR" != "$HOME/dotfiles" ]]; then
        echo "$DOTFILES_DIR" > "$HOME/.dotfiles-root" 2>/dev/null || true
    fi
}

# Helper function to source dotfiles-relative files safely
source_dotfiles_file() {
    local relative_path="$1"
    local full_path="${DOTFILES_DIR}/${relative_path}"
    
    if [[ -f "$full_path" ]]; then
        source "$full_path"
        return 0
    else
        return 1
    fi
}

# Export the helper function for use in shell configs
export -f source_dotfiles_file 2>/dev/null || true