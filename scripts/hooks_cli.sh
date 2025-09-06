#!/bin/bash

# Hook Management CLI for Unified Dotfiles Framework
# Provides command-line interface for managing hooks

set -euo pipefail

# Script directory and core dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export DOTFILES_ROOT

# Source core modules
source "$DOTFILES_ROOT/core/logger.sh"
source "$DOTFILES_ROOT/core/utils.sh"
source "$DOTFILES_ROOT/core/hooks.sh"

# CLI configuration
readonly PROGRAM_NAME="hooks_cli"
readonly VERSION="1.0.0"

# Display usage information
show_usage() {
    cat << EOF
$PROGRAM_NAME - Hook Management CLI for Unified Dotfiles Framework

USAGE:
    $PROGRAM_NAME <command> [options]

COMMANDS:
    init                    Initialize hook system
    list [type] [scope]     List available hooks
    create <type> <name> <scope> [target]
                           Create a new hook
    remove <hook_file>      Remove a hook
    execute <type> [module] [--dry-run] [--continue-on-error]
                           Execute hooks for a specific type
    validate <hook_file>    Validate a hook script
    help                    Show this help message

HOOK TYPES:
    pre_install, post_install, pre_uninstall, post_uninstall,
    pre_backup, post_backup, pre_restore, post_restore,
    pre_module_install, post_module_install, pre_module_uninstall,
    post_module_uninstall, override_applied, config_loaded, platform_detected

HOOK SCOPES:
    global                  Global hooks (apply to all operations)
    module <name>           Module-specific hooks
    environment <name>      Environment-specific hooks (work, personal, etc.)
    platform <name>         Platform-specific hooks (macos, ubuntu, etc.)
    condition <name>        Condition-based hooks

EXAMPLES:
    $PROGRAM_NAME init
    $PROGRAM_NAME list
    $PROGRAM_NAME list pre_install global
    $PROGRAM_NAME create pre_install backup-check global
    $PROGRAM_NAME create post_install setup-aliases module git
    $PROGRAM_NAME create pre_install work-vpn environment work
    $PROGRAM_NAME execute pre_install --dry-run
    $PROGRAM_NAME execute post_module_install git
    $PROGRAM_NAME validate hooks/global/pre_install/system-check.sh
    $PROGRAM_NAME remove hooks/global/pre_install/old-hook.sh

OPTIONS:
    --dry-run              Show what would be executed without running
    --continue-on-error    Continue execution even if some hooks fail
    --verbose              Enable verbose output
    --quiet                Suppress non-error output
    --help                 Show this help message
    --version              Show version information

EOF
}

# Display version information
show_version() {
    echo "$PROGRAM_NAME version $VERSION"
    echo "Unified Dotfiles Framework Hook Management CLI"
}

# Parse command line arguments
parse_arguments() {
    local command=""
    local args=()
    local dry_run=false
    local continue_on_error=false
    local verbose=false
    local quiet=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --continue-on-error)
                continue_on_error=true
                shift
                ;;
            --verbose)
                verbose=true
                export LOG_LEVEL="DEBUG"
                shift
                ;;
            --quiet)
                quiet=true
                export LOG_LEVEL="ERROR"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$command" ]]; then
                    command="$1"
                else
                    args+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    # Export options for use by functions
    export CLI_DRY_RUN="$dry_run"
    export CLI_CONTINUE_ON_ERROR="$continue_on_error"
    export CLI_VERBOSE="$verbose"
    export CLI_QUIET="$quiet"
    
    # Execute command
    case "$command" in
        "init")
            cmd_init "${args[@]+"${args[@]}"}"
            ;;
        "list")
            cmd_list "${args[@]+"${args[@]}"}"
            ;;
        "create")
            cmd_create "${args[@]+"${args[@]}"}"
            ;;
        "remove")
            cmd_remove "${args[@]+"${args[@]}"}"
            ;;
        "execute")
            cmd_execute "${args[@]+"${args[@]}"}"
            ;;
        "validate")
            cmd_validate "${args[@]+"${args[@]}"}"
            ;;
        "help")
            show_usage
            ;;
        "")
            log_error "No command specified"
            show_usage
            exit 1
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Initialize hook system
cmd_init() {
    log_info "Initializing hook system..."
    
    if init_hook_system; then
        log_success "Hook system initialized successfully!"
        
        # Show directory structure
        echo
        echo "Hook directory structure created:"
        echo "================================"
        find "$DOTFILES_ROOT/hooks" -type d | sort | sed 's|^|  |'
        
        echo
        echo "You can now create hooks using:"
        echo "  $PROGRAM_NAME create <type> <name> <scope> [target]"
        echo
        echo "Example:"
        echo "  $PROGRAM_NAME create pre_install system-check global"
    else
        log_error "Failed to initialize hook system"
        exit 1
    fi
}

