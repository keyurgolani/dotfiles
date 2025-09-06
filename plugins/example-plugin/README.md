# Example Plugin

A comprehensive demonstration plugin for the Unified Dotfiles Framework that showcases all plugin system capabilities including version management, hooks, templates, cross-platform support, and third-party repository integration.

## Overview

This plugin serves as both a working example and a template for creating your own plugins. It demonstrates:

- **Complete plugin structure** with all optional components
- **Cross-platform compatibility** (macOS, Ubuntu, WSL, Amazon Linux)
- **Version management** and update capabilities
- **Template processing** with environment variables
- **Lifecycle hooks** (pre/post install, uninstall, update)
- **System service integration** (launchd, systemd)
- **Comprehensive CLI tool** with multiple commands
- **Configuration management** with platform-specific settings
- **Dependency management** (modules, plugins, system packages)
- **Logging and monitoring** capabilities

## Features

### Core Functionality

- **example-tool**: A comprehensive CLI tool demonstrating plugin capabilities
- **Configuration management**: Platform-specific and templated configurations
- **Shell integration**: Aliases, functions, and auto-completion
- **Service integration**: Optional daemon mode with system service files
- **Logging**: Comprehensive logging with rotation
- **Self-testing**: Built-in validation and health checks

### Platform Support

- **macOS**: Native integration with Homebrew, launchd services, and macOS-specific paths
- **Ubuntu**: APT package integration and systemd user services
- **WSL**: Windows Subsystem for Linux compatibility
- **Amazon Linux**: YUM/DNF package manager support

### Plugin System Features

- **Version management**: Semantic versioning with update detection
- **Dependency resolution**: Module, plugin, and system dependencies
- **Conflict detection**: Prevents installation of conflicting plugins
- **Template processing**: Dynamic configuration with environment variables
- **Hook system**: Extensible lifecycle hooks
- **Repository support**: Can be distributed through plugin repositories

## Installation

### Using the Plugin CLI

```bash
# Initialize plugin system
./plugins_cli.sh init

# Discover available plugins
./plugins_cli.sh discover

# Install the example plugin
./plugins_cli.sh install example-plugin

# Verify installation
./plugins_cli.sh info example-plugin
```

### Manual Installation

```bash
# Copy plugin to plugins directory
cp -r example-plugin ~/.dotfiles/plugins/

# Install using the framework
cd ~/.dotfiles
./plugins_cli.sh install example-plugin
```

## Usage

### CLI Tool Commands

```bash
# Show version information
example-tool version

# Show comprehensive status
example-tool status --verbose

# View configuration
example-tool config --verbose

# Run self-tests
example-tool test

# View recent logs
example-tool logs

# Update plugin data
example-tool update

# Run in daemon mode (for testing services)
example-tool daemon
```

### Configuration

The plugin creates several configuration files:

- `~/.config/example/config` - Main configuration file
- `~/.config/example/platform.conf` - Platform-specific settings
- `~/.config/example/shell-integration.sh` - Shell integration script
- `~/.config/example/plugin_info` - Installation metadata

### Shell Integration

After installation, restart your shell or source the integration script:

```bash
source ~/.config/example/shell-integration.sh
```

This provides:
- `example-config` - Edit configuration
- `example-logs` - View logs
- `example-status` - Show status
- `example_help()` - Show help function
- Auto-completion for `example-tool`

## Configuration

### Main Configuration (`~/.config/example/config`)

```ini
[general]
enabled = true
debug = false
log_level = "info"

[user]
name = "username"
email = "user@example.com"

[paths]
data = "/home/user/.local/share/example"
cache = "/home/user/.cache/example"
logs = "/home/user/.local/share/example/logs"

[metadata]
version = "1.2.0"
installed = "2024-01-01T12:00:00Z"
platform = "ubuntu"
```

### Platform-Specific Configuration

The plugin automatically creates platform-specific configuration:

- **macOS**: Uses `~/Library/` paths and integrates with launchd
- **Linux**: Uses XDG base directories and systemd user services

### Environment Variables

The plugin respects these environment variables:

