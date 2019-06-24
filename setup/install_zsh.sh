brew install zsh
curl -Lo ~/.install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
sh ~/.install.sh --unattended
sudo sh -c "echo $(which zsh) >> /etc/shells"
brew tap homebrew/cask-fonts
brew cask install $(brew search nerd-font | sed '1d;')
brew tap sambadevi/powerlevel9k
brew install powerlevel9k
brew install antigen
rm -fr ~/.install.sh