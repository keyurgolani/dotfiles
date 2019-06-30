#!/usr/bin/env bash

echo "Linking ZSH Configuration..."

set echo off

{
    touch ~/.zshrc
    echo 'source ~/.dotfiles/source_all.sh' >> ~/.zshrc
    rm -fr ~/dotfiles_overrides.backup
    mv ~/dotfiles_overrides ~/dotfiles_overrides.backup
    ln -s $DIRECTORY/dotfiles/overrides ~/dotfiles_overrides
} &> /dev/null

set echo on