# Override System Documentation

The Unified Dotfiles Framework includes a powerful override system that allows you to customize configurations based on your environment, platform, hostname, and custom conditions. This system provides flexibility to maintain different configurations for work, personal, and development environments while sharing common base configurations.

## Overview

The override system works by applying configuration changes in a specific order of precedence:

1. **Base Configuration** - Your main configuration files
2. **Configuration Inheritance** - Configurations that extend other configurations
3. **Platform Overrides** - Applied based on detected OS (macOS, Ubuntu, WSL, Amazon Linux)
4. **Environment Variable Overrides** - Applied when specific environment variables are set
5. **Custom Condition Overrides** - Applied when custom shell conditions are met
6. **Hostname Overrides** - Applied based on the current hostname (highest precedence)

## Directory Structure

```
config/
├── base.yaml                    # Base configuration for inheritance
├── modules.yaml                 # Main module configuration
├── user.yaml                   # User-specific settings
└── overrides/
    ├── platform/               # Platform-specific overrides
    │   ├── macos.yaml          # macOS-specific configuration
    │   ├── ubuntu.yaml         # Ubuntu-specific configuration
    │   ├── wsl.yaml            # WSL-specific configuration
    │   └── amazon-linux.yaml  # Amazon Linux-specific configuration
    ├── hostname/               # Hostname-specific overrides
    │   ├── work-laptop.yaml    # Configuration for specific machine
    │   └── home-desktop.yaml   # Configuration for another machine
    ├── environment/            # Environment variable overrides
    │   ├── WORK_ENV.yaml       # Applied when WORK_ENV is set
    │   ├── DEV_ENV.yaml        # Applied when DEV_ENV is set
    │   └── PROD_ENV.yaml       # Applied when PROD_ENV is set
    ├── conditions/             # Custom condition overrides
    │   ├── docker-available.yaml      # Applied when Docker is available
    │   ├── corporate-network.yaml     # Applied in corporate environment
    │   └── high-performance.yaml      # Applied on high-performance systems
    └── work.yaml               # Example configuration with inheritance
```

## Configuration Types

### 1. Platform Overrides

Platform overrides are automatically applied based on the detected operating system.

**Example: `config/overrides/platform/macos.yaml`**
```yaml
# Platform-specific overrides for macOS
modules:
  enabled:
    - homebrew
    - iterm2
    - macos-defaults
  disabled: []

settings:
  shell: "/bin/zsh"
  package_manager: "brew"
  platform_specific: true

user:
  platform: "macos"

packages:
  git: "git"
  vim: "vim"
  tmux: "tmux"
  node: "node"
  python: "python@3.11"
```

### 2. Environment Variable Overrides

These overrides are applied when specific environment variables are set.

**Example: `config/overrides/environment/WORK_ENV.yaml`**
```yaml
# Work environment overrides
# Applied when WORK_ENV environment variable is set
modules:
  enabled:
    - corporate-vpn
    - work-tools
    - security-tools
  disabled:
    - personal-tools

settings:
  git_signing_required: true
  backup_to_corporate: true
  security_enhanced: true

user:
  email: "${WORK_EMAIL}"
  git_signing_key: "${WORK_GPG_KEY}"

git:
  user:
    email: "${WORK_EMAIL}"
  commit:
    gpgsign: true
  url:
    "git@github-work:":
      insteadOf: "git@github.com:"
```

### 3. Custom Condition Overrides

These overrides are applied when custom shell conditions evaluate to true.

**Example: `config/overrides/conditions/docker-available.yaml`**
```yaml
# Applied when Docker is available
condition: "command -v docker >/dev/null 2>&1"

overrides:
  modules:
    enabled:
      - docker-tools
      - container-utils
  
  settings:
    docker_available: true
    container_support: true
  
  shell:
    aliases:
      dps: "docker ps"
      dimg: "docker images"
      drun: "docker run -it --rm"
      dexec: "docker exec -it"
```

### 4. Hostname Overrides

These overrides are applied based on the current hostname, providing machine-specific configurations.

**Example: `config/overrides/hostname/work-laptop.yaml`**
```yaml
# Hostname-specific overrides for work laptop
extends: "../work.yaml"  # Can inherit from other configurations

modules:
  enabled:
    - laptop-tools
    - power-management
  disabled:
    - desktop-tools

settings:
  laptop_mode: true
  power_management: true

shell:
  aliases:
    battery: "pmset -g batt"
    sleep: "pmset sleepnow"
```

### 5. Configuration Inheritance

Configurations can extend other configurations using the `extends` field.

**Example: `config/overrides/work.yaml`**
```yaml
# Work configuration that extends base
extends: "base.yaml"

modules:
  enabled:
    - shell
    - git
    - vim
    - corporate-tools
  disabled:
    - personal-tools

settings:
  backup_retention_days: 90  # Override base setting
  security_enhanced: true

user:
  work_environment: true
  corporate_email: "${WORK_EMAIL}"

git:
  user:
    email: "${WORK_EMAIL}"
    signingkey: "${WORK_GPG_KEY}"
  commit:
    gpgsign: true
```

## Environment Variables

The override system supports environment variable substitution using `${VARIABLE_NAME}` syntax:

```yaml
user:
  email: "${WORK_EMAIL}"
  name: "${USER_FULL_NAME:-Default Name}"

git:
  user:
    signingkey: "${GPG_KEY_ID}"

shell:
  exports:
    WORKSPACE: "${WORK_WORKSPACE:-$HOME/work}"
```

