#!/usr/bin/env bash

echo "Updating dotfiles..."

cd ~/.dotfiles
git stash
git pull --rebase
git stash pop
cd -

include () {
    [[ -f "$1" ]] && source "$1"
}

export DIRECTORY=~/.dotfiles

for f in $DIRECTORY/dotfiles/*.import; do include $f; done