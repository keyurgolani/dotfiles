#!/bin/bash

# Example Plugin Pre-Install Hook

echo "Running pre-install hook for: $PLUGIN_NAME"

# Check prerequisites
if ! command -v git >/dev/null 2>&1; then
    echo "Warning: git is not installed but required by this plugin"
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "Warning: curl is not installed but required by this plugin"
fi

echo "Pre-install hook completed"