#!/bin/bash

# Unified Dotfiles Framework - Configuration Management
# Handles YAML configuration parsing and management

# Configuration system variables
CONFIG_CACHE_DIR="${HOME}/.dotfiles/cache/config"
DEFAULT_CONFIG_VALUES=""

# Initialize configuration system
init_config_system() {
    log_debug "Initializing configuration system..."
    
    # Create cache directory
    if [[ ! -d "$CONFIG_CACHE_DIR" ]]; then
        mkdir -p "$CONFIG_CACHE_DIR"
    fi
    
    # Set default configuration values
    set_default_config_values
    
    log_debug "Configuration system initialized"
    return 0
}

# Set default configuration values
set_default_config_values() {
    DEFAULT_CONFIG_VALUES=$(cat << 'EOF'
settings:
  backup_enabled: true
  backup_retention_days: 30
  interactive_mode: true
  parallel_installation: true

performance:
  enable_parallel_installation: true
  enable_download_cache: true
  enable_platform_cache: true
  enable_progress_indicators: true
  shell_startup_optimization: true
  max_parallel_jobs: 4
  cache_ttl_seconds: 3600

modules:
  enabled: []
  disabled: []

user:
  name: ""
  email: ""
  github_username: ""
EOF
)
}

# Simple YAML value extraction (basic implementation)
get_yaml_value() {
    local file="$1"
    local key="$2"
    local default_value="$3"
    
    if [[ ! -f "$file" ]]; then
        echo "$default_value"
        return 1
    fi
    
    # Convert dot notation to grep pattern
    local pattern
    case "$key" in
        *.*)
            # Handle nested keys like "settings.backup_enabled"
            local parent_key="${key%.*}"
            local child_key="${key##*.}"
            
            # Find the parent section and then the child key
            local in_section=false
            while IFS= read -r line; do
                # Remove leading whitespace and comments
                local clean_line
                clean_line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/#.*//')
                
                # Check if we're entering the parent section
                if [[ "$clean_line" == "$parent_key:" ]]; then
                    in_section=true
                    continue
                fi
                
                # Check if we're leaving the section (new top-level key)
                if [[ "$in_section" == true && "$clean_line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*: ]]; then
                    in_section=false
                fi
                
                # If we're in the section, look for our key
                if [[ "$in_section" == true && "$clean_line" =~ ^"$child_key": ]]; then
                    local value
                    value=$(echo "$clean_line" | sed "s/^$child_key:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//')
                    echo "$value"
                    return 0
                fi
            done < "$file"
            ;;
        *)
            # Handle simple keys
            local value
            value=$(grep "^[[:space:]]*$key:" "$file" 2>/dev/null | head -1 | sed "s/^[[:space:]]*$key:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//')
            if [[ -n "$value" ]]; then
                echo "$value"
                return 0
            fi
            ;;
    esac
    
    echo "$default_value"
    return 1
}

# Get YAML array values (basic implementation)
get_yaml_array() {
    local file="$1"
    local key="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # Handle nested keys like "modules.enabled"
    local parent_key="${key%.*}"
    local child_key="${key##*.}"
    
    local in_parent_section=false
    local in_child_array=false
    local result=()
    
    while IFS= read -r line; do
        # Remove leading whitespace and comments
        local clean_line
        clean_line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/#.*//')
        
        # Check if we're entering the parent section
        if [[ "$clean_line" == "$parent_key:" ]]; then
            in_parent_section=true
            continue
        fi
        
        # Check if we're leaving the parent section
        if [[ "$in_parent_section" == true && "$clean_line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*: ]]; then
            if [[ "$clean_line" != "$child_key:" ]]; then
                in_parent_section=false
                in_child_array=false
            fi
        fi
        
        # Check if we're entering the child array
        if [[ "$in_parent_section" == true && "$clean_line" == "$child_key:" ]]; then
            in_child_array=true
            continue
        fi
        
        # Check if we're leaving the child array
        if [[ "$in_child_array" == true && "$clean_line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*: ]]; then
            in_child_array=false
        fi
        
        # If we're in the array, collect items
        if [[ "$in_child_array" == true && "$clean_line" =~ ^-[[:space:]]+ ]]; then
            local item
            item=$(echo "$clean_line" | sed 's/^-[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
            result+=("$item")
        fi
    done < "$file"
    
    # Output array elements separated by spaces
    if [[ ${#result[@]} -gt 0 ]]; then
        printf "%s " "${result[@]}"
        return 0
    fi
    
    return 1
}

# Get configuration value with fallback to defaults
get_config_value() {
    local key="$1"
    local default_value="$2"
    local config_file="${3:-}"
    
    # Try to get value from specified config file
    if [[ -n "$config_file" && -f "$config_file" ]]; then
        local value
        value=$(get_yaml_value "$config_file" "$key" "")
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi
    
    # Try to get value from user config
    local user_config="$SCRIPT_DIR/config/user.yaml"
    if [[ -f "$user_config" ]]; then
        local value
        value=$(get_yaml_value "$user_config" "$key" "")
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi
    
    # Try to get value from base config
    local base_config="$SCRIPT_DIR/config/base.yaml"
    if [[ -f "$base_config" ]]; then
        local value
        value=$(get_yaml_value "$base_config" "$key" "")
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi
    
    # Return default value
    echo "$default_value"
}

# Check if configuration value is true
is_config_enabled() {
    local key="$1"
    local config_file="${2:-}"
    
    local value
    value=$(get_config_value "$key" "false" "$config_file")
    
    case "${value,,}" in
        true|yes|1|on|enabled)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Validate configuration file
validate_config_file() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Basic YAML syntax validation
    if ! validate_yaml_syntax "$config_file"; then
        log_error "Invalid YAML syntax in: $config_file"
        return 1
    fi
    
    # Validate required sections exist
    local required_sections=("modules")
    for section in "${required_sections[@]}"; do
        if ! grep -q "^$section:" "$config_file"; then
            log_warn "Missing required section '$section' in: $config_file"
        fi
    done
    
    log_debug "Configuration file validation passed: $config_file"
    return 0
}

# Basic YAML syntax validation
validate_yaml_syntax() {
    local file="$1"
    
    # Check for basic YAML syntax issues
    local line_number=0
    while IFS= read -r line; do
        ((line_number++))
        
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Check for proper key-value format
        if [[ "$line" =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]* ]]; then
            continue
        fi
        
        # Check for array items
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+ ]]; then
            continue
        fi
        
        # Check for indented content
        if [[ "$line" =~ ^[[:space:]]+ ]]; then
            continue
        fi
        
        # If we get here, the line might be invalid
        log_warn "Potential YAML syntax issue at line $line_number: $line"
    done < "$file"
    
    return 0
}

# Merge configuration files
merge_config_files() {
    local base_config="$1"
    local override_config="$2"
    local output_config="$3"
    
    log_debug "Merging configurations: $base_config + $override_config -> $output_config"
    
    # Simple merge: copy base, then append overrides
    # In a production system, you'd want proper YAML merging
    
    if [[ -f "$base_config" ]]; then
        cp "$base_config" "$output_config"
    else
        touch "$output_config"
    fi
    
    if [[ -f "$override_config" ]]; then
        echo "" >> "$output_config"
        echo "# Overrides from $override_config" >> "$output_config"
        cat "$override_config" >> "$output_config"
    fi
    
    log_debug "Configuration merge completed"
}

# Create configuration backup
backup_config() {
    local config_file="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"
    
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "${config_file}${backup_suffix}"
        log_debug "Configuration backup created: ${config_file}${backup_suffix}"
        return 0
    fi
    
    return 1
}

# Restore configuration from backup
restore_config() {
    local config_file="$1"
    local backup_file="$2"
    
    if [[ -f "$backup_file" ]]; then
        cp "$backup_file" "$config_file"
        log_info "Configuration restored from: $backup_file"
        return 0
    fi
    
    log_error "Backup file not found: $backup_file"
    return 1
}

# Show configuration summary
show_config_summary() {
    local config_file="${1:-$DEFAULT_CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        log_warn "Configuration file not found: $config_file"
        return 1
    fi
    
    echo "Configuration Summary ($config_file):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show enabled modules
    local enabled_modules
    enabled_modules=$(get_yaml_array "$config_file" "modules.enabled")
    if [[ -n "$enabled_modules" ]]; then
        echo "Enabled Modules: $enabled_modules"
    else
        echo "Enabled Modules: none"
    fi
    
    # Show key settings
    echo "Backup Enabled: $(get_config_value "settings.backup_enabled" "true" "$config_file")"
    echo "Interactive Mode: $(get_config_value "settings.interactive_mode" "true" "$config_file")"
    echo "Parallel Installation: $(get_config_value "performance.enable_parallel_installation" "true" "$config_file")"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}