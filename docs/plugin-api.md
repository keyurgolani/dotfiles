# Plugin API Documentation

## Overview

The Unified Dotfiles Framework provides a comprehensive plugin system that allows developers to create and distribute custom configurations and tools. This document describes the Plugin API and how to create, distribute, and manage plugins.

## Plugin API Version

Current API Version: **1.0.0**

The plugin API follows semantic versioning. Plugins must specify a compatible API version in their `plugin.yaml` file.

## Plugin Structure

A plugin is a directory containing the following files:

```
my-plugin/
├── plugin.yaml          # Plugin metadata (required)
├── install.sh           # Installation script (required)
├── uninstall.sh         # Uninstallation script (optional)
├── config/              # Configuration files
│   ├── common/          # Cross-platform configurations
│   └── macos/           # Platform-specific configurations
├── scripts/             # Hook scripts
│   ├── pre_install.sh   # Pre-installation hook
│   ├── post_install.sh  # Post-installation hook
│   ├── pre_uninstall.sh # Pre-uninstallation hook
│   └── post_uninstall.sh# Post-uninstallation hook
├── templates/           # Template files
├── bin/                 # Executable files
└── README.md           # Plugin documentation
```

## Plugin Metadata (plugin.yaml)

The `plugin.yaml` file contains all plugin metadata and configuration:

```yaml
name: "my-plugin"
version: "1.0.0"
description: "A sample plugin demonstrating the plugin system"
api_version: "1.0.0"

author:
  name: "Your Name"
  email: "your.email@example.com"
  url: "https://github.com/yourusername"

license: "MIT"
homepage: "https://github.com/yourusername/my-plugin"
repository: "https://github.com/yourusername/my-plugin.git"

platforms:
  - "all"  # or specific: ["macos", "ubuntu", "wsl", "amazon-linux"]

categories:
  - "development"
  - "productivity"

dependencies:
  modules:
    - "shell"
    - "git"
  plugins:
    - "another-plugin"
  system:
    all:
      - "curl"
      - "git"
    macos:
      - "brew"
    ubuntu:
      - "apt-transport-https"

conflicts:
  - "conflicting-plugin"

hooks:
  pre_install: "scripts/pre_install.sh"
  post_install: "scripts/post_install.sh"
  pre_uninstall: "scripts/pre_uninstall.sh"
  post_uninstall: "scripts/post_uninstall.sh"
  pre_update: "scripts/pre_update.sh"
  post_update: "scripts/post_update.sh"

configuration:
  priority: 50        # Installation priority (0-100)
  interactive: false  # Requires user interaction

files:
  - source: "config/myconfig.conf"
    target: "~/.config/myapp/config"
    template: true
    executable: false
    backup: true
    platforms: ["all"]
  - source: "bin/mytool"
    target: "~/.local/bin/mytool"
    executable: true
    backup: true
```

### Required Fields

- `name`: Plugin name (lowercase, alphanumeric, hyphens, underscores)
- `version`: Semantic version (e.g., 1.0.0, 1.0.0-beta)
- `description`: Plugin description (minimum 10 characters)
- `api_version`: Plugin API version (must be compatible with framework)
- `platforms`: Supported platforms array

### Optional Fields

- `author`: Author information (name, email, url)
- `license`: Plugin license
- `homepage`: Plugin homepage URL
- `repository`: Plugin repository URL
- `categories`: Plugin categories for organization
- `dependencies`: Required modules, plugins, and system packages
- `conflicts`: Conflicting plugins or modules
- `hooks`: Lifecycle hook scripts
- `configuration`: Plugin configuration options
- `files`: Files to install

## Installation Script (install.sh)

The `install.sh` script is executed during plugin installation. It must be executable and should handle the main installation logic.

### Environment Variables

The following environment variables are available during script execution:

- `PLUGIN_NAME`: Name of the plugin being installed
- `PLUGIN_DIR`: Path to the plugin directory
- `DOTFILES_ROOT`: Path to the dotfiles framework root
- `PLATFORM`: Current platform (macos, ubuntu, wsl, amazon-linux)
- `PLUGIN_API_VERSION`: Plugin API version

### Example install.sh

