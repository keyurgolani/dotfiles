brew tap homebrew/cask-fonts
brew cask install $(brew search nerd-font | sed '1d;')