- `USER_NAME` - Override user name in configuration
- `USER_EMAIL` - Override user email in configuration
- `EXAMPLE_PLUGIN_VERBOSE` - Enable verbose shell integration
- `EDITOR` - Default editor for configuration
- `BROWSER` - Default browser (Linux)

## Development

### Plugin Structure

```
example-plugin/
├── plugin.yaml              # Plugin metadata
├── install.sh               # Installation script
├── uninstall.sh             # Uninstallation script
├── README.md                # This file
├── config/                  # Configuration files
│   ├── example.conf         # Main config template
│   ├── example-macos.conf   # macOS-specific config
│   └── example-linux.conf   # Linux-specific config
├── bin/                     # Executable files
│   └── example-tool         # Main CLI tool
├── scripts/                 # Hook scripts
│   ├── pre_install.sh       # Pre-installation hook
│   ├── post_install.sh      # Post-installation hook
│   ├── pre_uninstall.sh     # Pre-uninstallation hook
│   ├── post_uninstall.sh    # Post-uninstallation hook
│   ├── pre_update.sh        # Pre-update hook
│   └── post_update.sh       # Post-update hook
└── templates/               # Template files
    └── shell-integration.sh # Shell integration template
```

### Creating Your Own Plugin

Use this plugin as a template:

1. **Copy the structure**: Use this plugin as a starting point
2. **Update metadata**: Modify `plugin.yaml` with your plugin information
3. **Customize installation**: Update `install.sh` for your specific needs
4. **Add your tools**: Replace `example-tool` with your actual tools
5. **Configure templates**: Update configuration templates
6. **Test thoroughly**: Test on all supported platforms

### Plugin Metadata (`plugin.yaml`)

Key fields to customize:

```yaml
name: "your-plugin-name"
version: "1.0.0"
description: "Your plugin description"
author:
  name: "Your Name"
  email: "your.email@example.com"
platforms:
  - "all"  # or specific platforms
categories:
  - "development"  # appropriate categories
dependencies:
  modules:
    - "shell"  # required modules
  system:
    all:
      - "curl"  # required system packages
```

## Testing

### Manual Testing

```bash
# Test installation
./plugins_cli.sh install example-plugin --dry-run

# Test the tool
example-tool test

# Test status
example-tool status --verbose

# Test configuration
example-tool config --verbose
```

### Automated Testing

The plugin includes self-tests:

```bash
example-tool test
```

This validates:
- Configuration file existence
- Binary permissions
- Directory structure
- Dependencies

## Troubleshooting

### Common Issues

1. **Plugin not found**: Ensure plugin is in the plugins directory
2. **Installation fails**: Check dependencies and permissions
3. **Tool not working**: Verify binary is executable and in PATH
4. **Configuration missing**: Re-run installation

### Debug Mode

Enable verbose logging:

```bash
export LOG_LEVEL="DEBUG"
./plugins_cli.sh install example-plugin --verbose
```

### Log Files

Check log files for issues:

```bash
# Plugin logs
example-tool logs

# Installation logs
tail ~/.dotfiles/logs/install.log

# Framework logs
tail ~/.dotfiles/logs/plugins.log
```

## Version History

### 1.2.0 (Current)
- Added comprehensive CLI tool with multiple commands
- Implemented platform-specific configurations
- Added service integration (launchd/systemd)
- Enhanced template processing
- Added update hooks and version management
- Improved logging and self-testing

### 1.0.0 (Initial)
- Basic plugin structure
- Simple installation script
- Basic configuration file
- Simple CLI tool

## Contributing

To contribute improvements to this example plugin:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms
5. Submit a pull request

## License

MIT License - see the main framework license for details.

## Support

For questions about plugin development:

- **Documentation**: See `docs/plugin-api.md`
- **Issues**: Report issues in the main framework repository
- **Examples**: This plugin serves as the primary example

## Related

- **Plugin API Documentation**: `docs/plugin-api.md`
- **Framework Documentation**: `README.md`
- **Plugin CLI**: `plugins_cli.sh`
- **Plugin System**: `core/plugins.sh`