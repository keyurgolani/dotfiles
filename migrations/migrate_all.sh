#!/bin/bash

# Universal Migration Script
# This script runs for all version transitions and handles common migration tasks

set -euo pipefail

FROM_VERSION="$1"
TO_VERSION="$2"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(dirname "$SCRIPT_DIR")"

# Source logging utilities
source "$FRAMEWORK_ROOT/core/logger.sh"

log_info "Running universal migration from $FROM_VERSION to $TO_VERSION"

# Common migration tasks that apply to all version transitions

# 1. Update configuration file formats if needed
migrate_config_formats() {
    log_debug "Checking configuration file formats..."
    
    local config_dir="$FRAMEWORK_ROOT/config"
    
    # Ensure all YAML files have proper structure
    for config_file in "$config_dir"/*.yaml; do
        if [[ -f "$config_file" ]]; then
            # Basic YAML validation (if yq is available)
            if command -v yq >/dev/null 2>&1; then
                if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
                    log_warn "Configuration file may have syntax issues: $config_file"
                fi
            fi
        fi
    done
    
    log_debug "Configuration format check completed"
}

# 2. Update cache directory structure
migrate_cache_structure() {
    log_debug "Updating cache directory structure..."
    
    local cache_dir="$FRAMEWORK_ROOT/cache"
    
    # Create new cache subdirectories if they don't exist
    mkdir -p "$cache_dir/updates"
    mkdir -p "$cache_dir/downloads"
    mkdir -p "$cache_dir/platform"
    
    # Move old cache files to appropriate subdirectories
    if [[ -f "$cache_dir/latest_version" ]]; then
        mv "$cache_dir/latest_version" "$cache_dir/updates/" 2>/dev/null || true
    fi
    
    log_debug "Cache structure migration completed"
}

# 3. Update log directory structure
migrate_log_structure() {
    log_debug "Updating log directory structure..."
    
    local log_dir="$FRAMEWORK_ROOT/logs"
    mkdir -p "$log_dir"
    
    # Ensure log files have proper permissions
    if [[ -f "$log_dir/install.log" ]]; then
        chmod 644 "$log_dir/install.log"
    fi
    
    log_debug "Log structure migration completed"
}

# 4. Clean up deprecated files
cleanup_deprecated_files() {
    log_debug "Cleaning up deprecated files..."
    
    # List of files that may have been deprecated
    local deprecated_files=(
        "$FRAMEWORK_ROOT/old_install.sh"
        "$FRAMEWORK_ROOT/legacy_config.yaml"
        "$FRAMEWORK_ROOT/deprecated_module.sh"
    )
    
    for file in "${deprecated_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "Removing deprecated file: $(basename "$file")"
            rm -f "$file"
        fi
    done
    
    log_debug "Deprecated file cleanup completed"
}

# 5. Update module metadata
update_module_metadata() {
    log_debug "Updating module metadata..."
    
    local modules_dir="$FRAMEWORK_ROOT/modules"
    
    if [[ -d "$modules_dir" ]]; then
        for module_dir in "$modules_dir"/*; do
            if [[ -d "$module_dir" ]]; then
                local module_yaml="$module_dir/module.yaml"
                
                # Ensure module.yaml exists and has required fields
                if [[ -f "$module_yaml" ]]; then
                    # Add version field if missing
                    if ! grep -q "^version:" "$module_yaml"; then
                        echo "version: \"1.0.0\"" >> "$module_yaml"
                        log_debug "Added version field to $(basename "$module_dir")/module.yaml"
                    fi
                fi
            fi
        done
    fi
    
    log_debug "Module metadata update completed"
}

# Run all migration tasks
main() {
    log_info "Starting universal migration tasks..."
    
    migrate_config_formats
    migrate_cache_structure
    migrate_log_structure
    cleanup_deprecated_files
    update_module_metadata
    
    log_info "Universal migration completed successfully"
}

# Execute main function
main "$@"