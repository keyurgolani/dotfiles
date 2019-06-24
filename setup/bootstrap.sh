include () {
    [[ -f "$1" ]] && source "$1"
}

export DIRECTORY=~/.dotfiles


include $DIRECTORY/setup/install_homebrew.sh
include $DIRECTORY/setup/install_zsh.sh
include $DIRECTORY/setup/backup_current_dotfiles.sh
include $DIRECTORY/setup/link_dotfiles.sh
include $DIRECTORY/setup/install_essentials.sh