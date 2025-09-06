#!/bin/bash

# Unified Dotfiles Framework - Main Installation Script
# A comprehensive, cross-platform dotfiles management system

set -euo pipefail

# Script directory and core paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CORE_DIR="${DOTFILES_ROOT}/core"
export DOTFILES_ROOT

# Source core utilities
source "${CORE_DIR}/logger.sh"
source "${CORE_DIR}/utils.sh"
source "${CORE_DIR}/platform.sh"
source "${CORE_DIR}/config.sh"
source "${CORE_DIR}/modules_simple.sh"
source "${CORE_DIR}/performance.sh"
source "${CORE_DIR}/update.sh"
source "${CORE_DIR}/user_experience.sh"
source "${CORE_DIR}/backup.sh"
source "${CORE_DIR}/error_handler.sh"

# Default configuration
DEFAULT_CONFIG_FILE="${DOTFILES_ROOT}/config/modules.yaml"
INTERACTIVE_MODE=true
DRY_RUN=false
VERBOSE=false
WIZARD_MODE=false
SELECTED_MODULES=()
OVERRIDE_FILE=""
RESTORE_BACKUP_ID=""
HELP_TOPIC=""
PARSED_COMMAND=""
INSTALLATION_START_TIME=""

# Display usage information
show_usage() {
    cat << EOF
Unified Dotfiles Framework - Installation Script
A comprehensive, cross-platform dotfiles management system

USAGE:
    $0 [OPTIONS] [COMMAND]

COMMANDS:
    install                 Install selected modules (default)
    wizard                  Run configuration wizard for first-time setup
    update                  Update framework and modules
    backup                  Create backup of current dotfiles
    restore [BACKUP_ID]     Restore from backup
    list-modules            List available modules with details
    list-backups            List available backups
    cleanup                 Clean up old backups and cache
    version                 Show current framework version
    status                  Show framework and module status
    help [TOPIC]            Show help message or topic-specific help

OPTIONS:
    -m, --modules MODULES   Comma-separated list of modules to install
    -c, --config FILE       Use custom configuration file
    -o, --override FILE     Apply configuration overrides
    -w, --wizard           Run configuration wizard for first-time setup
    -n, --non-interactive   Run in non-interactive mode
    -d, --dry-run          Show what would be done without executing
    -v, --verbose          Enable verbose output and debug information
    -h, --help             Show this help message

EXAMPLES:
    # First-time interactive installation
    $0

    # Run configuration wizard for first-time setup
    $0 wizard

    # Install specific modules
    $0 --modules git,vim,tmux,shell

    # Use custom configuration
    $0 --config config/my-setup.yaml

    # Apply work environment overrides
    $0 --override config/overrides/work.yaml

    # Preview installation without making changes
    $0 --dry-run --verbose

    # Non-interactive installation with defaults
    $0 --non-interactive

    # Update framework to latest version
    $0 update

    # Create backup before making changes
    $0 backup

    # Restore from specific backup
    $0 restore 20240827_143022

    # Clean up old backups and cache
    $0 cleanup

    # Show framework status
    $0 status

    # List all available modules
    $0 list-modules

    # Get help on specific topics
    $0 help modules
    $0 help configuration
    $0 help troubleshooting

GETTING STARTED:
    1. Run '$0 wizard' for guided first-time setup
    2. Or run '$0' for interactive installation
    3. Or run '$0 --modules shell,git' for quick setup
    4. Use '$0 --dry-run' to preview changes
    5. Check '$0 list-modules' for available modules

HELP TOPICS:
    modules         Information about available modules
    configuration   Configuration file format and options
    overrides       Environment-specific configuration overrides
    performance     Performance optimization options
    troubleshooting Common issues and solutions
    examples        More usage examples

For comprehensive documentation, see README.md and docs/ directory
EOF
}

# Display help for specific topics
show_help_topic() {
    local topic="$1"
    
    case "$topic" in
        modules|module)
            show_modules_help
            ;;
        config|configuration)
            show_configuration_help
            ;;
        overrides|override)
            show_overrides_help
            ;;
        performance|perf)
            show_performance_help
            ;;
        troubleshooting|troubleshoot|debug)
            show_troubleshooting_help
            ;;
        examples|example)
            show_examples_help
            ;;
        *)
            echo "Unknown help topic: $topic"
            echo ""
            echo "Available help topics:"
            echo "  modules         - Information about available modules"
            echo "  configuration   - Configuration file format and options"
            echo "  overrides       - Environment-specific overrides"
            echo "  performance     - Performance optimization"
            echo "  troubleshooting - Common issues and solutions"
            echo "  examples        - Usage examples"
            echo ""
            echo "Use '$0 help [TOPIC]' for topic-specific help"
            ;;
    esac
}

