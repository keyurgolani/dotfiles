datauri() {

    local mimeType=""

    if [ -f "$1" ]; then
        mimeType=$(file -b --mime-type "$1")
        #                └─ do not prepend the filename to the output

        if [[ $mimeType == text/* ]]; then
            mimeType="$mimeType;charset=utf-8"
        fi

        printf "data:%s;base64,%s" \
                    "$mimeType" \
                    "$(openssl base64 -in "$1" | tr -d "\n")"
    else
        printf "%s is not a file.\n" "$1"
    fi

}

# Delete files that match a certain pattern from the current directory.

delete-files() {
    local q="${1:-*.DS_Store}"
    find . -type f -name "$q" -ls -delete
}

# Create new directories and enter the first one.

mkcd() {
    if [ -n "$*" ]; then

        mkdir -p "$@"
        #      └─ make parent directories if needed

        cd "$@" \
            || exit 1

    fi
}

# Search history.

hist-find() {
    #           ┌─ enable colors for pipe
    #           │  ("--color=auto" enables colors only if
    #           │  the output is in the terminal)
    grep --color=always "$*" "$HISTFILE" |       less -RX
    # display ANSI color escape sequences in raw form ─┘│
    #       don't clear the screen after quitting less ─┘
}

# Search for text within the current directory.

find-pwd() {
    grep -ir --color=always "$*" --exclude-dir=".git" --exclude-dir="node_modules" . | less -RX
    #     │└─ search all files under each directory, recursively
    #     └─ ignore case
}

# Make the cd command output the files inside target directory

function cd {
    builtin cd "$@" && ls
}

function sshtunnel() {
    ssh -L $1:127.0.0.1:$1 golani.aka.corp.amazon.com
}

function cache_refresh() {
    brazil-package-cache clean
    brazil-package-cache disable_edge_cache
    brazil-package-cache stop
    brazil-package-cache start
}

function remove_ws_package() {
    cd ~/workplace/$1 && brazil ws remove --package $2 && cd -;
}

function crd() {
    cr -o --description="# Overview

## $(basename $(pwd))

### $(git log -1 --pretty=%B)

# Testing

- \`brazil-build\`

# Other notes

- N/A
" $*
}