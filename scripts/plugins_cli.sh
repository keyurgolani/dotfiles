#!/bin/bash

# Plugin CLI Interface
# Command-line interface for plugin management

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export DOTFILES_ROOT

# Source core functionality
source "$DOTFILES_ROOT/core/logger.sh"
source "$DOTFILES_ROOT/core/utils.sh"
source "$DOTFILES_ROOT/core/config.sh"
source "$DOTFILES_ROOT/core/platform.sh"
source "$DOTFILES_ROOT/core/plugins.sh"

# Initialize logging
setup_logging

# Plugin CLI version
readonly PLUGIN_CLI_VERSION="1.0.0"

# Show usage information
show_usage() {
    cat << 'EOF'
Plugin Management CLI

USAGE:
    ./plugins_cli.sh <command> [options]

COMMANDS:
    init                    Initialize plugin system
    discover [source]       Discover plugins (source: all|local|remote)
    list [filter]           List plugins (filter: all|installed|available)
    search <query>          Search plugins by name, description, or category
    info <plugin>           Show detailed plugin information
    install <plugin>        Install a plugin
    uninstall <plugin>      Uninstall a plugin
    update [plugin]         Update plugin(s) (all if no plugin specified)
    status                  Show plugin system status
    repos                   Manage plugin repositories
    export [file]           Export plugin configuration
    import <file>           Import plugin configuration
    clean [type]            Clean plugin cache (type: all|repositories|backups)
    check-updates [plugin]  Check for plugin updates
    auto-update             Run automatic plugin updates

OPTIONS:
    --dry-run              Show what would be done without making changes
    --force                Force operation (e.g., reinstall)
    --format <format>      Output format (table|json|yaml)
    --help, -h             Show this help message
    --version, -v          Show version information
    --verbose              Enable verbose logging
    --quiet                Suppress non-error output

EXAMPLES:
    ./plugins_cli.sh init
    ./plugins_cli.sh discover
    ./plugins_cli.sh list installed
    ./plugins_cli.sh search "shell"
    ./plugins_cli.sh install my-plugin
    ./plugins_cli.sh update --dry-run
    ./plugins_cli.sh export my-plugins.yaml
    ./plugins_cli.sh check-updates
    ./plugins_cli.sh auto-update --dry-run

REPOSITORY COMMANDS:
    repos list             List configured repositories
    repos add <name> <url> Add a new repository
    repos remove <name>    Remove a repository
    repos update [name]    Update repository cache

For more information, see the documentation at:
https://github.com/dotfiles-framework/unified-dotfiles/docs/plugins.md
EOF
}

# Show version information
show_version() {
    echo "Plugin CLI version: $PLUGIN_CLI_VERSION"
    echo "Plugin API version: $PLUGIN_API_VERSION"
    echo "Framework root: $DOTFILES_ROOT"
}

# Parse command line arguments
parse_args() {
    local command=""
    local dry_run=false
    local force=false
    local format="table"
    local verbose=false
    local quiet=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --quiet)
                quiet=true
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
                    # Store remaining arguments for command processing
                    break
                fi
                shift
                ;;
        esac
    done
    
    # Set logging level
    if [[ "$verbose" == "true" ]]; then
        export LOG_LEVEL="DEBUG"
    elif [[ "$quiet" == "true" ]]; then
        export LOG_LEVEL="ERROR"
    fi
    
    # Export parsed options for use in commands
    export CLI_DRY_RUN="$dry_run"
    export CLI_FORCE="$force"
    export CLI_FORMAT="$format"
    
    # Execute command
    case "$command" in
        "init")
            cmd_init "$@"
            ;;
        "discover")
            cmd_discover "$@"
            ;;
        "list")
            cmd_list "$@"
            ;;
        "search")
            cmd_search "$@"
            ;;
        "info")
            cmd_info "$@"
            ;;
        "install")
            cmd_install "$@"
            ;;
        "uninstall")
            cmd_uninstall "$@"
            ;;
        "update")
            cmd_update "$@"
            ;;
        "status")
            cmd_status "$@"
            ;;
        "repos")
            cmd_repos "$@"
            ;;
        "export")
            cmd_export "$@"
            ;;
        "import")
            cmd_import "$@"
            ;;
        "clean")
            cmd_clean "$@"
            ;;
        "check-updates")
            cmd_check_updates "$@"
            ;;
        "auto-update")
            cmd_auto_update "$@"
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

# Command implementations

cmd_init() {
    log_info "Initializing plugin system..."
    
    if init_plugin_system; then
        log_success "Plugin system initialized successfully"
        
        # Show status after initialization
        echo
        plugin_system_status
    else
        log_error "Failed to initialize plugin system"
        exit 1
    fi
}

