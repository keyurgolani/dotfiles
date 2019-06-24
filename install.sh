include () {
    [[ -f "$1" ]] && source "$1"
}

export DIRECTORY=~/.dotfiles

if [ -d "$DIRECTORY" ]; then
  # Control will enter here if $DIRECTORY exists.
  echo "$DIRECTORY already exists. Please remove."
  exit 1
fi

git clone https://github.com/keyurgolani/dotfiles.git $DIRECTORY

include $DIRECTORY/setup/bootstrap.sh