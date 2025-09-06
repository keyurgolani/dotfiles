# Test zshrc configuration
export PATH="/usr/local/bin:$PATH"

# Aliases
alias ll='ls -la'
alias grep='grep --color=auto'

# Functions
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Prompt
PS1='%n@%m:%~$ '