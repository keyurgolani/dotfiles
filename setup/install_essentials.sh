#!/usr/bin/env bash

echo "Installing essential packages..."

brew install ruby
export PATH="/usr/local/opt/ruby/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/ruby/lib"
export CPPFLAGS="-I/usr/local/opt/ruby/include"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
brew install autojump
brew install vim -- --with-override-system-vi
brew install tmux
brew install reattach-to-user-namespace
brew install go
brew install apache2
brew install tmux-xpanes
gem install colorls
ln $(dirname $(dirname $(gem which colorls)))/exe/colorls /usr/local/bin/colorls
gem install tmuxinator
brew install tmuxinator-completion
brew install python
brew install mas
brew install tldr
brew install https://raw.github.com/gleitz/howdoi/master/howdoi.rb  # Reference: https://github.com/gleitz/howdoi
pip3 install virtualenvwrapper
brew install icdiff                  # Reference: https://www.jefftk.com/icdiff
brew install interactive-rebase-tool # https://gitrebasetool.mitmaro.ca/