# Show modules help
show_modules_help() {
    cat << EOF
MODULES HELP - Available Modules and Usage

The framework uses a modular architecture where each tool or configuration
set is treated as an independent module that can be installed separately.

LISTING MODULES:
    $0 list-modules                    # List all available modules
    $0 list-modules --detailed         # Show detailed module information

SELECTING MODULES:
    # Interactive selection (recommended for first-time users)
    $0

    # Specify modules on command line
    $0 --modules git,vim,tmux

    # Install all available modules
    $0 --modules all

CORE MODULES:
    shell           Bash/Zsh configurations, aliases, functions
    git             Git configuration, aliases, ignore patterns
    vim             Vim configuration, plugins, key mappings
    tmux            Tmux configuration, key bindings

PLATFORM-SPECIFIC MODULES:
    homebrew        Homebrew package manager (macOS only)
    developer-tools Essential development tools (platform-specific)

MODULE DEPENDENCIES:
    The framework automatically resolves and installs module dependencies.
    For example, installing 'vim' will also install 'shell' if needed.

CUSTOM MODULES:
    You can create custom modules in the modules/ directory.
    See docs/module-development.md for details.

For more information: $0 help configuration
EOF
}

# Show configuration help
show_configuration_help() {
    cat << EOF
CONFIGURATION HELP - Configuration Files and Options

The framework uses YAML configuration files for flexible customization.

CONFIGURATION FILES:
    config/base.yaml        Default framework configuration
    config/modules.yaml     Module selection and settings
    config/user.yaml        User-specific customizations
    config/overrides/       Environment-specific overrides

BASIC CONFIGURATION FORMAT:
    modules:
      enabled:
        - shell
        - git
        - vim
      disabled:
        - docker

    settings:
      backup_enabled: true
      interactive_mode: true
      parallel_installation: true

    user:
      name: "Your Name"
      email: "your.email@example.com"
      github_username: "yourusername"

USING CUSTOM CONFIGURATION:
    # Use custom configuration file
    $0 --config my-config.yaml

    # Apply overrides
    $0 --override config/overrides/work.yaml

CONFIGURATION VALIDATION:
    The framework validates configuration files and will report errors
    if required fields are missing or values are invalid.

For more information: $0 help overrides
EOF
}

# Show overrides help
show_overrides_help() {
    cat << EOF
OVERRIDES HELP - Environment-Specific Configuration

Override files allow you to customize configurations for different
environments (work, personal, different machines, etc.).

OVERRIDE TYPES:
    Platform-based    Different settings for macOS vs Linux
    Hostname-based    Machine-specific configurations
    Environment-based Work vs personal environment settings

CREATING OVERRIDE FILES:
    # Work environment override
    config/overrides/work.yaml:
        user:
          email: "work@company.com"
        modules:
          enabled:
            - corporate-vpn
            - company-tools

    # Personal environment override
    config/overrides/personal.yaml:
        modules:
          enabled:
            - media-tools
            - gaming-setup

APPLYING OVERRIDES:
    # Apply specific override file
    $0 --override config/overrides/work.yaml

    # Multiple overrides (applied in order)
    $0 --override config/overrides/work.yaml --override config/overrides/laptop.yaml

AUTOMATIC OVERRIDE DETECTION:
    The framework can automatically detect and apply overrides based on:
    - Current hostname
    - Environment variables
    - Platform detection

For more information: $0 help configuration
EOF
}

# Show performance help
show_performance_help() {
    cat << EOF
PERFORMANCE HELP - Optimization Options

The framework includes several performance optimizations to speed up
installation and improve shell startup times.

PERFORMANCE FEATURES:
    Parallel Installation    Install multiple modules simultaneously
    Download Caching        Cache downloaded packages and files
    Platform Caching        Cache platform detection results
    Shell Optimization      Optimize shell startup performance

PERFORMANCE CONFIGURATION:
    performance:
      enable_parallel_installation: true
      max_parallel_jobs: 4
      enable_download_cache: true
      enable_platform_cache: true
      shell_startup_optimization: true
      cache_ttl_seconds: 3600

PERFORMANCE MONITORING:
    # Show performance summary after installation
    $0 --verbose

    # Monitor shell startup time
    time zsh -i -c exit

PERFORMANCE TROUBLESHOOTING:
    # Disable parallel installation if issues occur
    $0 --modules git,vim --override config/overrides/sequential.yaml

    # Clear caches if needed
    rm -rf ~/.dotfiles/cache/

For more information: see docs/performance-optimization.md
EOF
}

