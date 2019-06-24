cd ~/.dotfiles
git stash
git pull --rebase
git stash pop
cd -

for f in ~/.dotfiles/dotfiles/*.import; do source $f; done