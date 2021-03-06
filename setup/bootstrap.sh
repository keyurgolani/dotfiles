#!/usr/bin/env bash

print_usage() {
    printf "Usage: bootstrap.sh [-i ALL|NONE]"
}

while getopts ":i:" opt; do
    case $opt in
        i)
            INSTALL="${OPTARG}"
            if [[ $INSTALL != "ALL" ]] && [[ $INSTALL != "NONE" ]]; then
                print_usage
                exit 1
            fi
        ;;
        \?)
            print_usage
            exit 1
        ;;
        :)
            print_usage
            exit 1
        ;;
    esac
done

include () {
    [[ -f "$1" ]] && source "$1"
}

ask_and_include () {
    if [ -n "$INSTALL" ]; then
        if [[ $INSTALL == "ALL" ]]; then
            echo "Installing $1"
            include $2
        fi
    else
        while true; do
            read -p "Do you wish to install $1? " yn
            case $yn in
                [Yy]* ) 
                    echo "Installing $1"
                    include $2
                    break
                    ;;
                [Nn]* ) 
                    break
                    ;;
                * ) 
                    echo "Please answer yes or no."
                    ;;
            esac
        done
    fi
}

execute() {
    echo "Setting $2"
    eval "$1"
}


export DIRECTORY=~/.dotfiles

#################################
# Obtain and Maintain Sudo		#
#################################

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `bootstrap.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


include $DIRECTORY/setup/install_developer_tools.sh
include $DIRECTORY/setup/install_homebrew.sh
include $DIRECTORY/setup/install_zsh.sh
include $DIRECTORY/setup/backup_current_dotfiles.sh
include $DIRECTORY/setup/link_dotfiles.sh
include $DIRECTORY/setup/install_preferences.sh
include $DIRECTORY/setup/install_essentials.sh
include $DIRECTORY/setup/install_binaries.sh
include $DIRECTORY/setup/install_things.sh
include $DIRECTORY/setup/cleanup.sh

sudo shutdown -r now &> /dev/null