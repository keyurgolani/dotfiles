#!/bin/bash

# Example Plugin Post-Uninstall Hook

echo "Running post-uninstall hook for: $PLUGIN_NAME"

# Clean up any remaining files
rm -f "$HOME/.config/example/user_data.backup" 2>/dev/null || true

echo "Post-uninstall hook completed"
echo "Plugin $PLUGIN_NAME has been completely removed"