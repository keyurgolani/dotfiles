#!/usr/bin/env bash

echo "Installing essential packages..."

set echo off

{
    xcode-select --install
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    brew install ruby
    export PATH="/usr/local/opt/ruby/bin:$PATH"
    export LDFLAGS="-L/usr/local/opt/ruby/lib"
    export CPPFLAGS="-I/usr/local/opt/ruby/include"
    brew install autojump
    brew install tmux
    brew install go
    brew install apache2
    brew install tmux-xpanes
    gem install tmuxinator
    brew install tmuxinator-completion
    brew install python
    brew install mas
    pip3 install virtualenvwrapper
    brew install icdiff     # Reference: https://www.jefftk.com/icdiff
    brew install interactive-rebase-tool        # https://gitrebasetool.mitmaro.ca/
} &> /dev/null

set echo on