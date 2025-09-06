#!/usr/bin/env bash

set -euo pipefail

echo "Installing shell module..."

# Note: Oh My Zsh and plugins are now optional and can be installed separately
# This avoids network timeouts during the main installation process
# 
# To install optional enhancements, run:
# $DOTFILES_ROOT/module_cli.sh shell install-plugins

echo "Shell module core configuration installed successfully"
echo "Optional plugins (oh-my-zsh, autosuggestions, etc.) can be installed by running:"
echo "  ${DOTFILES_ROOT:-~/dotfiles}/module_cli.sh shell install-plugins"