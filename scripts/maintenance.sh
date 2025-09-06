#!/bin/bash

# Unified Dotfiles Framework - Maintenance CLI
# Provides easy access to update and maintenance features

set -euo pipefail

# Script directory and core paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CORE_DIR="${DOTFILES_ROOT}/core"

# Source core utilities
source "${CORE_DIR}/logger.sh"
source "${CORE_DIR}/utils.sh"
source "${CORE_DIR}/update.sh"

# Default configuration
VERBOSE=false
DRY_RUN=false

# Display usage information
show_usage() {
    cat << EOF
Unified Dotfiles Framework - Maintenance CLI
Update and maintenance utilities for the dotfiles framework

USAGE:
    $0 [OPTIONS] COMMAND [ARGS...]

COMMANDS:
    update framework [VERSION]    Update framework to latest or specific version
    update modules [MODULE...]    Update all modules or specific modules
    update check                  Check for available updates
    
    cleanup [--dry-run]          Clean up unused configurations and cache
    cleanup backups              Clean up old backups
    cleanup cache                Clean up update and download cache
    cleanup orphans              Clean up orphaned configuration files
    
    version                      Show current framework version
    version set VERSION          Set framework version manually
    
    status                       Show framework and module status
    
    migrate FROM_VERSION TO_VERSION  Run migration scripts manually
    
    help [COMMAND]               Show help for specific command

OPTIONS:
    -v, --verbose               Enable verbose output
    -d, --dry-run              Show what would be done without executing
    -h, --help                 Show this help message

EXAMPLES:
    # Check for updates
    $0 update check
    
    # Update framework to latest version
    $0 update framework
    
    # Update specific modules
    $0 update modules git vim
    
    # Clean up old files (preview mode)
    $0 cleanup --dry-run
    
    # Clean up old backups
    $0 cleanup backups
    
    # Show current status
    $0 status
    
    # Set version manually
    $0 version set 1.1.0

For more information, see the documentation in docs/ directory
EOF
}

# Show help for specific commands
show_command_help() {
    local command="$1"
    
    case "$command" in
        update)
            cat << EOF
UPDATE COMMAND HELP

Update the framework or individual modules to their latest versions.

SUBCOMMANDS:
    framework [VERSION]    Update framework to latest or specific version
    modules [MODULE...]    Update all modules or specific modules  
    check                  Check for available updates without updating

EXAMPLES:
    $0 update framework           # Update to latest version
    $0 update framework 1.2.0     # Update to specific version
    $0 update modules             # Update all modules
    $0 update modules git vim     # Update specific modules
    $0 update check               # Check for updates

The framework update will:
- Create a backup before updating
- Download and install the new version
- Run any necessary migration scripts
- Update the version file

Module updates will:
- Run module-specific update scripts
- Reinstall modules if no update script exists
- Preserve existing configurations
EOF
            ;;
        cleanup)
            cat << EOF
CLEANUP COMMAND HELP

Clean up unused configurations, old backups, and cached files.

SUBCOMMANDS:
    (no subcommand)       Clean up all categories
    backups              Clean up old backups based on retention policy
    cache                Clean up update and download cache
    orphans              Clean up orphaned configuration files

OPTIONS:
    --dry-run            Show what would be cleaned up without doing it

EXAMPLES:
    $0 cleanup                    # Clean up everything
    $0 cleanup --dry-run          # Preview cleanup actions
    $0 cleanup backups            # Clean up old backups only
    $0 cleanup cache              # Clean up cache files only

The cleanup process will:
- Remove backups older than retention period
- Clear expired cache files
- Remove orphaned configuration files
- Clean up temporary files
EOF
            ;;
        version)
            cat << EOF
VERSION COMMAND HELP

Manage framework version information.

SUBCOMMANDS:
    (no subcommand)       Show current framework version
    set VERSION          Set framework version manually

EXAMPLES:
    $0 version                    # Show current version
    $0 version set 1.1.0          # Set version to 1.1.0

