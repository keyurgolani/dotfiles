#!/usr/bin/env bash

set -euo pipefail

echo "Installing iTerm module..."

# Create iTerm2 DynamicProfiles directory
mkdir -p "$HOME/Library/Application Support/iTerm2/DynamicProfiles"

echo "iTerm module installed successfully"
echo "Restart iTerm2 to apply the new profile"