# Configuration Management System

The Unified Dotfiles Framework includes a comprehensive configuration management system that handles YAML configuration parsing, validation, merging, and environment variable substitution.

## Features

- **YAML Configuration Parsing**: Supports both `yq` and Python-based YAML parsing
- **Configuration Validation**: JSON schema-based validation for configuration files
- **Environment Variable Substitution**: Automatic substitution of environment variables in configuration files
- **Configuration Merging**: Deep merging of multiple configuration files
- **Caching**: Efficient caching of parsed configurations

## Configuration Files

### Base Configuration (`config/base.yaml`)

The base configuration file contains default settings for the framework:

```yaml
# Framework metadata
framework:
  name: "unified-dotfiles"
  version: "1.0.0"

# Module configuration
modules:
  # List of modules to install by default
  # Available modules: shell, git, vim, tmux, homebrew, developer-tools
  # Type: array of strings
  # Example: ["shell", "git", "vim"]
  enabled: []
  
  # List of modules to explicitly disable
  # Useful when using 'all' in enabled or inheriting from other configs
  # Type: array of strings
  # Example: ["docker", "kubernetes"]
  disabled: []
  
# Framework behavior settings
settings:
  # Whether to create backups before making changes
  # Type: boolean, Default: true
  # Impact: Prevents data loss during installation
  backup_enabled: true
  
  # Number of days to keep backup files
  # Type: integer, Default: 30, Range: 1-365
  # Impact: Automatic cleanup of old backups
  backup_retention_days: 30
  
  # Whether to prompt user for input during installation
  # Type: boolean, Default: true
  # Impact: Enables/disables interactive prompts
  interactive_mode: true
  
  # Whether to install modules in parallel (legacy setting)
  # Type: boolean, Default: false
  # Note: Use performance.enable_parallel_installation instead
  parallel_installation: false
  
# Performance optimization settings
performance:
  # Enable parallel module installation for faster setup
  # Type: boolean, Default: false
  # Impact: Can reduce installation time by 40-60%
  # Warning: May cause issues on systems with limited resources
  enable_parallel_installation: false
  
  # Cache downloaded files to speed up subsequent installations
  # Type: boolean, Default: true
  # Impact: Reduces download time on repeated installations
  # Storage: Uses ~/.dotfiles/cache/downloads/
  enable_download_cache: true
  
  # Cache platform detection results
  # Type: boolean, Default: true
  # Impact: Faster startup on subsequent runs
  # Storage: Uses ~/.dotfiles/cache/platform/
  enable_platform_cache: true
  
  # Maximum number of parallel jobs during installation
  # Type: integer, Default: 2, Range: 1-8
  # Impact: Higher values may cause system instability
  # Recommendation: Use 2-4 for most systems
  max_parallel_jobs: 2
  
  # Cache time-to-live in seconds
  # Type: integer, Default: 3600 (1 hour), Range: 300-86400
  # Impact: How long cached data remains valid
  cache_ttl_seconds: 3600
  
  # Enable shell startup performance optimizations
  # Type: boolean, Default: true
  # Impact: Can improve shell startup time by up to 85%
  # Features: Lazy loading, deferred initialization
  shell_startup_optimization: true

# User information template
# These values are used in configuration templates
user:
  # Full name for git configuration and other tools
  # Type: string, Required for git module
  # Example: "John Doe"
  name: ""
  
  # Email address for git configuration
  # Type: string, Required for git module
  # Example: "john.doe@example.com"
  email: ""
  
  # GitHub username for git configuration and SSH
  # Type: string, Optional
  # Example: "johndoe"
  # Impact: Used for GitHub-specific git configurations
  github_username: ""
  
  # Optional: Additional user-specific settings
  # shell: "/bin/zsh"      # Preferred shell (Type: string)
  # editor: "vim"          # Default editor (Type: string)
  # timezone: "UTC"        # Timezone preference (Type: string)
```

### User Configuration (`config/user.yaml`)