cmd_discover() {
    local source="${1:-all}"
    
    if [[ ! "$source" =~ ^(all|local|remote)$ ]]; then
        log_error "Invalid source: $source. Must be 'all', 'local', or 'remote'"
        exit 1
    fi
    
    log_info "Discovering plugins from: $source"
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    if discover_plugins "$source"; then
        log_success "Plugin discovery completed"
        
        # Show discovered plugins
        echo
        list_plugins "available" "$CLI_FORMAT"
    else
        log_error "Plugin discovery failed"
        exit 1
    fi
}

cmd_list() {
    local filter="${1:-all}"
    
    if [[ ! "$filter" =~ ^(all|installed|available)$ ]]; then
        log_error "Invalid filter: $filter. Must be 'all', 'installed', or 'available'"
        exit 1
    fi
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    # Discover plugins if not already done
    if [[ ${#DISCOVERED_PLUGINS_NAMES[@]} -eq 0 ]]; then
        discover_plugins >/dev/null 2>&1 || true
    fi
    
    list_plugins "$filter" "$CLI_FORMAT"
}

cmd_search() {
    local query="$1"
    local search_field="${2:-all}"
    
    if [[ -z "$query" ]]; then
        log_error "Search query is required"
        exit 1
    fi
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    # Discover plugins if not already done
    if [[ ${#DISCOVERED_PLUGINS_NAMES[@]} -eq 0 ]]; then
        log_info "Discovering plugins..."
        discover_plugins >/dev/null 2>&1 || true
    fi
    
    search_plugins "$query" "$search_field"
}

cmd_info() {
    local plugin_name="$1"
    
    if [[ -z "$plugin_name" ]]; then
        log_error "Plugin name is required"
        exit 1
    fi
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    # Discover plugins if not already done
    if [[ ${#DISCOVERED_PLUGINS_NAMES[@]} -eq 0 ]]; then
        discover_plugins >/dev/null 2>&1 || true
    fi
    
    show_plugin_info "$plugin_name"
}

cmd_install() {
    local plugin_name="$1"
    
    if [[ -z "$plugin_name" ]]; then
        log_error "Plugin name is required"
        exit 1
    fi
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    # Discover plugins if not already done
    if [[ ${#DISCOVERED_PLUGINS_NAMES[@]} -eq 0 ]]; then
        log_info "Discovering plugins..."
        discover_plugins >/dev/null 2>&1 || true
    fi
    
    if install_plugin "$plugin_name" "$CLI_DRY_RUN" "$CLI_FORCE"; then
        if [[ "$CLI_DRY_RUN" != "true" ]]; then
            log_success "Plugin '$plugin_name' installed successfully"
        fi
    else
        log_error "Failed to install plugin: $plugin_name"
        exit 1
    fi
}

cmd_uninstall() {
    local plugin_name="$1"
    
    if [[ -z "$plugin_name" ]]; then
        log_error "Plugin name is required"
        exit 1
    fi
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    # Discover plugins if not already done
    if [[ ${#DISCOVERED_PLUGINS_NAMES[@]} -eq 0 ]]; then
        discover_plugins >/dev/null 2>&1 || true
    fi
    
    if uninstall_plugin "$plugin_name" "$CLI_DRY_RUN"; then
        if [[ "$CLI_DRY_RUN" != "true" ]]; then
            log_success "Plugin '$plugin_name' uninstalled successfully"
        fi
    else
        log_error "Failed to uninstall plugin: $plugin_name"
        exit 1
    fi
}

cmd_update() {
    local plugin_name="${1:-}"
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    # Discover plugins if not already done
    if [[ ${#DISCOVERED_PLUGINS_NAMES[@]} -eq 0 ]]; then
        log_info "Discovering plugins..."
        discover_plugins >/dev/null 2>&1 || true
    fi
    
    if [[ -n "$plugin_name" ]]; then
        # Update specific plugin
        if update_plugin "$plugin_name" "$CLI_DRY_RUN"; then
            if [[ "$CLI_DRY_RUN" != "true" ]]; then
                log_success "Plugin '$plugin_name' updated successfully"
            fi
        else
            log_error "Failed to update plugin: $plugin_name"
            exit 1
        fi
    else
        # Update all plugins
        if update_all_plugins "$CLI_DRY_RUN"; then
            if [[ "$CLI_DRY_RUN" != "true" ]]; then
                log_success "All plugins updated successfully"
            fi
        else
            log_error "Some plugins failed to update"
            exit 1
        fi
    fi
}

cmd_status() {
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    plugin_system_status
}

cmd_repos() {
    local subcmd="${1:-list}"
    shift || true
    
    case "$subcmd" in
        "list")
            cmd_repos_list "$@"
            ;;
        "add")
            cmd_repos_add "$@"
            ;;
        "remove")
            cmd_repos_remove "$@"
            ;;
        "update")
            cmd_repos_update "$@"
            ;;
        *)
            log_error "Unknown repos subcommand: $subcmd"
            echo "Available subcommands: list, add, remove, update"
            exit 1
            ;;
    esac
}

cmd_repos_list() {
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    echo "=== PLUGIN REPOSITORIES ==="
    printf "%-15s %-10s %-10s %s\n" "NAME" "ENABLED" "TRUSTED" "URL"
    printf "%-15s %-10s %-10s %s\n" "----" "-------" "-------" "---"
    
    for repo_name in $(get_array_keys "PLUGIN_REPOSITORIES_KEYS"); do
        local repo_data
        repo_data=$(get_array_value "PLUGIN_REPOSITORIES_KEYS" "PLUGIN_REPOSITORIES_VALUES" "$repo_name")
        local repo_enabled=$(echo "$repo_data" | grep -o 'enabled=[^;]*' | cut -d'=' -f2)
        local repo_trusted=$(echo "$repo_data" | grep -o 'trusted=[^;]*' | cut -d'=' -f2)
        local repo_url=$(echo "$repo_data" | grep -o 'url=[^;]*' | cut -d'=' -f2)
        
        printf "%-15s %-10s %-10s %s\n" "$repo_name" "$repo_enabled" "$repo_trusted" "$repo_url"
    done
}

cmd_repos_add() {
    local repo_name="$1"
    local repo_url="$2"
    local repo_branch="${3:-main}"
    local repo_trusted="${4:-false}"
    
    if [[ -z "$repo_name" || -z "$repo_url" ]]; then
        log_error "Repository name and URL are required"
        exit 1
    fi
    
    log_info "Adding repository: $repo_name"
    
    # This would require implementing repository management functions
    # For now, show what would be done
    if [[ "$CLI_DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would add repository:"
        log_info "  Name: $repo_name"
        log_info "  URL: $repo_url"
        log_info "  Branch: $repo_branch"
        log_info "  Trusted: $repo_trusted"
    else
        log_warn "Repository management not yet implemented"
        log_info "Please manually edit: $PLUGIN_REPOS_FILE"
    fi
}

cmd_repos_remove() {
    local repo_name="$1"
    
    if [[ -z "$repo_name" ]]; then
        log_error "Repository name is required"
        exit 1
    fi
    
    log_info "Removing repository: $repo_name"
    
    if [[ "$CLI_DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would remove repository: $repo_name"
    else
        log_warn "Repository management not yet implemented"
        log_info "Please manually edit: $PLUGIN_REPOS_FILE"
    fi
}

cmd_repos_update() {
    local repo_name="${1:-}"
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    if [[ -n "$repo_name" ]]; then
        log_info "Updating repository: $repo_name"
        
        local repo_data
        repo_data=$(get_array_value "PLUGIN_REPOSITORIES_KEYS" "PLUGIN_REPOSITORIES_VALUES" "$repo_name")
        
        if [[ -z "$repo_data" ]]; then
            log_error "Repository not found: $repo_name"
            exit 1
        fi
        
        local repo_url=$(echo "$repo_data" | grep -o 'url=[^;]*' | cut -d'=' -f2)
        local repo_branch=$(echo "$repo_data" | grep -o 'branch=[^;]*' | cut -d'=' -f2)
        local cache_dir="$PLUGIN_CACHE_DIR/$repo_name"
        
        if update_repository_cache "$repo_name" "$repo_url" "$repo_branch" "$cache_dir"; then
            log_success "Repository '$repo_name' updated successfully"
        else
            log_error "Failed to update repository: $repo_name"
            exit 1
        fi
    else
        log_info "Updating all repositories..."
        
        local error_count=0
        for repo_name in $(get_array_keys "PLUGIN_REPOSITORIES_KEYS"); do
            local repo_data
            repo_data=$(get_array_value "PLUGIN_REPOSITORIES_KEYS" "PLUGIN_REPOSITORIES_VALUES" "$repo_name")
            local repo_enabled=$(echo "$repo_data" | grep -o 'enabled=[^;]*' | cut -d'=' -f2)
            
            if [[ "$repo_enabled" == "true" ]]; then
                local repo_url=$(echo "$repo_data" | grep -o 'url=[^;]*' | cut -d'=' -f2)
                local repo_branch=$(echo "$repo_data" | grep -o 'branch=[^;]*' | cut -d'=' -f2)
                local cache_dir="$PLUGIN_CACHE_DIR/$repo_name"
                
                if update_repository_cache "$repo_name" "$repo_url" "$repo_branch" "$cache_dir"; then
                    log_info "✓ Repository '$repo_name' updated"
                else
                    log_error "✗ Failed to update repository: $repo_name"
                    ((error_count++))
                fi
            fi
        done
        
        if [[ $error_count -eq 0 ]]; then
            log_success "All repositories updated successfully"
        else
            log_error "$error_count repositories failed to update"
            exit 1
        fi
    fi
}

cmd_export() {
    local output_file="${1:-}"
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    export_plugin_config "$output_file"
}

cmd_import() {
    local config_file="$1"
    
    if [[ -z "$config_file" ]]; then
        log_error "Configuration file is required"
        exit 1
    fi
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    import_plugin_config "$config_file" "$CLI_DRY_RUN"
}

cmd_clean() {
    local cache_type="${1:-all}"
    
    if [[ ! "$cache_type" =~ ^(all|repositories|backups)$ ]]; then
        log_error "Invalid cache type: $cache_type. Must be 'all', 'repositories', or 'backups'"
        exit 1
    fi
    
    if [[ "$CLI_DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would clean plugin cache: $cache_type"
    else
        clean_plugin_cache "$cache_type"
    fi
}

cmd_check_updates() {
    local plugin_name="${1:-}"
    
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    if [[ -n "$plugin_name" ]]; then
        # Check specific plugin
        if check_plugin_updates "$plugin_name"; then
            echo "Update available for plugin: $plugin_name"
        else
            echo "Plugin '$plugin_name' is up to date or not installed"
        fi
    else
        # Show update status for all plugins
        list_plugins_with_updates "$CLI_FORMAT"
        
        # Also run the check
        if check_plugin_updates; then
            echo
            echo "Run './plugins_cli.sh update' to update all plugins"
        fi
    fi
}

cmd_auto_update() {
    # Initialize plugin system if not already done
    init_plugin_system >/dev/null 2>&1 || true
    
    if auto_update_plugins "$CLI_DRY_RUN"; then
        if [[ "$CLI_DRY_RUN" != "true" ]]; then
            log_success "Auto-update completed successfully"
        fi
    else
        log_info "No updates were needed"
    fi
}

# Show detailed plugin information
show_plugin_info() {
    local plugin_name="$1"
    
    local plugin_path
    plugin_path=$(get_array_value "DISCOVERED_PLUGINS_NAMES" "DISCOVERED_PLUGINS_PATHS" "$plugin_name")
    
    if [[ -z "$plugin_path" ]]; then
        log_error "Plugin not found: $plugin_name"
        return 1
    fi
    
    echo "=== PLUGIN INFORMATION ==="
    echo "Name: $plugin_name"
    
    local version
    version=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.version")
    echo "Version: $version"
    
    local description
    description=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.description")
    echo "Description: $description"
    
    local author
    author=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.author")
    if [[ -n "$author" ]]; then
        echo "Author: $author"
    fi
    
    local license
    license=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.license")
    if [[ -n "$license" ]]; then
        echo "License: $license"
    fi
    
    local homepage
    homepage=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.homepage")
    if [[ -n "$homepage" ]]; then
        echo "Homepage: $homepage"
    fi
    
    local repository
    repository=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.repository")
    if [[ -n "$repository" ]]; then
        echo "Repository: $repository"
    fi
    
    local categories
    categories=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.categories")
    if [[ -n "$categories" ]]; then
        echo "Categories: $categories"
    fi
    
    local api_version
    api_version=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.api_version")
    echo "API Version: $api_version"
    
    local trusted
    trusted=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.trusted")
    echo "Trusted: $trusted"
    
    echo "Path: $plugin_path"
    
    local status="available"
    if is_plugin_installed "$plugin_name"; then
        status="installed"
    fi
    echo "Status: $status"
    
    # Show dependencies
    local module_deps
    module_deps=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.module_dependencies")
    if [[ -n "$module_deps" ]]; then
        echo "Module Dependencies: $module_deps"
    fi
    
    local plugin_deps
    plugin_deps=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.plugin_dependencies")
    if [[ -n "$plugin_deps" ]]; then
        echo "Plugin Dependencies: $plugin_deps"
    fi
    
    local system_deps
    system_deps=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.system_dependencies")
    if [[ -n "$system_deps" ]]; then
        echo "System Dependencies: $system_deps"
    fi
    
    # Show conflicts
    local conflicts
    conflicts=$(get_array_value "PLUGIN_METADATA_KEYS" "PLUGIN_METADATA_VALUES" "$plugin_name.conflicts")
    if [[ -n "$conflicts" ]]; then
        echo "Conflicts: $conflicts"
    fi
}

# Main entry point
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    parse_args "$@"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi