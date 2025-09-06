#!/usr/bin/env bash

set -euo pipefail

echo "Installing VS Code module..."

# Create VS Code User directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    mkdir -p "$HOME/Library/Application Support/Code/User"
else
    mkdir -p "$HOME/.config/Code/User"
fi

echo "VS Code module installed successfully"