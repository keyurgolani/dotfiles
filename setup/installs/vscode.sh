#!/usr/bin/env bash

brew cask install visual-studio-code
rm -fr ~/Library/Application\ Support/Code/User.backup
mv ~/Library/Application\ Support/Code/User ~/Library/Application\ Support/Code/User.backup
ln -s ~/.dotfiles/VSCode/* ~/Library/Application\ Support/Code/User/