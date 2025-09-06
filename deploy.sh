#!/bin/bash

# 🚀 Deploy - Quick alias for the main dotfiles interface
# This provides a cool, memorable entry point

exec "$(dirname "$0")/dotfiles.sh" "$@"