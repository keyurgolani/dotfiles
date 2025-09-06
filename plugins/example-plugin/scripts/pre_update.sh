#!/bin/bash

# Example Plugin Pre-Update Hook
# This script runs before the plugin is updated

set -euo pipefail

echo "Running pre-update hook for $PLUGIN_NAME"

# Backup current configuration before update
if [[ -f "$HOME/.config/example/config" ]]; then
    echo "Backing up current configuration..."
    cp "$HOME/.config/example/config" "$HOME/.config/example/config.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Check if any processes are using the plugin
if pgrep -f "example-tool" >/dev/null 2>&1; then
    echo "Warning: example-tool processes are running. Consider stopping them before update."
    echo "Running processes:"
    pgrep -f "example-tool" | while read -r pid; do
        ps -p "$pid" -o pid,cmd --no-headers || true
    done
fi

# Validate current installation
if [[ ! -f "$HOME/.local/bin/example-tool" ]]; then
    echo "Warning: example-tool binary not found. This might be a fresh installation."
fi

# Platform-specific pre-update tasks
case "$PLATFORM" in
    "macos")
        echo "macOS pre-update tasks..."
        # Stop any launchd services if they exist
        if launchctl list | grep -q "com.example.plugin"; then
            echo "Stopping example plugin service..."
            launchctl unload "$HOME/Library/LaunchAgents/com.example.plugin.plist" 2>/dev/null || true
        fi
        ;;
    "ubuntu"|"wsl"|"amazon-linux")
        echo "Linux pre-update tasks..."
        # Stop any systemd user services if they exist
        if systemctl --user is-active example-plugin >/dev/null 2>&1; then
            echo "Stopping example plugin service..."
            systemctl --user stop example-plugin || true
        fi
        ;;
esac

echo "Pre-update hook completed successfully"