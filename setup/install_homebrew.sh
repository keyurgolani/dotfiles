#!/usr/bin/env bash

echo "Installing homebrew for package management..."

set echo off

{
    # Check to see if Homebrew is installed, and install it if it is not
    command -v brew >/dev/null 2>&1 || { echo >&2 "Installing Homebrew Now"; \
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; }
} &> /dev/null

set echo on