## Usage Examples

### Setting Up Work Environment

1. Set environment variables:
```bash
export WORK_ENV="true"
export WORK_EMAIL="john.doe@company.com"
export WORK_GPG_KEY="ABC123DEF456"
```

2. Run the installation:
```bash
./install.sh
```

The system will automatically:
- Apply platform-specific overrides (e.g., macOS settings)
- Apply work environment overrides (corporate tools, security settings)
- Apply any matching condition overrides (e.g., Docker tools if Docker is available)

### Creating Custom Overrides

Generate a new override file:
```bash
# Generate platform override
./install.sh --generate-override platform my-platform config/overrides/platform/my-platform.yaml

# Generate environment override
./install.sh --generate-override environment MY_ENV config/overrides/environment/MY_ENV.yaml

# Generate condition override
./install.sh --generate-override condition gpu-available config/overrides/conditions/gpu-available.yaml "command -v nvidia-smi >/dev/null 2>&1"
```

### Listing Available Overrides

```bash
# List all override files
./install.sh --list-overrides

# List specific type
./install.sh --list-overrides platform
./install.sh --list-overrides environment
./install.sh --list-overrides conditions
```

### Testing Override Application

```bash
# Show current environment context
./install.sh --show-context

# Test override application without installation
./install.sh --dry-run --verbose
```

## Advanced Features

### Conditional Logic in Overrides

You can use complex conditions in condition overrides:

```yaml
# Multiple conditions
condition: "test -d /opt/corporate && command -v vpn >/dev/null 2>&1"

# Environment variable checks
condition: "test -n \"$CORPORATE_NETWORK\" && test \"$SECURITY_LEVEL\" = \"high\""

# File existence checks
condition: "test -f ~/.ssh/corporate_key && test -f /etc/corporate/config"
```

### Deep Configuration Merging

The override system performs deep merging of configurations:

```yaml
# Base configuration
shell:
  aliases:
    ls: "ls --color=auto"
    ll: "ls -l"
  exports:
    EDITOR: "vim"

# Override configuration
shell:
  aliases:
    la: "ls -la"        # Added
    ll: "ls -la"        # Overridden
  exports:
    PAGER: "less"       # Added
    
# Result after merging
shell:
  aliases:
    ls: "ls --color=auto"  # Preserved
    ll: "ls -la"           # Overridden
    la: "ls -la"           # Added
  exports:
    EDITOR: "vim"          # Preserved
    PAGER: "less"          # Added
```

### Override Precedence

When multiple overrides affect the same configuration key, the precedence order is:

1. Hostname overrides (highest)
2. Custom condition overrides
3. Environment variable overrides
4. Platform overrides
5. Base configuration (lowest)

## Best Practices

### 1. Use Inheritance for Related Configurations

```yaml
# config/base.yaml - Common settings
# config/overrides/work.yaml - Work-specific settings (extends base.yaml)
# config/overrides/hostname/work-laptop.yaml - Machine-specific (extends work.yaml)
```

### 2. Environment Variable Naming

Use consistent naming conventions:
- `WORK_ENV` for work environment
- `DEV_ENV` for development environment
- `PROD_ENV` for production environment

### 3. Condition Complexity

Keep conditions simple and readable:
```yaml
# Good
condition: "command -v docker >/dev/null 2>&1"

# Avoid overly complex conditions
condition: "test -f ~/.config/complex && grep -q 'setting' ~/.config/complex && command -v tool >/dev/null 2>&1"
```

### 4. Documentation

Document your override files:
```yaml
# Work environment configuration
# This file is applied when WORK_ENV is set
# Required environment variables:
#   - WORK_EMAIL: Corporate email address
#   - WORK_GPG_KEY: GPG signing key ID
```

## Troubleshooting

### Debug Override Application

Enable debug logging to see which overrides are being applied:
```bash
export LOG_LEVEL=4  # Debug level
./install.sh --verbose
```

### Validate Override Files

Check override file syntax:
```bash
./install.sh --validate-overrides
```

### Test Conditions

Test custom conditions manually:
```bash
# Test if condition evaluates correctly
if command -v docker >/dev/null 2>&1; then
    echo "Docker condition would be true"
else
    echo "Docker condition would be false"
fi
```

### Common Issues

1. **Environment variables not substituted**: Ensure variables are exported before running installation
2. **Overrides not applied**: Check file paths and YAML syntax
3. **Inheritance loops**: Avoid circular references in `extends` fields
4. **Condition failures**: Test conditions in isolation to ensure they work correctly

## API Reference

### Core Functions

- `init_override_system()` - Initialize the override system
- `apply_all_overrides(config)` - Apply all applicable overrides to a configuration
- `apply_platform_overrides(config)` - Apply platform-specific overrides
- `apply_env_overrides(config)` - Apply environment variable overrides
- `apply_condition_overrides(config)` - Apply custom condition overrides
- `apply_hostname_overrides(config)` - Apply hostname-specific overrides
- `process_inheritance(config)` - Process configuration inheritance
- `generate_override_file(type, name, file, ...)` - Generate new override files
- `list_override_files([type])` - List available override files
- `validate_override_config(file)` - Validate override file syntax

### Environment Context Functions

- `detect_environment_context()` - Detect current environment
- `get_context_value(key)` - Get environment context value
- `show_environment_context()` - Display current environment information

This override system provides a powerful and flexible way to manage configurations across different environments while maintaining clean separation of concerns and avoiding configuration duplication.