#!/usr/bin/env bash

brew tap dteoh/sqa
brew cask install slowquitapps

defaults write com.dteoh.SlowQuitApps delay -int 1500

# Check this for more info: https://github.com/dteoh/SlowQuitApps