# Show troubleshooting help
show_troubleshooting_help() {
    cat << EOF
TROUBLESHOOTING HELP - Common Issues and Solutions

INSTALLATION ISSUES:

Permission Errors:
    Problem: "Permission denied" errors during installation
    Solution: Ensure you have write permissions to your home directory
              sudo chown -R \$USER:\$USER ~

Module Not Found:
    Problem: "Module 'xyz' not found" error
    Solution: Check available modules with '$0 list-modules'
              Verify module name spelling

Network Issues:
    Problem: Download failures or timeouts
    Solution: Check internet connection
              Try again with '--verbose' for more details
              Use '--dry-run' to test without downloading

Backup/Restore Issues:
    Problem: Backup creation or restoration fails
    Solution: Check available backups with '$0 list-backups'
              Ensure backup ID is correct
              Verify disk space availability

PERFORMANCE ISSUES:

Slow Installation:
    Problem: Installation takes too long
    Solution: Enable parallel installation in configuration
              Check network connection
              Use '--verbose' to identify bottlenecks

Slow Shell Startup:
    Problem: Shell takes long time to start
    Solution: Enable shell optimization in configuration
              Check for conflicting shell configurations
              Use 'time zsh -i -c exit' to measure startup time

DEBUGGING:

Enable Debug Mode:
    export DEBUG=1
    $0 --verbose

Check Log Files:
    tail -f ~/.dotfiles/logs/install.log

Dry Run Mode:
    $0 --dry-run --verbose

Get Help:
    $0 help [topic]
    Check docs/ directory for detailed guides
    Report issues on project repository

For more information: see docs/error-handling.md
EOF
}

# Show examples help
show_examples_help() {
    cat << EOF
EXAMPLES HELP - Common Usage Patterns

FIRST-TIME SETUP:
    # Interactive installation (recommended)
    $0

    # Quick setup with essential modules
    $0 --modules shell,git,vim

    # Preview what would be installed
    $0 --dry-run --verbose

WORK ENVIRONMENT SETUP:
    # Create work-specific configuration
    $0 --override config/overrides/work.yaml

    # Install work-specific modules
    $0 --modules shell,git,vim,corporate-tools

DEVELOPMENT MACHINE SETUP:
    # Full development environment
    $0 --modules shell,git,vim,tmux,developer-tools,homebrew

    # With custom configuration
    $0 --config config/dev-machine.yaml

UPDATING AND MAINTENANCE:
    # Update existing installation
    $0 update

    # Create backup before changes
    $0 backup

    # Restore from backup if needed
    $0 restore 20240827_143022

TESTING AND DEBUGGING:
    # Test configuration without applying
    $0 --dry-run --verbose

    # Debug installation issues
    DEBUG=1 $0 --verbose

    # List available options
    $0 list-modules
    $0 list-backups

CUSTOM CONFIGURATIONS:
    # Use different configuration file
    $0 --config ~/.dotfiles-custom.yaml

    # Apply multiple overrides
    $0 --override work.yaml --override laptop.yaml

    # Non-interactive with specific modules
    $0 --non-interactive --modules git,vim,tmux

For more examples: see README.md and docs/ directory
EOF
}

