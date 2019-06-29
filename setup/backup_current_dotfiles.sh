#!/bin/bash

echo "Backing up current dotfiles configurations (if any)..."

set echo off

{
    rm -fr ~/.zshrc.backup
    mv ~/.zshrc ~/.zshrc.backup
} &> /dev/null

set echo on