Note: Setting the version manually should only be done if you know
what you're doing. It's normally updated automatically during updates.
EOF
            ;;
        status)
            cat << EOF
STATUS COMMAND HELP

Show comprehensive status information about the framework and modules.

The status command displays:
- Current framework version
- Available updates
- Installed modules and their status
- Recent backup information
- Cache usage statistics
- Configuration health check

EXAMPLE:
    $0 status                     # Show full status report
EOF
            ;;
        migrate)
            cat << EOF
MIGRATE COMMAND HELP

Manually run migration scripts for version transitions.

USAGE:
    $0 migrate FROM_VERSION TO_VERSION

EXAMPLES:
    $0 migrate 1.0.0 1.1.0        # Run migrations from 1.0.0 to 1.1.0

This command is normally run automatically during updates, but can be
used manually if needed for troubleshooting or custom scenarios.
EOF
            ;;
        *)
            echo "Unknown command: $command"
            echo ""
            echo "Available commands: update, cleanup, version, status, migrate"
            echo "Use '$0 help [COMMAND]' for command-specific help"
            ;;
    esac
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                # First non-option argument is the command
                break
                ;;
        esac
    done
    
    # Return remaining arguments
    echo "$@"
}

# Handle update commands
handle_update() {
    local subcommand="${1:-framework}"
    shift || true
    
    case "$subcommand" in
        framework|self)
            log_info "Updating framework..."
            handle_update_command framework "$@"
            ;;
        modules|module)
            log_info "Updating modules..."
            handle_update_command modules "$@"
            ;;
        check)
            log_info "Checking for updates..."
            handle_update_command check "$@"
            ;;
        *)
            log_error "Unknown update subcommand: $subcommand"
            log_info "Available subcommands: framework, modules, check"
            return 1
            ;;
    esac
}

# Handle cleanup commands
handle_cleanup() {
    local subcommand="${1:-all}"
    local dry_run_flag="$DRY_RUN"
    
    # Check for --dry-run flag in arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run_flag=true
                shift
                ;;
            *)
                subcommand="$1"
                shift
                ;;
        esac
    done
    
    case "$subcommand" in
        all|"")
            log_info "Running full cleanup..."
            cleanup_unused_configs "$dry_run_flag"
            ;;
        backups|backup)
            log_info "Cleaning up old backups..."
            cleanup_old_backups "$dry_run_flag"
            ;;
        cache)
            log_info "Cleaning up cache files..."
            cleanup_update_cache "$dry_run_flag"
            ;;
        orphans|orphan)
            log_info "Cleaning up orphaned files..."
            cleanup_orphaned_configs "$dry_run_flag"
            ;;
        *)
            log_error "Unknown cleanup subcommand: $subcommand"
            log_info "Available subcommands: all, backups, cache, orphans"
            return 1
            ;;
    esac
}

# Handle version commands
handle_version() {
    local subcommand="${1:-show}"
    shift || true
    
    case "$subcommand" in
        show|"")
            local current_version
            current_version=$(get_current_version)
            echo "Framework version: $current_version"
            ;;
        set)
            local new_version="$1"
            if [[ -z "$new_version" ]]; then
                log_error "Version required for 'set' command"
                return 1
            fi
            
            log_info "Setting framework version to: $new_version"
            set_framework_version "$new_version"
            ;;
        *)
            log_error "Unknown version subcommand: $subcommand"
            log_info "Available subcommands: show, set"
            return 1
            ;;
    esac
}

