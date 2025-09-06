#!/usr/bin/env bash

set -euo pipefail

echo "Installing vim module..."

# Create vim directories
mkdir -p ~/.vim/{backups,swaps,undos,plugins}

# Install Vundle plugin manager
if [[ ! -d ~/.vim/plugins/Vundle.vim ]]; then
    echo "Installing Vundle plugin manager..."
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/plugins/Vundle.vim
fi

echo "Vim module installed successfully"
echo "Run ':PluginInstall' in vim to install plugins"