```bash
#!/bin/bash

set -euo pipefail

echo "Installing $PLUGIN_NAME..."

# Platform-specific installation
case "$PLATFORM" in
    "macos")
        echo "Installing on macOS"
        # macOS-specific installation logic
        ;;
    "ubuntu")
        echo "Installing on Ubuntu"
        # Ubuntu-specific installation logic
        ;;
    *)
        echo "Installing on $PLATFORM"
        # Generic installation logic
        ;;
esac

# Create necessary directories
mkdir -p "$HOME/.config/myapp"

# Install configuration files (handled by framework)
echo "Configuration files will be installed by the framework"

# Install additional components
if command -v npm >/dev/null 2>&1; then
    npm install -g my-tool
fi

echo "$PLUGIN_NAME installed successfully"
```

## Uninstallation Script (uninstall.sh)

The optional `uninstall.sh` script handles plugin removal:

```bash
#!/bin/bash

set -euo pipefail

echo "Uninstalling $PLUGIN_NAME..."

# Remove installed components
if command -v npm >/dev/null 2>&1; then
    npm uninstall -g my-tool 2>/dev/null || true
fi

# Clean up directories
rm -rf "$HOME/.config/myapp"

echo "$PLUGIN_NAME uninstalled successfully"
```

## Hook Scripts

Hook scripts are executed at specific points during the plugin lifecycle:

### Pre-install Hook (scripts/pre_install.sh)

Executed before plugin installation begins:

```bash
#!/bin/bash

echo "Pre-install hook for $PLUGIN_NAME"

# Check prerequisites
if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required but not installed"
    exit 1
fi

# Prepare environment
mkdir -p "$HOME/.local/bin"
```

### Post-install Hook (scripts/post_install.sh)

Executed after plugin installation completes:

```bash
#!/bin/bash

echo "Post-install hook for $PLUGIN_NAME"

# Configure installed tools
if [[ -f "$HOME/.config/myapp/config" ]]; then
    echo "Configuring myapp..."
    # Configuration logic
fi

# Add to shell PATH if needed
if [[ -d "$HOME/.local/bin" ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
```

## File Installation

The framework handles file installation based on the `files` section in `plugin.yaml`:

### File Properties

- `source`: Source file path relative to plugin directory
- `target`: Target installation path (supports ~ expansion)
- `template`: Process file as template (default: false)
- `executable`: Make file executable (default: false)
- `backup`: Backup existing file (default: true)
- `platforms`: Platform compatibility (default: all)

### Template Processing

Files marked with `template: true` are processed with environment variable substitution:

```bash
# config/myconfig.conf.template
[user]
name = ${USER_NAME:-$(whoami)}
email = ${USER_EMAIL:-user@example.com}

[paths]
home = ${HOME}
config = ${HOME}/.config/myapp
```

## Plugin Categories

Plugins can be categorized for better organization:

- `shell`: Shell configurations and tools
- `editor`: Editor configurations (vim, emacs, etc.)
- `vcs`: Version control systems (git, svn, etc.)
- `development`: Development tools and environments
- `productivity`: Productivity tools and utilities
- `system`: System administration tools
- `security`: Security tools and configurations
- `other`: Other plugins

## Dependencies

### Module Dependencies

Plugins can depend on framework modules:

```yaml
dependencies:
  modules:
    - "shell"
    - "git"
    - "vim"
```

### Plugin Dependencies

Plugins can depend on other plugins:

```yaml
dependencies:
  plugins:
    - "base-tools"
    - "shell-extensions"
```

### System Dependencies

Plugins can specify system package dependencies:

```yaml
dependencies:
  system:
    all:
      - "curl"
      - "git"
    macos:
      - "brew"
    ubuntu:
      - "apt-transport-https"
      - "ca-certificates"
    wsl:
      - "wslu"
    amazon-linux:
      - "yum-utils"
```

## Plugin Repositories

Plugins can be distributed through repositories. The framework supports multiple repository types:

### Repository Configuration

```yaml
# config/plugin_repositories.yaml
repositories:
  - name: "official"
    url: "https://github.com/dotfiles-framework/plugins.git"
    branch: "main"
    enabled: true
    trusted: true
    description: "Official dotfiles framework plugins"
  
  - name: "community"
    url: "https://github.com/dotfiles-community/plugins.git"
    branch: "main"
    enabled: true
    trusted: false
    description: "Community contributed plugins"
```

### Repository Structure

A plugin repository should have the following structure:

