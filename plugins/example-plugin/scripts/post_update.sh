#!/bin/bash

# Example Plugin Post-Update Hook
# This script runs after the plugin is updated

set -euo pipefail

echo "Running post-update hook for $PLUGIN_NAME"

# Verify installation
if [[ ! -f "$HOME/.local/bin/example-tool" ]]; then
    echo "Error: example-tool binary not found after update"
    exit 1
fi

# Test the updated tool
if ! "$HOME/.local/bin/example-tool" --version >/dev/null 2>&1; then
    echo "Error: example-tool is not working after update"
    exit 1
fi

# Migrate configuration if needed
config_file="$HOME/.config/example/config"
if [[ -f "$config_file" ]]; then
    # Check if configuration needs migration
    if ! grep -q "version = " "$config_file"; then
        echo "Migrating configuration format..."
        echo "" >> "$config_file"
        echo "[metadata]" >> "$config_file"
        echo "version = \"1.2.0\"" >> "$config_file"
        echo "updated = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" >> "$config_file"
    fi
fi

# Update shell integration
shell_integration="$HOME/.config/example/shell-integration.sh"
if [[ -f "$shell_integration" ]]; then
    echo "Shell integration updated. Please restart your shell or run:"
    echo "  source $shell_integration"
fi

# Platform-specific post-update tasks
case "$PLATFORM" in
    "macos")
        echo "macOS post-update tasks..."
        # Restart launchd services if they were running
        if [[ -f "$HOME/Library/LaunchAgents/com.example.plugin.plist" ]]; then
            echo "Restarting example plugin service..."
            launchctl load "$HOME/Library/LaunchAgents/com.example.plugin.plist" 2>/dev/null || true
        fi
        ;;
    "ubuntu"|"wsl"|"amazon-linux")
        echo "Linux post-update tasks..."
        # Restart systemd user services if they were running
        if [[ -f "$HOME/.config/systemd/user/example-plugin.service" ]]; then
            echo "Restarting example plugin service..."
            systemctl --user daemon-reload
            systemctl --user start example-plugin || true
        fi
        ;;
esac

# Show update summary
echo ""
echo "=== UPDATE SUMMARY ==="
echo "Plugin: $PLUGIN_NAME"
echo "Version: 1.2.0"
echo "Updated: $(date)"
echo "Configuration: $HOME/.config/example/"
echo "Binary: $HOME/.local/bin/example-tool"
echo ""
echo "Run 'example-tool --help' to see new features"

echo "Post-update hook completed successfully"