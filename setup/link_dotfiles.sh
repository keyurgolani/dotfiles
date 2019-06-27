#!/bin/bash

echo "Linking ZSH Configuration..."

set echo off

{
    touch ~/.zshrc
    echo 'source ~/.dotfiles/source_all.sh' >> ~/.zshrc
} &> /dev/null

set echo on