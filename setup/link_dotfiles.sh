#!/usr/bin/env bash

echo "Linking ZSH Configuration..."

# Link Dotfiles Overrides
rm -fr ~/dotfiles_overrides.backup
mv ~/dotfiles_overrides ~/dotfiles_overrides.backup
ln -s $DIRECTORY/dotfiles/overrides ~/dotfiles_overrides

# Link Config Overrides
rm -fr ~/config_overrides.backup
mv ~/config_overrides ~/config_overrides.backup
ln -s $DIRECTORY/dotfiles/configs ~/config_overrides

# Link ZSH Dotfiles
touch ~/.zshrc
echo 'source ~/.dotfiles/source_all.sh' >> ~/.zshrc

# Link Git Dotfiles
mv ~/.gitconfig ~/.gitconfig.backup
read -p "Full Name for Git: " git_name
git config --global user.name "$git_name"
read -p "Email for Git: " git_email
git config --global user.email "$git_email"
# TODO: Generate GPG Sign and add `user.signingkey` to config
git config --global include.path "config_overrides/git.config"