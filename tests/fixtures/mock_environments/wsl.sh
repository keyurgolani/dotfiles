#!/bin/bash
# Mock WSL environment for testing

export OSTYPE="linux-gnu"
export WSL_DISTRO_NAME="Ubuntu"
export PLATFORM_OVERRIDE="wsl"

# Mock WSL-specific commands
wsl.exe() {
    case "$1" in
        "--version") echo "WSL version: 2.0.0.0" ;;
        "--list") echo "Ubuntu (Default)" ;;
        *) echo "wsl.exe $*" ;;
    esac
}

# Mock Linux commands with WSL characteristics
uname() {
    case "$1" in
        "-r") echo "5.15.90.1-microsoft-standard-WSL2" ;;
        "-a") echo "Linux hostname 5.15.90.1-microsoft-standard-WSL2 #1 SMP x86_64 GNU/Linux" ;;
        *) echo "Linux" ;;
    esac
}

# Mock apt for Ubuntu on WSL
apt() {
    echo "apt $*"
    case "$1" in
        "list") echo "git/now 1:2.34.1-1ubuntu1.9 amd64 [installed]" ;;
        "update") echo "Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease" ;;
        *) return 0 ;;
    esac
}

export -f wsl.exe uname apt