# Show framework and module status
show_status() {
    log_info "Framework Status Report"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Framework version
    local current_version
    current_version=$(get_current_version)
    echo "Framework Version: $current_version"
    
    # Check for updates
    check_for_updates false
    if [[ "$UPDATE_AVAILABLE" == "true" ]]; then
        echo "Update Available: $LATEST_VERSION"
    else
        echo "Status: Up to date"
    fi
    
    echo ""
    
    # Installed modules
    echo "Installed Modules:"
    local installed_modules
    installed_modules=($(get_installed_modules))
    
    if [[ ${#installed_modules[@]} -gt 0 ]]; then
        for module in "${installed_modules[@]}"; do
            echo "  ✓ $module"
        done
    else
        echo "  No modules installed"
    fi
    
    echo ""
    
    # Backup information
    echo "Backup Information:"
    local backup_dir="$HOME/.dotfiles-backups"
    if [[ -d "$backup_dir" ]]; then
        local backup_count
        backup_count=$(find "$backup_dir" -maxdepth 1 -type d -name "backup_*" | wc -l | tr -d ' ')
        echo "  Backups available: $backup_count"
        
        # Show most recent backup
        local latest_backup
        latest_backup=$(find "$backup_dir" -maxdepth 1 -type d -name "backup_*" | sort | tail -n1)
        if [[ -n "$latest_backup" ]]; then
            local backup_date
            backup_date=$(stat -c %Y "$latest_backup" 2>/dev/null || stat -f %m "$latest_backup" 2>/dev/null)
            local backup_age
            backup_age=$(( $(date +%s) - backup_date ))
            echo "  Latest backup: $(basename "$latest_backup") ($(format_age $backup_age) ago)"
        fi
    else
        echo "  No backups found"
    fi
    
    echo ""
    
    # Cache information
    echo "Cache Information:"
    local cache_dir="$SCRIPT_DIR/cache"
    if [[ -d "$cache_dir" ]]; then
        local cache_size
        cache_size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1 || echo "0B")
        echo "  Cache size: $cache_size"
        
        # Show cache subdirectories
        for subdir in "$cache_dir"/*; do
            if [[ -d "$subdir" ]]; then
                local subdir_size
                subdir_size=$(du -sh "$subdir" 2>/dev/null | cut -f1 || echo "0B")
                echo "    $(basename "$subdir"): $subdir_size"
            fi
        done
    else
        echo "  No cache directory found"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Format age in human-readable format
format_age() {
    local seconds="$1"
    
    if [[ $seconds -lt 60 ]]; then
        echo "${seconds}s"
    elif [[ $seconds -lt 3600 ]]; then
        echo "$((seconds / 60))m"
    elif [[ $seconds -lt 86400 ]]; then
        echo "$((seconds / 3600))h"
    else
        echo "$((seconds / 86400))d"
    fi
}

# Handle migrate commands
handle_migrate() {
    local from_version="$1"
    local to_version="$2"
    
    if [[ -z "$from_version" || -z "$to_version" ]]; then
        log_error "Both FROM_VERSION and TO_VERSION are required"
        log_info "Usage: $0 migrate FROM_VERSION TO_VERSION"
        return 1
    fi
    
    log_info "Running migration from $from_version to $to_version..."
    
    if run_migration_scripts "$from_version" "$to_version"; then
        log_success "Migration completed successfully"
    else
        log_error "Migration failed or completed with warnings"
        return 1
    fi
}

# Main execution
main() {
    # Set up logging
    setup_logging "$VERBOSE"
    
    # Parse arguments
    local remaining_args
    remaining_args=($(parse_arguments "$@"))
    
    # Get command
    local command="${remaining_args[0]:-help}"
    
    # Remove command from args
    if [[ ${#remaining_args[@]} -gt 0 ]]; then
        remaining_args=("${remaining_args[@]:1}")
    else
        remaining_args=()
    fi
    
    # Initialize update system
    if ! init_update_system; then
        log_error "Failed to initialize update system"
        exit 1
    fi
    
    # Execute command
    case "$command" in
        update)
            handle_update "${remaining_args[@]+"${remaining_args[@]}"}"
            ;;
        cleanup)
            handle_cleanup "${remaining_args[@]+"${remaining_args[@]}"}"
            ;;
        version)
            handle_version "${remaining_args[@]+"${remaining_args[@]}"}"
            ;;
        status)
            show_status
            ;;
        migrate)
            handle_migrate "${remaining_args[@]+"${remaining_args[@]}"}"
            ;;
        help)
            if [[ ${#remaining_args[@]} -gt 0 ]]; then
                show_command_help "${remaining_args[0]}"
            else
                show_usage
            fi
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi