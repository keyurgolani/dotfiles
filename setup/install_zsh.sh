#!/usr/bin/env bash

echo "Installing ZSH and related packages..."

set echo off

{
    brew install zsh
    curl -Lo ~/.install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
    sh ~/.install.sh --unattended
    sudo sh -c "echo $(which zsh) >> /etc/shells"
    brew tap sambadevi/powerlevel9k
    brew install powerlevel9k
    brew install antigen
    rm -fr ~/.install.sh
} &> /dev/null

set echo on