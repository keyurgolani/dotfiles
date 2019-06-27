#!/bin/bash

echo "Installing optional packages..."

ask_and_include "Nerd Fonts" $DIRECTORY/setup/installs/nerdfonts.sh
ask_and_include "Visual Studio Code" $DIRECTORY/setup/installs/vscode.sh
ask_and_include "IntelliJ Idea" $DIRECTORY/setup/installs/jetbrains.sh
ask_and_include "iTerm 2" $DIRECTORY/setup/installs/iterm.sh