# List hooks
cmd_list() {
    local hook_type="${1:-}"
    local hook_scope="${2:-}"
    
    log_info "Listing hooks..."
    
    if ! init_hook_system; then
        log_error "Failed to initialize hook system"
        exit 1
    fi
    
    list_hooks "$hook_type" "$hook_scope"
}

# Create new hook
cmd_create() {
    if [[ $# -lt 3 ]]; then
        log_error "Usage: $PROGRAM_NAME create <type> <name> <scope> [target]"
        exit 1
    fi
    
    local hook_type="$1"
    local hook_name="$2"
    local hook_scope="$3"
    local hook_target="${4:-}"
    
    log_info "Creating hook: $hook_name ($hook_type, $hook_scope)"
    
    if ! init_hook_system; then
        log_error "Failed to initialize hook system"
        exit 1
    fi
    
    if create_hook "$hook_type" "$hook_name" "$hook_scope" "$hook_target"; then
        log_success "Hook created successfully!"
        echo
        echo "Next steps:"
        echo "1. Edit the hook script to implement your logic"
        echo "2. Test the hook with: $PROGRAM_NAME execute $hook_type --dry-run"
        echo "3. Validate the hook with: $PROGRAM_NAME validate <hook_file>"
    else
        log_error "Failed to create hook"
        exit 1
    fi
}

# Remove hook
cmd_remove() {
    if [[ $# -lt 1 ]]; then
        log_error "Usage: $PROGRAM_NAME remove <hook_file>"
        exit 1
    fi
    
    local hook_file="$1"
    
    # Convert relative path to absolute if needed
    if [[ "$hook_file" != /* ]]; then
        hook_file="$DOTFILES_ROOT/$hook_file"
    fi
    
    log_info "Removing hook: $hook_file"
    
    if remove_hook "$hook_file"; then
        log_success "Hook removed successfully!"
    else
        log_error "Failed to remove hook"
        exit 1
    fi
}

# Execute hooks
cmd_execute() {
    if [[ $# -lt 1 ]]; then
        log_error "Usage: $PROGRAM_NAME execute <type> [module]"
        exit 1
    fi
    
    local hook_type="$1"
    local module_name="${2:-}"
    
    log_info "Executing hooks: $hook_type${module_name:+ (module: $module_name)}"
    
    if ! init_hook_system; then
        log_error "Failed to initialize hook system"
        exit 1
    fi
    
    if execute_hooks "$hook_type" "$module_name" "$CLI_DRY_RUN" "$CLI_CONTINUE_ON_ERROR"; then
        log_success "Hooks executed successfully!"
    else
        log_error "Hook execution failed"
        exit 1
    fi
}

# Validate hook
cmd_validate() {
    if [[ $# -lt 1 ]]; then
        log_error "Usage: $PROGRAM_NAME validate <hook_file>"
        exit 1
    fi
    
    local hook_file="$1"
    
    # Convert relative path to absolute if needed
    if [[ "$hook_file" != /* ]]; then
        hook_file="$DOTFILES_ROOT/$hook_file"
    fi
    
    log_info "Validating hook: $hook_file"
    
    if validate_hook_script "$hook_file"; then
        log_success "Hook validation passed!"
    else
        log_error "Hook validation failed"
        exit 1
    fi
}

# Main execution
main() {
    # Set default log level
    export LOG_LEVEL="${LOG_LEVEL:-INFO}"
    
    # Initialize logging
    setup_logging
    
    # Parse and execute command
    parse_arguments "$@"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi