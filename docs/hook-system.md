# Hook System Documentation

The Unified Dotfiles Framework includes a comprehensive hook system that allows for extensible pre/post installation hooks with global, module-specific, and environment-specific support.

## Overview

The hook system provides multiple levels of customization:

- **Global hooks**: Apply to all operations
- **Module-specific hooks**: Apply to specific module operations
- **Environment-specific hooks**: Apply based on environment (work, personal, etc.)
- **Platform-specific hooks**: Apply based on platform (macOS, Ubuntu, etc.)
- **Condition-based hooks**: Apply when specific conditions are met

## Hook Types

The following hook types are supported:

- `pre_install` - Before global installation
- `post_install` - After global installation
- `pre_uninstall` - Before global uninstallation
- `post_uninstall` - After global uninstallation
- `pre_module_install` - Before module installation
- `post_module_install` - After module installation
- `pre_module_uninstall` - Before module uninstallation
- `post_module_uninstall` - After module uninstallation
- `pre_backup` - Before backup operations
- `post_backup` - After backup operations
- `pre_restore` - Before restore operations
- `post_restore` - After restore operations
- `override_applied` - When configuration overrides are applied
- `config_loaded` - When configuration is loaded
- `platform_detected` - When platform is detected

## Directory Structure

```
hooks/
├── global/                    # Global hooks (apply to all operations)
│   ├── pre_install/
│   ├── post_install/
│   └── ...
├── modules/                   # Module-specific hooks
│   ├── git/
│   │   ├── pre_module_install/
│   │   ├── post_module_install/
│   │   └── ...
│   └── shell/
│       └── ...
├── environments/              # Environment-specific hooks
│   ├── work/
│   │   ├── pre_install/
│   │   └── ...
│   ├── personal/
│   └── hostname-based/
├── platforms/                 # Platform-specific hooks
│   ├── macos/
│   │   ├── pre_install/
│   │   └── ...
│   ├── ubuntu/
│   └── ...
└── conditions/                # Condition-based hooks
    ├── pre_install/
    │   ├── docker-available/
    │   │   ├── condition.sh
    │   │   └── setup-docker-tools.sh
    │   └── ...
    └── ...
```

## Hook Execution Order

Hooks are executed in the following order:

1. **Global hooks** - Always executed first
2. **Platform hooks** - Based on current platform
3. **Environment hooks** - Based on environment variables or hostname
4. **Condition hooks** - Based on runtime conditions
5. **Module hooks** - For module-specific operations

## Creating Hooks

### Using the CLI

```bash
# Create a global pre-install hook
./hooks_cli.sh create pre_install system-check global

# Create a module-specific hook
./hooks_cli.sh create post_install setup-aliases module git

# Create an environment-specific hook
./hooks_cli.sh create pre_install work-vpn environment work

# Create a platform-specific hook
./hooks_cli.sh create pre_install macos-setup platform macos

# Create a condition-based hook
./hooks_cli.sh create pre_install docker-setup condition docker-available
```

### Manual Creation

You can also create hooks manually by placing executable shell scripts in the appropriate directories:

```bash
# Create directory
mkdir -p hooks/global/pre_install

# Create hook script
cat > hooks/global/pre_install/my-hook.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Hook implementation
echo "Executing my custom hook"
echo "Platform: $PLATFORM"
echo "User: $USER"

# Return 0 for success, non-zero for failure
exit 0
EOF

# Make executable
chmod +x hooks/global/pre_install/my-hook.sh
```

## Hook Environment Variables

All hooks have access to the following environment variables:

- `DOTFILES_ROOT` - Root directory of dotfiles framework
- `PLATFORM` - Current platform (macos, ubuntu, wsl, amazon-linux)
- `PACKAGE_MANAGER` - Current package manager (brew, apt, yum, dnf)
- `HOSTNAME` - Current hostname
- `USER` - Current user
- `HOME` - User home directory
- `SHELL` - Current shell
- `TIMESTAMP` - Hook execution timestamp

For module-specific hooks:
- `MODULE_NAME` - Name of the module being processed
- `MODULE_DIR` - Directory of the module being processed

## Hook Script Requirements

Hook scripts must:

1. Be executable (`chmod +x`)
2. Have a `.sh` extension
3. Return 0 for success, non-zero for failure
4. Handle errors gracefully
5. Use `set -euo pipefail` for strict error handling

## Example Hooks

### Global System Check Hook

```bash
#!/bin/bash
# hooks/global/pre_install/00-system-check.sh
set -euo pipefail

# Source core utilities
CORE_DIR="$DOTFILES_ROOT/core"
source "$CORE_DIR/logger.sh"
source "$CORE_DIR/utils.sh"

main() {
    log_info "Running system compatibility check..."
    
    # Check platform compatibility
    case "$PLATFORM" in
        "macos"|"ubuntu"|"wsl"|"amazon-linux")
            log_success "Platform '$PLATFORM' is supported"
            ;;
        *)
            log_error "Platform '$PLATFORM' is not supported"
            return 1
            ;;
    esac
    
    # Check disk space
    local available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    local required_space=1048576  # 1GB in KB
    
    if [[ $available_space -gt $required_space ]]; then
        log_success "Sufficient disk space available"
    else
        log_error "Insufficient disk space"
        return 1
    fi
    
    return 0
}

main "$@"
```

### Module-Specific Hook