# Parse command line arguments
parse_arguments() {
    local command=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            install|wizard|update|backup|restore|list-modules|list-backups|cleanup|version|status|help)
                command="$1"
                shift
                # For restore command, capture the backup ID if provided
                if [[ "$command" == "restore" && $# -gt 0 && ! "$1" =~ ^- ]]; then
                    RESTORE_BACKUP_ID="$1"
                    shift
                # For help command, capture the topic if provided
                elif [[ "$command" == "help" && $# -gt 0 && ! "$1" =~ ^- ]]; then
                    HELP_TOPIC="$1"
                    shift
                fi
                ;;
            -m|--modules)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --modules requires an argument" >&2
                    exit 1
                fi
                IFS=',' read -ra SELECTED_MODULES <<< "$2"
                echo "DEBUG: Parsed modules: ${SELECTED_MODULES[*]}" >&2
                shift 2
                ;;
            -c|--config)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --config requires an argument" >&2
                    exit 1
                fi
                DEFAULT_CONFIG_FILE="$2"
                shift 2
                ;;
            -o|--override)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --override requires an argument" >&2
                    exit 1
                fi
                OVERRIDE_FILE="$2"
                shift 2
                ;;
            -w|--wizard)
                WIZARD_MODE=true
                shift
                ;;
            -n|--non-interactive)
                INTERACTIVE_MODE=false
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                command="help"
                shift
                ;;
            *)
                echo "Error: Unknown option: $1" >&2
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Handle wizard mode flag
    if [[ "$WIZARD_MODE" == "true" && -z "$command" ]]; then
        command="wizard"
    fi
    
    # Default to install command if none specified
    if [[ -z "$command" ]]; then
        command="install"
    fi
    
    PARSED_COMMAND="$command"
}

# Main installation function
main_install() {
    # Record start time for performance tracking
    INSTALLATION_START_TIME=$(date +%s)
    
    log_info "Starting Unified Dotfiles Framework installation..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi
    
    # Validate environment
    validate_environment
    
    # Initialize platform system
    log_info "Initializing platform detection..."
    if ! init_platform_system; then
        log_error "Failed to initialize platform system"
        exit 1
    fi
    
    # Initialize module system
    log_info "Initializing module system..."
    if ! init_module_system "$DOTFILES_ROOT"; then
        log_error "Failed to initialize module system"
        exit 1
    fi
    
    # Load configuration
    log_info "Loading configuration..."
    
    # Initialize the configuration system
    if ! init_config_system; then
        log_error "Failed to initialize configuration system"
        exit 1
    fi
    
    if [[ ! -f "$DEFAULT_CONFIG_FILE" ]]; then
        log_warn "Configuration file not found: $DEFAULT_CONFIG_FILE"
        log_info "Creating default configuration..."
        create_default_config
    fi
    
    # Determine modules to install
    local modules_to_install=()
    echo "DEBUG: SELECTED_MODULES count: ${#SELECTED_MODULES[@]}"
    echo "DEBUG: SELECTED_MODULES content: ${SELECTED_MODULES[*]:-}"
    if [[ ${#SELECTED_MODULES[@]} -gt 0 ]]; then
        modules_to_install=("${SELECTED_MODULES[@]}")
        log_info "Installing selected modules: ${modules_to_install[*]}"
        
        # Still run user configuration in interactive mode even with pre-selected modules
        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            interactive_user_configuration
        fi
    else
        # Load from configuration file
        if [[ -f "$DEFAULT_CONFIG_FILE" ]]; then
            local enabled_modules
            enabled_modules=$(get_yaml_array "$DEFAULT_CONFIG_FILE" "modules.enabled")
            if [[ -n "$enabled_modules" ]]; then
                read -ra modules_to_install <<< "$enabled_modules"
                log_info "Installing modules from configuration: ${modules_to_install[*]}"
                
                # Run user configuration in interactive mode
                if [[ "$INTERACTIVE_MODE" == "true" ]]; then
                    interactive_user_configuration
                fi
            fi
        fi
        
        # If still no modules, use interactive selection or defaults
        if [[ ${#modules_to_install[@]} -eq 0 ]]; then
            if [[ "$INTERACTIVE_MODE" == "true" ]]; then
                # Use enhanced interactive setup that handles both user config and module selection
                interactive_setup_complete
                # Get the selected modules from the interactive selection
                interactive_module_selection modules_to_install
            else
                modules_to_install=("shell" "git")
                log_info "Using default modules: ${modules_to_install[*]}"
            fi
        fi
    fi
    
    # Show dry-run preview if requested
    if [[ "$DRY_RUN" == "true" ]]; then
        run_dry_run_preview "${modules_to_install[@]}"
        return 0
    fi
    
    # Interactive installation confirmation
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        if ! interactive_installation_confirmation "${modules_to_install[@]}"; then
            log_info "Installation cancelled by user"
            return 0
        fi
    fi
    
    # Resolve dependencies
    log_info "Resolving module dependencies..."
    if ! resolve_dependencies "${modules_to_install[@]}"; then
        log_error "Failed to resolve module dependencies"
        exit 1
    fi
    
    # Initialize progress tracking
    local total_steps=$((${#INSTALL_QUEUE[@]} + 3))  # modules + platform preferences + backup + cleanup
    local enable_progress="true"
    
    # Try to get progress indicator setting from config
    if command -v get_config_value >/dev/null 2>&1; then
        enable_progress=$(get_config_value "performance.enable_progress_indicators" "true")
    fi
    
    init_progress_tracking "$total_steps" "$enable_progress"
    
    # Install modules with performance optimizations
    log_info "Installing ${#INSTALL_QUEUE[@]} modules..."
    local install_failures=0
    
    # Try to use performance-optimized batch installation
    if [[ "$(type -t install_modules_batch)" == "function" ]]; then
        if ! install_modules_batch "${INSTALL_QUEUE[@]}"; then
            install_failures=1
        fi
    else
        # Fall back to sequential installation with progress tracking
        for module in "${INSTALL_QUEUE[@]}"; do
            update_progress "Installing $module"
            
            if ! install_module "$module" "$DRY_RUN"; then
                log_error "Failed to install module: $module"
                ((install_failures++))
            fi
        done
    fi
    
    # Apply platform-specific system preferences
    update_progress "Applying system preferences"
    
    # Clear progress line before platform preferences output
    if [[ "$(type -t clear_progress_line)" == "function" ]]; then
        clear_progress_line
    fi
    
    if ! install_platform_preferences "$DRY_RUN"; then
        log_warn "Failed to apply platform preferences, but continuing with installation"
        # Don't fail the entire installation for preferences failures
    fi
    
    # Final progress update
    update_progress "Finalizing installation"
    
    # Clear progress line before final output
    if [[ "$(type -t clear_progress_line)" == "function" ]]; then
        clear_progress_line
    fi
    
    # Summary
    if [[ $install_failures -eq 0 ]]; then
        log_success "Installation completed successfully!"
        
        # Use enhanced summary if available
        if [[ "$(type -t show_installation_summary_enhanced)" == "function" ]]; then
            show_installation_summary_enhanced "${INSTALL_QUEUE[@]}"
        else
            show_installation_summary "${INSTALL_QUEUE[@]}"
        fi
        
        # Show performance summary if available
        if [[ "$(type -t show_performance_summary)" == "function" && "$VERBOSE" == "true" ]]; then
            show_performance_summary
        fi
    else
        log_error "Installation completed with $install_failures failures"
        show_failure_help
        exit 1
    fi
}

# Run configuration wizard
main_wizard() {
    log_info "Starting Configuration Wizard..."
    
    # Initialize module system for wizard
    if ! init_module_system "$DOTFILES_ROOT"; then
        log_error "Failed to initialize module system"
        exit 1
    fi
    
    # Run the configuration wizard
    local wizard_config_file="${SCRIPT_DIR}/config/wizard-generated.yaml"
    
    if run_configuration_wizard "$wizard_config_file"; then
        log_success "Configuration wizard completed successfully!"
        
        # Ask if user wants to install now
        echo ""
        if confirm "Would you like to install with the generated configuration now?"; then
            # Set the generated config as default and run installation
            DEFAULT_CONFIG_FILE="$wizard_config_file"
            INTERACTIVE_MODE=false  # Skip interactive prompts since wizard already collected input
            main_install
        else
            log_info "Configuration saved. You can install later with:"
            log_info "  $0 --config $wizard_config_file"
        fi
    else
        log_error "Configuration wizard failed"
        exit 1
    fi
}

# Update existing installation
main_update() {
    log_info "Updating Unified Dotfiles Framework..."
    
    # Initialize update system
    if ! init_update_system; then
        log_error "Failed to initialize update system"
        return 1
    fi
    
    # Check for updates and update if available
    check_for_updates true
    if [[ "$UPDATE_AVAILABLE" == "true" ]]; then
        log_info "Update available: $CURRENT_VERSION → $LATEST_VERSION"
        update_framework "$LATEST_VERSION"
    else
        log_info "Framework is already up to date (version $CURRENT_VERSION)"
        
        # Offer to update modules instead
        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            echo ""
            log_info "Would you like to update installed modules? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                update_modules
            fi
        fi
    fi
    
    log_success "Update process completed!"
}

# Create backup
main_backup() {
    log_info "Creating backup of current dotfiles..."
    
    # Initialize backup system
    if ! init_backup_system; then
        log_error "Failed to initialize backup system"
        return 1
    fi
    
    # Create backup
    local backup_id
    backup_id=$(create_backup "manual-$(date +%Y%m%d_%H%M%S)")
    
    if [[ $? -eq 0 && -n "$backup_id" ]]; then
        log_success "Backup created successfully: $backup_id"
        log_info "Backup location: $BACKUP_BASE_DIR/$backup_id"
    else
        log_error "Failed to create backup"
        return 1
    fi
}

# Restore from backup
main_restore() {
    local backup_id="$1"
    if [[ -z "$backup_id" ]]; then
        log_error "Backup ID required for restore command"
        
        # Show available backups
        log_info "Available backups:"
        main_list_backups
        exit 1
    fi
    
    log_info "Restoring from backup: $backup_id"
    
    # Initialize backup system
    if ! init_backup_system; then
        log_error "Failed to initialize backup system"
        return 1
    fi
    
    # Restore from backup
    if restore_backup "$backup_id"; then
        log_success "Restore completed successfully!"
    else
        log_error "Failed to restore from backup: $backup_id"
        return 1
    fi
}

# List available modules
main_list_modules() {
    log_info "Initializing module system..."
    if ! init_module_system "$DOTFILES_ROOT"; then
        log_error "Failed to initialize module system"
        exit 1
    fi
    
    log_info "Available modules:"
    list_available_modules "detailed"
}

# List available backups
main_list_backups() {
    log_info "Available backups:"
    
    # Initialize backup system
    if ! init_backup_system; then
        log_error "Failed to initialize backup system"
        return 1
    fi
    
    # List backups
    if list_backups; then
        return 0
    else
        echo "  No backups found"
        return 0
    fi
}

# Validate environment and dependencies
validate_environment() {
    log_debug "Validating environment..."
    
    # Check for required commands
    local required_commands=("bash" "mkdir" "cp" "ln")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required command not found: $cmd"
            exit 1
        fi
    done
    
    # Check write permissions
    if [[ ! -w "$HOME" ]]; then
        log_error "No write permission to home directory: $HOME"
        exit 1
    fi
    
    log_debug "Environment validation completed"
}

# Create default configuration file
create_default_config() {
    local config_dir
    config_dir="$(dirname "$DEFAULT_CONFIG_FILE")"
    
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
    fi
    
    cat > "$DEFAULT_CONFIG_FILE" << 'EOF'
# Default Unified Dotfiles Framework Configuration
modules:
  enabled:
    - shell
    - git
  disabled: []

settings:
  backup_enabled: true
  backup_retention_days: 30
  interactive_mode: true
  parallel_installation: true
  
performance:
  enable_parallel_installation: true
  enable_download_cache: true
  enable_platform_cache: true
  enable_progress_indicators: true
  shell_startup_optimization: true
  max_parallel_jobs: 4
  cache_ttl_seconds: 3600

user:
  name: ""
  email: ""
  github_username: ""
EOF
    
    log_info "Created default configuration: $DEFAULT_CONFIG_FILE"
}

# Show installation summary with next steps
show_installation_summary() {
    local installed_modules=("$@")
    
    echo ""
    log_info "📋 INSTALLATION SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    log_info "✅ Successfully installed ${#installed_modules[@]} modules:"
    for module in "${installed_modules[@]}"; do
        echo "   • $module"
    done
    
    echo ""
    log_info "🔧 NEXT STEPS:"
    
    # Check if shell module was installed
    local shell_installed=false
    for module in "${installed_modules[@]}"; do
        if [[ "$module" == "shell" ]]; then
            shell_installed=true
            break
        fi
    done
    
    if [[ "$shell_installed" == "true" ]]; then
        echo "   1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
        echo "   2. Verify shell configurations are working: alias"
    fi
    
    # Check if git module was installed
    local git_installed=false
    for module in "${installed_modules[@]}"; do
        if [[ "$module" == "git" ]]; then
            git_installed=true
            break
        fi
    done
    
    if [[ "$git_installed" == "true" ]]; then
        # Check if git is configured
        local git_name git_email
        git_name=$(git config --global user.name 2>/dev/null || echo "")
        git_email=$(git config --global user.email 2>/dev/null || echo "")
        
        if [[ -n "$git_name" && -n "$git_email" ]]; then
            echo "   3. ✅ Git is configured with:"
            echo "      Name: $git_name"
            echo "      Email: $git_email"
        else
            echo "   3. Configure git user information:"
            echo "      git config --global user.name \"Your Name\""
            echo "      git config --global user.email \"your.email@example.com\""
        fi
    fi
    
    echo "   4. Create a backup before making changes: $0 backup"
    echo "   5. Update configurations anytime: $0 update"
    echo "   6. View available modules: $0 list-modules"
    
    echo ""
    log_info "📚 DOCUMENTATION:"
    echo "   • README.md - Comprehensive usage guide"
    echo "   • docs/ - Detailed documentation for all features"
    echo "   • $0 help [topic] - Topic-specific help"
    
    echo ""
    log_info "🔍 TROUBLESHOOTING:"
    echo "   • If you encounter issues: $0 help troubleshooting"
    echo "   • Enable debug mode: DEBUG=1 $0 --verbose"
    echo "   • Check logs: ~/.dotfiles/logs/install.log"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Show help for installation failures
show_failure_help() {
    echo ""
    log_error "❌ INSTALLATION FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    log_info "🔧 TROUBLESHOOTING STEPS:"
    echo "   1. Check the error messages above for specific issues"
    echo "   2. Verify you have required permissions: ls -la ~"
    echo "   3. Ensure internet connectivity for package downloads"
    echo "   4. Try running with verbose output: $0 --verbose"
    echo "   5. Use dry-run mode to test: $0 --dry-run --verbose"
    
    echo ""
    log_info "🆘 GETTING HELP:"
    echo "   • View troubleshooting guide: $0 help troubleshooting"
    echo "   • Check common issues: $0 help examples"
    echo "   • Enable debug logging: DEBUG=1 $0 --verbose"
    echo "   • Review documentation in docs/ directory"
    
    echo ""
    log_info "🔄 RECOVERY OPTIONS:"
    echo "   • Restore from backup: $0 restore [backup-id]"
    echo "   • List available backups: $0 list-backups"
    echo "   • Try installing individual modules: $0 --modules git"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Legacy interactive module selection (kept for compatibility)
select_modules_interactively() {
    local selected_modules_var_name="$1"
    
    # Use the enhanced interactive module selection
    interactive_module_selection "$selected_modules_var_name"
}

# Main execution
main() {
    # Set up logging
    setup_logging "$VERBOSE"
    
    log_debug "Script started with arguments: $*"
    
    # Parse command line arguments
    local command
    parse_arguments "$@"
    command="$PARSED_COMMAND"
    
    log_debug "Executing command: $command"
    
    # Execute the appropriate command
    case "$command" in
        install)
            main_install
            ;;
        wizard)
            main_wizard
            ;;
        update)
            main_update
            ;;
        backup)
            main_backup
            ;;
        restore)
            main_restore "$RESTORE_BACKUP_ID"
            ;;
        list-modules)
            main_list_modules
            ;;
        list-backups)
            main_list_backups
            ;;
        cleanup)
            main_cleanup
            ;;
        version)
            main_version
            ;;
        status)
            main_status
            ;;
        help)
            if [[ -n "$HELP_TOPIC" ]]; then
                show_help_topic "$HELP_TOPIC"
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

# Clean up old backups and cache
main_cleanup() {
    log_info "Cleaning up old backups and cache..."
    
    # Initialize update system for cleanup functions
    if ! init_update_system; then
        log_error "Failed to initialize update system"
        return 1
    fi
    
    # Run cleanup
    if cleanup_unused_configs false; then
        log_success "Cleanup completed successfully!"
    else
        log_error "Cleanup completed with some failures"
        return 1
    fi
}

# Show current version
main_version() {
    # Initialize version system
    if ! init_version_system; then
        log_error "Failed to initialize version system"
        return 1
    fi
    
    local current_version
    current_version=$(get_framework_version)
    echo "Unified Dotfiles Framework version: $current_version"
}

# Show framework status
main_status() {
    log_info "Framework Status"
    
    # Initialize systems
    if ! init_update_system; then
        log_error "Failed to initialize update system"
        return 1
    fi
    
    if ! init_version_system; then
        log_error "Failed to initialize version system"
        return 1
    fi
    
    # Show version status
    show_version_status
    
    echo ""
    
    # Check for updates
    check_for_updates false
    if [[ "$UPDATE_AVAILABLE" == "true" ]]; then
        log_info "🔄 Update available: $CURRENT_VERSION → $LATEST_VERSION"
        log_info "Run '$0 update' to update to the latest version"
    else
        log_info "✅ Framework is up to date"
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi