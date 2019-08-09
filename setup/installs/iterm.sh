#!/usr/bin/env bash

brew cask install iterm2
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.dotfiles/dotfiles/preferences/iterm"
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true