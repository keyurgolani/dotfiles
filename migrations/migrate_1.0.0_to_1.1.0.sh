#!/bin/bash

# Migration Script: 1.0.0 to 1.1.0
# Handles specific changes introduced in version 1.1.0

set -euo pipefail

FROM_VERSION="$1"
TO_VERSION="$2"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(dirname "$SCRIPT_DIR")"

# Source logging utilities
source "$FRAMEWORK_ROOT/core/logger.sh"

log_info "Running migration from $FROM_VERSION to $TO_VERSION"

# Migration tasks specific to 1.1.0

# 1. Update configuration schema for new features
update_config_schema() {
    log_debug "Updating configuration schema for v1.1.0..."
    
    local config_file="$FRAMEWORK_ROOT/config/base.yaml"
    
    if [[ -f "$config_file" ]]; then
        # Add new performance section if it doesn't exist
        if ! grep -q "^performance:" "$config_file"; then
            cat >> "$config_file" << 'EOF'

# Performance optimization settings (added in v1.1.0)
performance:
  enable_parallel_installation: true
  enable_download_cache: true
  enable_platform_cache: true
  enable_progress_indicators: true
  shell_startup_optimization: true
  max_parallel_jobs: 4
  cache_ttl_seconds: 3600
EOF
            log_info "Added performance configuration section"
        fi
        
        # Add update settings if they don't exist
        if ! grep -q "update_settings:" "$config_file"; then
            cat >> "$config_file" << 'EOF'

# Update and maintenance settings (added in v1.1.0)
update_settings:
  auto_check_updates: true
  update_check_interval: 86400  # 24 hours
  backup_before_update: true
  cleanup_old_backups: true
EOF
            log_info "Added update settings configuration section"
        fi
    fi
    
    log_debug "Configuration schema update completed"
}

# 2. Migrate old backup format to new format
migrate_backup_format() {
    log_debug "Migrating backup format..."
    
    local backup_dir="$HOME/.dotfiles-backups"
    
    if [[ -d "$backup_dir" ]]; then
        # Look for old backup directories without proper metadata
        for old_backup in "$backup_dir"/backup_*; do
            if [[ -d "$old_backup" && ! -f "$old_backup/backup_metadata.json" ]]; then
                log_info "Adding metadata to old backup: $(basename "$old_backup")"
                
                # Create basic metadata for old backup
                local backup_id
                backup_id="$(basename "$old_backup")"
                local backup_date
                backup_date=$(stat -c %Y "$old_backup" 2>/dev/null || date +%s)
                
                cat > "$old_backup/backup_metadata.json" << EOF
{
  "id": "$backup_id",
  "created_at": $backup_date,
  "framework_version": "1.0.0",
  "backup_type": "manual",
  "description": "Legacy backup (migrated in v1.1.0)"
}
EOF
            fi
        done
    fi
    
    log_debug "Backup format migration completed"
}

# 3. Update module structure for new features
update_module_structure() {
    log_debug "Updating module structure for v1.1.0..."
    
    local modules_dir="$FRAMEWORK_ROOT/modules"
    
    if [[ -d "$modules_dir" ]]; then
        for module_dir in "$modules_dir"/*; do
            if [[ -d "$module_dir" ]]; then
                local module_name
                module_name="$(basename "$module_dir")"
                
                # Add update.sh script template if it doesn't exist
                local update_script="$module_dir/update.sh"
                if [[ ! -f "$update_script" ]]; then
                    cat > "$update_script" << 'EOF'
#!/bin/bash

# Module Update Script
# This script handles updates for this specific module

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_NAME="$(basename "$MODULE_DIR")"

# Source framework utilities
FRAMEWORK_ROOT="$(dirname "$(dirname "$MODULE_DIR")")"
source "$FRAMEWORK_ROOT/core/logger.sh"

log_info "Updating module: $MODULE_NAME"

# Module-specific update logic goes here
# For now, we'll just reinstall the module

# Check if module has install script
if [[ -f "$MODULE_DIR/install.sh" ]]; then
    log_info "Reinstalling module configurations..."
    bash "$MODULE_DIR/install.sh"
else
    log_warn "No install script found for module: $MODULE_NAME"
fi

log_info "Module update completed: $MODULE_NAME"
EOF
                    chmod +x "$update_script"
                    log_debug "Created update script for module: $module_name"
                fi
            fi
        done
    fi
    
    log_debug "Module structure update completed"
}

# 4. Initialize new cache directories
initialize_cache_directories() {
    log_debug "Initializing new cache directories..."
    
    local cache_base="$FRAMEWORK_ROOT/cache"
    
    # Create new cache subdirectories introduced in v1.1.0
    local new_cache_dirs=(
        "$cache_base/updates"
        "$cache_base/downloads"
        "$cache_base/platform"
        "$cache_base/modules"
    )
    
    for cache_dir in "${new_cache_dirs[@]}"; do
        if [[ ! -d "$cache_dir" ]]; then
            mkdir -p "$cache_dir"
            log_debug "Created cache directory: $(basename "$cache_dir")"
        fi
    done
    
    # Create cache index file
    local cache_index="$cache_base/cache_index.json"
    if [[ ! -f "$cache_index" ]]; then
        cat > "$cache_index" << 'EOF'
{
  "version": "1.1.0",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cache_directories": {
    "updates": "Framework update cache",
    "downloads": "Downloaded package cache",
    "platform": "Platform detection cache",
    "modules": "Module metadata cache"
  }
}
EOF
        log_debug "Created cache index file"
    fi
    
    log_debug "Cache directory initialization completed"
}

# Run all migration tasks
main() {
    log_info "Starting v1.1.0 specific migration tasks..."
    
    update_config_schema
    migrate_backup_format
    update_module_structure
    initialize_cache_directories
    
    log_info "v1.1.0 migration completed successfully"
}

# Execute main function
main "$@"