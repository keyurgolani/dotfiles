#!/usr/bin/env bash

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Lock screen.

alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Shorter commands for `Homebrew`.

alias brewd="brew doctor"
alias brewi="brew install"
alias brewr="brew uninstall"
alias brews="brew search"
alias brewu="brew update \
                && brew upgrade \
                && brew cleanup"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear DNS cache.

alias clear-dns-cache="sudo dscacheutil -flushcache; \
                       sudo killall -HUP mDNSResponder"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Empty the trash, the main HDD and on all mounted volumes,
# and clear Apple’s system logs to improve shell startup speed.

alias empty-trash="sudo rm -frv /Volumes/*/.Trashes; \
                   sudo rm -frv ~/.Trash; \
                   sudo rm -frv /private/var/log/asl/*.asl; \
                   sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Hide/Show desktop icons.

alias hide-desktop-icons="defaults write com.apple.finder CreateDesktop -bool false \
                            && killall Finder"

alias show-desktop-icons="defaults write com.apple.finder CreateDesktop -bool true \
                            && killall Finder"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Get local IP.

alias local-ip="ipconfig getifaddr en1"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Open from the terminal.

alias o="open"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Update applications and CLTs.

alias u="sudo softwareupdate --install --all \
            && brew update \
            && brew upgrade \
            && brew cleanup \
            && npm install -g npm \
            && npm update -g"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias cd..="cd .."

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

alias :q="exit"
alias c="clear"
alias ch="history -c && > ~/.bash_history"
alias e="vim --"
alias g="git"
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias ll="ls -l"
alias m="man"
alias map="xargs -n1"
alias n="npm"
alias path='printf "%b\n" "${PATH//:/\\n}"'
alias q="exit"
alias rm="rm -rf --"
alias t="tmux"
alias y="yarn"

alias sourceall="source ~/.zshrc"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Get list of currently open ports
alias ports="netstat -tupln"

alias f="find . -type f -follow -name "
alias g="find . -type f -follow | xargs grep"

alias ls="colorls --group-directories-first"


##################### Your DevDesktop Alias ###################
alias golani="ssh golani.aka.corp.amazon.com"
alias devdesk="golani"
alias sshdev="golani"