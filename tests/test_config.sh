#!/bin/bash

# Test configuration for unified dotfiles framework

# Test environment variables
export TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT="$(dirname "$TEST_ROOT")"
export TEST_FIXTURES_DIR="$TEST_ROOT/fixtures"
export TEST_TEMP_DIR="${TMPDIR:-/tmp}/dotfiles_test_$$"

# Test-specific overrides
export DOTFILES_BACKUP_DIR="$TEST_TEMP_DIR/backups"
export DOTFILES_CONFIG_DIR="$TEST_FIXTURES_DIR/configs"
export DOTFILES_LOG_LEVEL="DEBUG"

# Create test temp directory
mkdir -p "$TEST_TEMP_DIR"

# Cleanup function for tests
cleanup_test_env() {
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Trap cleanup on exit
trap cleanup_test_env EXIT
