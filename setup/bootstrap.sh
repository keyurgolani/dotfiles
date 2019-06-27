#!/bin/bash

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
            set echo off
            include $2 &> /dev/null
            set echo on
        fi
    else
        while true; do
            read -p "Do you wish to install $1? " yn
            case $yn in
                [Yy]* ) echo "Installing $1"; set echo off; include $2 &> /dev/null; set echo on; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

export DIRECTORY=~/.dotfiles


include $DIRECTORY/setup/install_homebrew.sh
include $DIRECTORY/setup/install_zsh.sh
include $DIRECTORY/setup/backup_current_dotfiles.sh
include $DIRECTORY/setup/link_dotfiles.sh
include $DIRECTORY/setup/install_essentials.sh
include $DIRECTORY/setup/install_things.sh