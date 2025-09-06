#!/bin/bash

# =============================================================================
# Module CLI Dispatcher
# =============================================================================
# Provides access to module-specific command-line utilities

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Show usage information
show_usage() {
    cat << EOF
Module CLI Dispatcher - Dotfiles Framework

USAGE:
    $0 <module> <command> [options]

AVAILABLE MODULES:
    shell               Shell configuration utilities

SHELL MODULE COMMANDS:
    install-plugins     Install optional ZSH plugins
    setup-work-aliases  Set up work-specific aliases (gitignored)
    migrate-aliases     Analyze alias migration status
    list-aliases        List all currently loaded aliases
    reload-aliases      Reload alias configurations

EXAMPLES:
    $0 shell install-plugins              # Install ZSH enhancements
    $0 shell setup-work-aliases           # Set up work aliases safely
    $0 shell list-aliases | grep git      # Find git-related aliases

QUICK ACCESS:
    For convenience, you can also run module CLIs directly:
    ./modules/shell/shell_cli.sh install-plugins

DESCRIPTION:
    This dispatcher provides unified access to module-specific utilities
    while maintaining the framework's modular architecture.

EOF
}

# Main function
main() {
    local module="${1:-}"
    local command="${2:-}"
    
    if [[ -z "$module" || "$module" == "help" || "$module" == "--help" || "$module" == "-h" ]]; then
        show_usage
        return 0
    fi
    
    # Check if module exists
    local module_dir="$DOTFILES_ROOT/modules/$module"
    if [[ ! -d "$module_dir" ]]; then
        echo "Error: Module '$module' not found"
        echo ""
        echo "Available modules:"
        ls -1 "$DOTFILES_ROOT/modules" | grep -v "^\\." | sed 's/^/  /'
        return 1
    fi
    
    # Check if module has a CLI
    local module_cli="$module_dir/${module}_cli.sh"
    if [[ ! -f "$module_cli" ]]; then
        echo "Error: Module '$module' does not have a CLI interface"
        echo "Expected: $module_cli"
        return 1
    fi
    
    # Shift to remove module name and pass remaining args to module CLI
    shift
    
    # Execute module CLI
    bash "$module_cli" "$@"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi