#!/bin/bash
# Mock Amazon Linux 2 environment for testing

export OSTYPE="linux-gnu"
export PLATFORM_ID="amzn"
export PLATFORM_OVERRIDE="amazon-linux"

# Mock Amazon Linux specific commands
yum() {
    echo "yum $*"
    case "$1" in
        "list") echo "git.x86_64 2.39.3-1.amzn2.0.1 @amzn2-core" ;;
        "update") echo "Loaded plugins: extras_suggestions, langpacks, priorities, update-motd" ;;
        *) return 0 ;;
    esac
}

dnf() {
    echo "dnf $*"
    case "$1" in
        "list") echo "git.x86_64 2.39.3-1.amzn2.0.1 @amzn2-core" ;;
        "update") echo "Amazon Linux 2 repository" ;;
        *) return 0 ;;
    esac
}

# Mock system info commands
cat() {
    if [[ "$1" == "/etc/os-release" ]]; then
        echo 'NAME="Amazon Linux"'
        echo 'VERSION="2"'
        echo 'ID="amzn"'
        echo 'ID_LIKE="centos rhel fedora"'
        echo 'VERSION_ID="2"'
        echo 'PRETTY_NAME="Amazon Linux 2"'
    else
        command cat "$@"
    fi
}

lsb_release() {
    case "$1" in
        "-si") echo "Amazon" ;;
        "-sr") echo "2" ;;
        "-a") echo "Distributor ID: Amazon\nDescription: Amazon Linux 2\nRelease: 2" ;;
        *) return 0 ;;
    esac
}

export -f yum dnf cat lsb_release