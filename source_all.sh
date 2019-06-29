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

include () {
    [[ -f "$1" ]] && source "$1"
}

export DIRECTORY=~/.dotfiles

for f in $DIRECTORY/dotfiles/*.import; do include $f; done