```
plugins-repo/
├── plugin1/
│   ├── plugin.yaml
│   ├── install.sh
│   └── ...
├── plugin2/
│   ├── plugin.yaml
│   ├── install.sh
│   └── ...
└── README.md
```

## Plugin Management Commands

### Discovery and Listing

```bash
# Initialize plugin system
./plugins_cli.sh init

# Discover plugins from all sources
./plugins_cli.sh discover

# List all plugins
./plugins_cli.sh list

# List only installed plugins
./plugins_cli.sh list installed

# List only available plugins
./plugins_cli.sh list available
```

### Search and Information

```bash
# Search plugins by name, description, or category
./plugins_cli.sh search "shell"

# Show detailed plugin information
./plugins_cli.sh info my-plugin
```

### Installation and Management

```bash
# Install a plugin
./plugins_cli.sh install my-plugin

# Install with dry-run (preview changes)
./plugins_cli.sh install my-plugin --dry-run

# Force reinstall
./plugins_cli.sh install my-plugin --force

# Uninstall a plugin
./plugins_cli.sh uninstall my-plugin

# Update a specific plugin
./plugins_cli.sh update my-plugin

# Update all plugins
./plugins_cli.sh update
```

### Repository Management

```bash
# List repositories
./plugins_cli.sh repos list

# Add a repository
./plugins_cli.sh repos add myrepo https://github.com/user/plugins.git

# Update repository cache
./plugins_cli.sh repos update

# Update specific repository
./plugins_cli.sh repos update myrepo
```

### Export and Import

```bash
# Export plugin configuration
./plugins_cli.sh export my-plugins.yaml

# Import plugin configuration
./plugins_cli.sh import my-plugins.yaml
```

### Maintenance

```bash
# Show plugin system status
./plugins_cli.sh status

# Clean plugin cache
./plugins_cli.sh clean all

# Clean only repository cache
./plugins_cli.sh clean repositories
```

## Best Practices

### Plugin Development

1. **Follow naming conventions**: Use lowercase names with hyphens
2. **Provide comprehensive metadata**: Include description, author, license
3. **Support multiple platforms**: Test on different operating systems
4. **Handle errors gracefully**: Use proper error handling in scripts
5. **Document your plugin**: Include a detailed README.md
6. **Version your plugin**: Use semantic versioning
7. **Test thoroughly**: Test installation, uninstallation, and updates

### Security Considerations

1. **Validate inputs**: Sanitize user inputs and file paths
2. **Use secure downloads**: Verify checksums and signatures
3. **Set proper permissions**: Use appropriate file permissions
4. **Avoid hardcoded secrets**: Don't include credentials in plugins
5. **Review dependencies**: Audit third-party dependencies

### Performance

1. **Minimize startup impact**: Avoid heavy operations in shell configs
2. **Use caching**: Cache expensive operations when possible
3. **Parallel installation**: Design for concurrent installation
4. **Clean up resources**: Remove temporary files and processes

## Plugin Schema Validation

The framework validates plugins against a JSON schema. You can validate your plugin manually:

```bash
# Validate plugin.yaml against schema
yq eval '.' my-plugin/plugin.yaml | \
  jsonschema -i /dev/stdin schemas/plugin.schema.json
```

## Troubleshooting

### Common Issues

1. **Plugin not found**: Check plugin name and repository configuration
2. **Installation fails**: Check dependencies and system requirements
3. **Permission errors**: Ensure proper file permissions
4. **API version mismatch**: Update plugin to compatible API version
5. **Dependency conflicts**: Resolve conflicting plugins or modules

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
./plugins_cli.sh install my-plugin --verbose
```

### Log Files

Plugin operations are logged to:
- `~/.dotfiles/logs/plugins.log`
- `~/.dotfiles/logs/install.log`

## Examples

See the `plugins/example-plugin/` directory for a complete plugin example.

## Contributing

To contribute plugins to the official repository:

1. Fork the plugins repository
2. Create your plugin following this API
3. Test thoroughly on supported platforms
4. Submit a pull request with documentation
5. Follow the code review process

## Support

For plugin development support:
- Documentation: https://github.com/dotfiles-framework/unified-dotfiles/docs
- Issues: https://github.com/dotfiles-framework/unified-dotfiles/issues
- Discussions: https://github.com/dotfiles-framework/unified-dotfiles/discussions