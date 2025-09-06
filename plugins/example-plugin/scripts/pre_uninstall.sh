#!/bin/bash

# Example Plugin Pre-Uninstall Hook

echo "Running pre-uninstall hook for: $PLUGIN_NAME"

# Backup user data if needed
if [[ -f "$HOME/.config/example/user_data" ]]; then
    echo "Backing up user data..."
    cp "$HOME/.config/example/user_data" "$HOME/.config/example/user_data.backup"
fi

echo "Pre-uninstall hook completed"