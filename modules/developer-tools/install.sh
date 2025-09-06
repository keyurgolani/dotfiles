#!/usr/bin/env bash

set -euo pipefail

echo "Installing developer tools module..."

# Install common development dependencies based on platform
case "$(uname)" in
    "Darwin")
        # macOS - use Homebrew if available
        if command -v brew >/dev/null 2>&1; then
            echo "Installing common development tools via Homebrew..."
            
            # Essential tools for dotfiles functionality
            brew install --quiet curl wget git || true
            
            # Tools for tmux functionality
            brew install --quiet tmux reattach-to-user-namespace || true
            
            # Optional but useful development tools
            brew install --quiet node npm || true
            
            echo "Homebrew packages installed"
        else
            echo "Homebrew not available, skipping package installation"
        fi
        ;;
    "Linux")
        # Linux - try common package managers
        if command -v apt-get >/dev/null 2>&1; then
            echo "Installing common development tools via apt..."
            sudo apt-get update -qq || true
            sudo apt-get install -y curl wget git tmux xclip nodejs npm || true
        elif command -v yum >/dev/null 2>&1; then
            echo "Installing common development tools via yum..."
            sudo yum install -y curl wget git tmux xclip nodejs npm || true
        elif command -v pacman >/dev/null 2>&1; then
            echo "Installing common development tools via pacman..."
            sudo pacman -S --noconfirm curl wget git tmux xclip nodejs npm || true
        else
            echo "No supported package manager found, skipping package installation"
        fi
        ;;
    *)
        echo "Unknown platform, skipping package installation"
        ;;
esac

echo "Developer tools module installed successfully"
echo "See README.md for detailed development environment setup guide"