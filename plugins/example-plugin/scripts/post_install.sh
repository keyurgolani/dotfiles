#!/bin/bash

# Example Plugin Post-Install Hook

echo "Running post-install hook for: $PLUGIN_NAME"

# Verify installation
if [[ -f "$HOME/.config/example/plugin_info" ]]; then
    echo "✓ Plugin info file created successfully"
else
    echo "✗ Plugin info file not found"
fi

if [[ -x "$HOME/.local/bin/example-tool" ]]; then
    echo "✓ Example tool installed successfully"
else
    echo "✗ Example tool not found or not executable"
fi

echo "Post-install hook completed"