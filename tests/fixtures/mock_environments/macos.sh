#!/bin/bash
# Mock macOS environment for testing

export OSTYPE="darwin"
export PLATFORM_OVERRIDE="macos"

# Mock commands
brew() {
    echo "brew $*"
    case "$1" in
        "--version") echo "Homebrew 4.0.0" ;;
        "list") echo "git\nvim\ntmux" ;;
        *) return 0 ;;
    esac
}

sw_vers() {
    case "$1" in
        "-productVersion") echo "13.0.0" ;;
        "-productName") echo "macOS" ;;
        *) echo "ProductName: macOS\nProductVersion: 13.0.0" ;;
    esac
}

export -f brew sw_vers
