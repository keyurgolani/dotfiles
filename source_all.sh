#!/bin/bash

echo "Updating dotfiles..."

set echo off

{
    cd ~/.dotfiles
    git stash
    git pull --rebase
    git stash pop
    cd -
} &> /dev/null

set echo on

for f in ~/.dotfiles/dotfiles/*.import; do source $f; done