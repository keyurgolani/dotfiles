#!/usr/bin/env bash

echo "Backing up current dotfiles configurations (if any)..."

rm -fr ~/.zshrc.backup
mv ~/.zshrc ~/.zshrc.backup