User-specific overrides that can contain:

```yaml
# Override module selection
modules:
  enabled:
    - shell
    - git
    - vim
    - tmux
  disabled:
    - docker  # Disable even if enabled elsewhere

# Override framework settings
settings:
  # Enable interactive mode for this user
  interactive_mode: true
  
  # Increase backup retention for important configurations
  backup_retention_days: 90

# Performance settings for this user/machine
performance:
  # Enable parallel installation on powerful machines
  enable_parallel_installation: true
  max_parallel_jobs: 4
  
  # Enable all optimizations
  shell_startup_optimization: true
  enable_download_cache: true

# User-specific information
user:
  name: "John Doe"
  email: "john.doe@example.com"
  github_username: "johndoe"
  
  # Additional user preferences
  shell: "/bin/zsh"
  editor: "vim"
  timezone: "America/New_York"

# Module-specific configurations
git:
  # Git-specific settings
  signing_key: "your-gpg-key-id"
  default_branch: "main"
  
  # Custom git aliases
  aliases:
    co: "checkout"
    br: "branch"
    st: "status"

shell:
  # Shell-specific settings
  theme: "powerlevel10k"
  plugins:
    - "git"
    - "docker"
    - "kubectl"
  
  # Custom aliases
  aliases:
    ll: "ls -la"
    la: "ls -A"
    grep: "grep --color=auto"

vim:
  # Vim-specific settings
  colorscheme: "solarized"
  plugins:
    - "nerdtree"
    - "syntastic"
    - "fugitive"
```

### Override Configuration Files

Override files allow environment-specific customizations:

#### Work Environment (`config/overrides/work.yaml`)

```yaml
# Work-specific user information
user:
  email: "john.doe@company.com"
  name: "John Doe (Work)"

# Work-specific modules
modules:
  enabled:
    - corporate-vpn
    - company-tools
    - security-tools
  disabled:
    - personal-tools
    - media-tools

# Work-specific git configuration
git:
  signing_key: "work-gpg-key-id"
  user:
    email: "john.doe@company.com"
  
  # Company-specific git settings
  url_rewrites:
    "git@github-work:": "git@github.com:"

# Work-specific performance settings
performance:
  # Conservative settings for work machines
  enable_parallel_installation: false
  max_parallel_jobs: 2
```

#### Personal Environment (`config/overrides/personal.yaml`)

```yaml
# Personal user information
user:
  email: "john@personal.com"
  name: "John Doe"

# Personal modules
modules:
  enabled:
    - media-tools
    - gaming-setup
    - personal-scripts
  disabled:
    - corporate-tools

# Personal git configuration
git:
  signing_key: "personal-gpg-key-id"
  user:
    email: "john@personal.com"

# Aggressive performance settings for personal machines
performance:
  enable_parallel_installation: true
  max_parallel_jobs: 6
  shell_startup_optimization: true
```

#### Platform-Specific Overrides

**macOS Override (`config/overrides/platform/macos.yaml`)**:

```yaml
# macOS-specific modules
modules:
  enabled:
    - homebrew
    - iterm2
    - macos-defaults

# macOS-specific settings
settings:
  # Use macOS-specific backup location
  backup_location: "~/Library/Application Support/dotfiles/backups"

# macOS-specific user preferences
user:
  shell: "/bin/zsh"  # Default on macOS

# macOS-specific performance settings
performance:
  # macOS can handle more parallel jobs
  max_parallel_jobs: 4
```

**Ubuntu Override (`config/overrides/platform/ubuntu.yaml`)**:

```yaml
# Ubuntu-specific modules
modules:
  enabled:
    - apt-tools
    - ubuntu-desktop
  disabled:
    - homebrew  # Not available on Ubuntu

# Ubuntu-specific settings
user:
  shell: "/bin/bash"  # Default on Ubuntu

# Ubuntu-specific performance settings
performance:
  # More conservative on Ubuntu
  max_parallel_jobs: 2
```

## Usage

