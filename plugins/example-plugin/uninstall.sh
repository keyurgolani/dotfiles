#!/bin/bash

# Example Plugin Uninstallation Script

set -euo pipefail

echo "Uninstalling example plugin: $PLUGIN_NAME"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "[DRY RUN] Would perform plugin uninstallation steps"
    exit 0
fi

# Remove plugin-specific files
rm -f "$HOME/.config/example/plugin_info"

# Remove directories if empty
rmdir "$HOME/.config/example" 2>/dev/null || true

echo "Example plugin uninstalled successfully"