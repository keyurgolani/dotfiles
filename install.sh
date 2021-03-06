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

touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
PROD=$(softwareupdate -l |
 grep "\*.*Command Line.*$(sw_vers -productVersion|awk -F. '{print $1"."$2}')" |
 head -n 1 | awk -F"*" '{print $2}' |
 sed -e 's/^ *//' |
 tr -d '\n')
softwareupdate -i "$PROD" --verbose
rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

echo "Checking out dotfiles..."

git clone https://github.com/keyurgolani/dotfiles.git $DIRECTORY

if [ -n "$INSTALL" ]; then
    include $DIRECTORY/setup/bootstrap.sh -i $INSTALL
else
    include $DIRECTORY/setup/bootstrap.sh
fi