### Basic Usage

```bash
# Source the configuration system
source core/config.sh

# Initialize the configuration system
init_config_system

# Get a configuration value from a file
backup_enabled=$(get_yaml_value "config/base.yaml" "settings.backup_enabled" "true")

# Get an array of enabled modules
enabled_modules=$(get_yaml_array "config/modules.yaml" "modules.enabled")

# Check if a feature is enabled
if is_config_enabled "settings.interactive_mode" "config/user.yaml"; then
    echo "Interactive mode is enabled"
fi

# Merge configurations
merge_config_files "config/base.yaml" "config/user.yaml"
```

### Environment Variable Substitution

Configuration files can include environment variables using the following formats:
- `${VARIABLE_NAME}` - Standard format
- `$VARIABLE_NAME` - Short format

Example in user.yaml:
```yaml
user:
  name: "${USER_NAME:-Default Name}"
  email: "${USER_EMAIL:-user@example.com}"
  shell: "${SHELL##*/}"
```

### Configuration Schema Validation

The system includes JSON schemas for validating configuration files:
- `schemas/modules.schema.json` - Validates modules.yaml configuration
- `schemas/user.schema.json` - Validates user.yaml configuration  
- `schemas/module.schema.json` - Validates individual module definitions
- `schemas/plugin.schema.json` - Validates plugin configurations

Validation is performed automatically when loading configuration files using the `validate_config_file()` function.

## API Reference

### Core Functions

- `init_config_system()` - Initializes the configuration system and cache directory
- `get_yaml_value(file, key, default)` - Extracts values from YAML files with dot notation support
- `get_yaml_array(file, key)` - Retrieves array values from YAML configuration
- `get_config_value(key, default)` - Gets configuration value with fallback to defaults
- `is_config_enabled(key, config_file)` - Checks if a configuration value is true/enabled
- `validate_config_file(config_file)` - Validates configuration file structure
- `validate_yaml_syntax(file)` - Validates YAML syntax and structure

### Configuration Management

- `merge_config_files(base_config, override_config)` - Merges two configuration files
- `backup_config(config_file, backup_suffix)` - Creates timestamped configuration backups
- `restore_config(config_file, backup_file)` - Restores configuration from backup
- `show_config_summary(config_file)` - Displays configuration summary

### Utility Functions

- `set_default_config_values()` - Sets framework default configuration values
- Configuration caching in `~/.dotfiles/cache/config/` for performance

## Dependencies

The configuration system uses a lightweight, pure bash implementation:
- **Bash 4.0+** - Core shell functionality
- **Standard Unix tools** - grep, sed, awk for text processing
- **No external dependencies** - Self-contained YAML parsing

The system includes:
- Built-in YAML parsing for common use cases
- Dot notation support for nested keys (e.g., `settings.backup_enabled`)
- Array value extraction
- Configuration validation and error handling

## Error Handling

The configuration system includes comprehensive error handling:
- Syntax validation before parsing
- Graceful fallbacks for missing tools
- Detailed error logging
- Safe defaults for missing values

## Examples

### Working with User Configuration

```bash
# Initialize the system
init_config_system

# Get user information with defaults
user_name=$(get_yaml_value "config/user.yaml" "user.name" "Unknown User")
user_email=$(get_yaml_value "config/user.yaml" "user.email" "user@example.com")

# Check if modules are enabled
if is_config_enabled "modules.enabled" "config/user.yaml"; then
    echo "Modules are configured"
fi

# Validate configuration before use
if validate_config_file "config/user.yaml"; then
    echo "Configuration is valid"
else
    echo "Configuration has errors"
fi
```

### Configuration Backup and Restore

```bash
# Create a backup before making changes
backup_config "config/user.yaml"

# Make changes to configuration
# ... modify config/user.yaml ...

# Restore from backup if needed
restore_config "config/user.yaml" "config/user.yaml.backup.20231201_143022"

# Show configuration summary
show_config_summary "config/user.yaml"
```