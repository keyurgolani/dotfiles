#!/usr/bin/env bash

set -euo pipefail

echo "Installing homebrew module..."

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew (this may take a few minutes)..."
    if CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        echo "Homebrew installed successfully"
    else
        echo "Warning: Homebrew installation failed or was interrupted"
        echo "You can install it manually later by running:"
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi
fi

# Update Homebrew (skip if it takes too long)
echo "Updating Homebrew..."
if timeout 300 brew update 2>/dev/null; then
    echo "Homebrew updated successfully"
    # Only upgrade if update succeeded and we have time
    echo "Upgrading existing packages (this may take a while)..."
    timeout 600 brew upgrade 2>/dev/null || echo "Package upgrade timed out or failed (this is normal)"
else
    echo "Homebrew update timed out (this is normal on slow connections)"
    echo "You can update manually later with: brew update && brew upgrade"
fi

echo "Homebrew module installed successfully"