```bash
#!/bin/bash
# hooks/modules/git/post_install/git-config-check.sh
set -euo pipefail

CORE_DIR="$DOTFILES_ROOT/core"
source "$CORE_DIR/logger.sh"

main() {
    log_info "Checking git configuration for module: $MODULE_NAME"
    
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git not found after installation"
        return 1
    fi
    
    if ! git config --global user.name >/dev/null 2>&1; then
        log_warn "Git user name not configured"
        echo "Run: git config --global user.name 'Your Name'"
    fi
    
    if ! git config --global user.email >/dev/null 2>&1; then
        log_warn "Git user email not configured"
        echo "Run: git config --global user.email 'your@email.com'"
    fi
    
    return 0
}

main "$@"
```

### Condition-Based Hook

```bash
#!/bin/bash
# hooks/conditions/pre_install/docker-available/condition.sh
set -euo pipefail

# Check if Docker is available and running
main() {
    # Check if docker command exists
    if ! command -v docker >/dev/null 2>&1; then
        return 1
    fi
    
    # Check if Docker daemon is accessible
    if ! docker info >/dev/null 2>&1; then
        return 1
    fi
    
    # Docker is available and accessible
    return 0
}

main "$@"
```

```bash
#!/bin/bash
# hooks/conditions/pre_install/docker-available/setup-docker-tools.sh
set -euo pipefail

CORE_DIR="$DOTFILES_ROOT/core"
source "$CORE_DIR/logger.sh"

main() {
    log_info "Docker detected - setting up Docker-related configurations"
    
    # Docker-specific setup logic here
    local docker_version=$(docker --version)
    log_info "Docker version: $docker_version"
    
    return 0
}

main "$@"
```

## Managing Hooks

### List Hooks

```bash
# List all hooks
./hooks_cli.sh list

# List hooks by type
./hooks_cli.sh list pre_install

# List hooks by scope
./hooks_cli.sh list "" global
```

### Execute Hooks

```bash
# Execute all pre_install hooks
./hooks_cli.sh execute pre_install

# Execute hooks for a specific module
./hooks_cli.sh execute post_module_install git

# Dry run (show what would be executed)
./hooks_cli.sh execute pre_install --dry-run

# Continue on error (don't stop if a hook fails)
./hooks_cli.sh execute pre_install --continue-on-error
```

### Validate Hooks

```bash
# Validate a specific hook
./hooks_cli.sh validate hooks/global/pre_install/system-check.sh
```

### Remove Hooks

```bash
# Remove a hook
./hooks_cli.sh remove hooks/global/pre_install/old-hook.sh
```

## Integration with Modules

The hook system is automatically integrated with the module system. When installing or uninstalling modules, the following hooks are executed:

1. `pre_module_install` - Before installing any module
2. Module's own pre-install hook (from module.yaml)
3. Module installation
4. Module's own post-install hook (from module.yaml)
5. `post_module_install` - After installing any module

## Best Practices

1. **Naming**: Use descriptive names with numeric prefixes for execution order (e.g., `00-system-check.sh`, `99-cleanup.sh`)

2. **Error Handling**: Always use `set -euo pipefail` and handle errors gracefully

3. **Logging**: Use the framework's logging functions (`log_info`, `log_error`, etc.)

4. **Idempotency**: Make hooks idempotent (safe to run multiple times)

5. **Performance**: Keep hooks fast and efficient

6. **Documentation**: Include comments explaining what the hook does

7. **Testing**: Test hooks in dry-run mode before deployment

## Troubleshooting

### Hook Not Executing

1. Check if the hook file is executable: `ls -la hooks/path/to/hook.sh`
2. Validate the hook syntax: `./hooks_cli.sh validate hooks/path/to/hook.sh`
3. Run in dry-run mode to see if it's being found: `./hooks_cli.sh execute hook_type --dry-run`

### Hook Failing

1. Check the hook's exit code and error messages
2. Verify all required environment variables are available
3. Test the hook independently: `./hooks/path/to/hook.sh`
4. Use `--continue-on-error` to see if other hooks work

### Environment Variables Not Available

1. Ensure the hook system is properly initialized
2. Check that the hook is being executed in the correct context
3. Verify the hook type matches the expected execution phase

## Security Considerations

1. **Validation**: All hooks are validated for basic security issues
2. **Permissions**: Hooks must be executable but should not be world-writable
3. **Input Sanitization**: Be careful with user input and environment variables
4. **Privilege Escalation**: Avoid running hooks with elevated privileges unless necessary

## Advanced Usage

### Custom Hook Context

You can set custom context variables for hooks:

```bash
# In your installation script
source "$DOTFILES_ROOT/core/hooks.sh"
init_hook_system

# Set custom context
set_hook_context "CUSTOM_VAR" "custom_value"

# Execute hooks with custom context
execute_hooks "pre_install"
```

### Conditional Hook Execution

Create sophisticated condition-based hooks by implementing complex logic in the `condition.sh` script:

```bash
#!/bin/bash
# condition.sh - Complex condition example
set -euo pipefail

main() {
    # Check multiple conditions
    if [[ "$PLATFORM" == "macos" ]] && [[ -d "/Applications/Docker.app" ]] && [[ -n "${WORK_ENV:-}" ]]; then
        return 0  # All conditions met
    fi
    
    return 1  # Conditions not met
}

main "$@"
```

This hook system provides a powerful and flexible way to extend the dotfiles framework with custom logic while maintaining clean separation of concerns and easy maintainability.