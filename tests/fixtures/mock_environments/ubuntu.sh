#!/bin/bash
# Mock Ubuntu environment for testing

export OSTYPE="linux-gnu"
export PLATFORM_OVERRIDE="ubuntu"

# Mock commands
apt() {
    echo "apt $*"
    case "$1" in
        "list") echo "git/now 1:2.34.1-1ubuntu1.9 amd64 [installed]" ;;
        *) return 0 ;;
    esac
}

lsb_release() {
    case "$1" in
        "-si") echo "Ubuntu" ;;
        "-sr") echo "22.04" ;;
        "-a") echo "Distributor ID: Ubuntu\nDescription: Ubuntu 22.04.3 LTS\nRelease: 22.04\nCodename: jammy" ;;
        *) return 0 ;;
    esac
}

export -f apt lsb_release
