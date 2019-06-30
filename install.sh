#!/usr/bin/env bash

print_usage() {
    printf "Usage: install.sh [-i ALL|NONE]"
}

while getopts 'abf:v' flag; do
    case "${flag}" in
        i)
            INSTALL="${OPTARG}"
            if [[ $INSTALL != "ALL" ]] && [[ $INSTALL != "NONE" ]]; then
                print_usage
                exit 1
            fi
        ;;
        *)
            print_usage
            exit 1
        ;;
    esac
done

include () {
    [[ -f "$1" ]] && source "$1"
}

export DIRECTORY=~/.dotfiles

if [ -d "$DIRECTORY" ]; then
    # Control will enter here if $DIRECTORY exists.
    echo "$DIRECTORY already exists. Please remove."
    exit 1
fi

echo "Checking out dotfiles..."

set echo off

{
    git clone https://github.com/keyurgolani/dotfiles.git $DIRECTORY
} &> /dev/null

set echo on

if [ -n "$INSTALL" ]; then
    include $DIRECTORY/setup/bootstrap.sh -i $INSTALL
else
    include $DIRECTORY/setup/bootstrap.sh
fi