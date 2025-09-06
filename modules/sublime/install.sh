#!/usr/bin/env bash

set -euo pipefail

echo "Installing Sublime Text module..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create Sublime Text User directory and copy config files
if [[ "$OSTYPE" == "darwin"* ]]; then
    TARGET_DIR="$HOME/Library/Application Support/Sublime Text 3/Packages/User"
    mkdir -p "$TARGET_DIR"
    
    # Copy all files from .subl/User to the target directory
    if [[ -d "$SCRIPT_DIR/config/common/.subl/User" ]]; then
        cp -r "$SCRIPT_DIR/config/common/.subl/User/"* "$TARGET_DIR/" 2>/dev/null || true
    fi
else
    TARGET_DIR="$HOME/.config/sublime-text-3/Packages/User"
    mkdir -p "$TARGET_DIR"
    
    # Copy all files from .subl/User to the target directory
    if [[ -d "$SCRIPT_DIR/config/common/.subl/User" ]]; then
        cp -r "$SCRIPT_DIR/config/common/.subl/User/"* "$TARGET_DIR/" 2>/dev/null || true
    fi
fi

echo "Sublime Text module installed successfully"