#!/bin/bash

# Fix common shell script issues for CI/CD compatibility

set -e

echo "🔧 Fixing common shell script issues..."

# Find all shell scripts
SHELL_SCRIPTS=$(find . -name "*.sh" -not -path "./.git/*" -not -path "./tests/helpers/bats-*")

FIXED_COUNT=0

for script in $SHELL_SCRIPTS; do
    echo "Checking: $script"
    
    # Make sure script is executable
    if [ ! -x "$script" ]; then
        echo "  Making executable: $script"
        chmod +x "$script"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    fi
    
    # Check for basic syntax
    if ! bash -n "$script" 2>/dev/null; then
        echo "  ❌ Syntax error in: $script"
    else
        echo "  ✅ Syntax OK: $script"
    fi
done

echo "🎉 Fixed $FIXED_COUNT shell script issues"