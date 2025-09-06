#!/bin/bash

# 🎯 Unified Dotfiles Framework - Single Entry Point
# A beautiful, interactive interface for all dotfiles operations

set -eo pipefail  # Removed -u flag to allow undefined variables

# Script directory and core paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="${SCRIPT_DIR}/core"
export DOTFILES_ROOT="$SCRIPT_DIR"

# Source core utilities
source "${CORE_DIR}/logger.sh"
source "${CORE_DIR}/utils.sh"

# Additional formatting (colors are defined in logger.sh)
BOLD='\033[1m'
DIM='\033[2m'

# Unicode symbols
readonly ROCKET="🚀"
readonly GEAR="⚙️"
readonly PACKAGE="📦"
readonly HOOK="🪝"
readonly WRENCH="🔧"
readonly BACKUP="💾"
readonly UPDATE="⬆️"
readonly CLEAN="🧹"
readonly INFO="ℹ️"
readonly SUCCESS="✅"
readonly WARNING="⚠️"
readonly ERROR="❌"

# Version
readonly VERSION="1.0.0"

# Show beautiful header
show_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    🎯 Unified Dotfiles Framework                                             ║
║    Your one-stop solution for development environment management             ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${DIM}Cross-platform • Modular • Secure • Fast${NC}"
    echo ""
}

# Show main menu
show_main_menu() {
    echo -e "${WHITE}${BOLD}What would you like to do?${NC}"
    echo ""
    
    echo -e "${GREEN}${BOLD}🚀 GETTING STARTED${NC}"
    echo -e "  ${CYAN}1)${NC} ${BOLD}Install & Setup${NC}     ${DIM}Set up your dotfiles with guided installation${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}Configuration Wizard${NC} ${DIM}First-time setup with step-by-step guidance${NC}"
    echo ""
    
    echo -e "${BLUE}${BOLD}📦 MODULES & PACKAGES${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}Manage Modules${NC}      ${DIM}Install, update, or configure shell, git, vim, etc.${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Browse Available${NC}    ${DIM}See all available modules and their features${NC}"
    echo ""
    
    echo -e "${PURPLE}${BOLD}🔧 MAINTENANCE${NC}"
    echo -e "  ${CYAN}5)${NC} ${BOLD}Update Framework${NC}    ${DIM}Update to latest version and refresh modules${NC}"
    echo -e "  ${CYAN}6)${NC} ${BOLD}Backup & Restore${NC}   ${DIM}Create backups or restore from previous state${NC}"
    echo -e "  ${CYAN}7)${NC} ${BOLD}System Cleanup${NC}     ${DIM}Clean old files, cache, and unused configurations${NC}"
    echo ""
    
    echo -e "${YELLOW}${BOLD}⚙️ ADVANCED${NC}"
    echo -e "  ${CYAN}8)${NC} ${BOLD}Hook Management${NC}     ${DIM}Create custom automation hooks and scripts${NC}"
    echo -e "  ${CYAN}9)${NC} ${BOLD}Plugin System${NC}      ${DIM}Extend functionality with community plugins${NC}"
    echo -e " ${CYAN}10)${NC} ${BOLD}System Status${NC}      ${DIM}View framework status and health information${NC}"
    echo ""
    
    echo -e "${DIM}${BOLD}OTHER OPTIONS${NC}"
    echo -e " ${CYAN}11)${NC} ${BOLD}Help & Documentation${NC} ${DIM}Access guides, troubleshooting, and examples${NC}"
    echo -e "  ${CYAN}q)${NC} ${BOLD}Quit${NC}              ${DIM}Exit the dotfiles manager${NC}"
    echo ""
}

# Safe read function that handles EOF gracefully
safe_read() {
    local prompt="$1"
    local var_name="$2"
    local input
    
    echo -ne "$prompt" >&2
    
    # Check if stdin is available
    if [[ ! -t 0 ]]; then
        # Non-interactive mode - read with timeout
        if read -r -t 1 input 2>/dev/null; then
            # Check for empty input which indicates EOF
            if [[ -z "$input" ]]; then
                return 1
            fi
            # Use printf to assign to the variable name
            printf -v "$var_name" '%s' "$input"
            return 0
        else
            return 1
        fi
    else
        # Interactive mode - normal read
        if read -r input; then
            # Use printf to assign to the variable name
            printf -v "$var_name" '%s' "$input"
            return 0
        else
            return 1
        fi
    fi
}

# Get user choice with validation
get_user_choice() {
    local choice
    local attempts=0
    local max_attempts=5
    
    while [[ $attempts -lt $max_attempts ]]; do
        if safe_read "${WHITE}${BOLD}Enter your choice [1-11, q]: ${NC}" choice; then
            case "$choice" in
                [1-9]|10|11|q|Q)
                    echo "$choice"
                    return 0
                    ;;
                *)
                    echo -e "${RED}${ERROR} Invalid choice. Please enter a number between 1-11 or 'q' to quit.${NC}" >&2
                    echo "" >&2
                    ((attempts++))
                    ;;
            esac
        else
            # EOF or read error - exit gracefully
            echo "" >&2
            echo -e "${YELLOW}${WARNING} Input stream ended. Exiting...${NC}" >&2
            exit 0
        fi
    done
    
    # Too many invalid attempts
    echo -e "${RED}${ERROR} Too many invalid attempts. Exiting...${NC}" >&2
    exit 1
}

# Handle install & setup
handle_install_setup() {
    show_section_header "🚀 Install & Setup"
    
    echo -e "${WHITE}Choose your installation approach:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}Quick Start${NC}        ${DIM}Install essential modules (shell, git, vim)${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}Interactive Setup${NC}  ${DIM}Choose modules interactively with descriptions${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}Custom Selection${NC}   ${DIM}Specify exact modules you want${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Preview Mode${NC}       ${DIM}See what would be installed without changes${NC}"
    echo -e "  ${CYAN}b)${NC} ${BOLD}Back to Main Menu${NC}"
    echo ""
    
    local choice
    if ! safe_read "${WHITE}${BOLD}Enter your choice [1-4, b]: ${NC}" choice; then
        # EOF or read error - return to main menu
        echo ""
        echo -e "${YELLOW}${WARNING} Input stream ended. Returning to main menu...${NC}"
        return 0
    fi
    
    case "$choice" in
        1)
            echo -e "${GREEN}${SUCCESS} Starting quick installation...${NC}"
            ./scripts/install.sh --modules shell,git,vim
            ;;
        2)
            echo -e "${GREEN}${SUCCESS} Starting interactive setup...${NC}"
            ./scripts/install.sh
            ;;
        3)
            echo ""
            echo -e "${WHITE}Enter modules separated by commas (e.g., shell,git,vim,tmux):${NC}"
            echo -ne "${CYAN}Modules: ${NC}"
            read -r modules
            if [[ -n "$modules" ]]; then
                ./scripts/install.sh --modules "$modules"
            else
                echo -e "${RED}${ERROR} No modules specified${NC}"
            fi
            ;;
        4)
            echo -e "${BLUE}${INFO} Running preview mode...${NC}"
            ./scripts/install.sh --dry-run --verbose
            ;;
        b|B)
            return 0
            ;;
        *)
            echo -e "${RED}${ERROR} Invalid choice${NC}"
            ;;
    esac
    
    pause_for_user
}

# Handle configuration wizard
handle_wizard() {
    show_section_header "🧙 Configuration Wizard"
    
    echo -e "${WHITE}The configuration wizard will guide you through:${NC}"
    echo ""
    echo -e "  ${SUCCESS} User information setup (name, email, GitHub)"
    echo -e "  ${SUCCESS} Git configuration"
    echo -e "  ${SUCCESS} Module selection with descriptions"
    echo -e "  ${SUCCESS} Platform-specific optimizations"
    echo -e "  ${SUCCESS} Backup preferences"
    echo ""
    
    if confirm "Ready to start the configuration wizard?"; then
        ./scripts/install.sh wizard
    fi
    
    pause_for_user
}

# Handle module management
handle_modules() {
    show_section_header "📦 Module Management"
    
    echo -e "${WHITE}Module management options:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}List Installed${NC}      ${DIM}Show currently installed modules${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}Install New${NC}        ${DIM}Add new modules to your setup${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}Update Modules${NC}     ${DIM}Update existing modules to latest versions${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Shell Utilities${NC}    ${DIM}Manage shell aliases, plugins, and configurations${NC}"
    echo -e "  ${CYAN}b)${NC} ${BOLD}Back to Main Menu${NC}"
    echo ""
    
    local choice
    echo -ne "${WHITE}${BOLD}Enter your choice [1-4, b]: ${NC}"
    read -r choice
    
    case "$choice" in
        1)
            echo -e "${BLUE}${INFO} Listing installed modules...${NC}"
            ./scripts/install.sh list-modules
            ;;
        2)
            echo -e "${GREEN}${SUCCESS} Starting module installation...${NC}"
            ./scripts/install.sh
            ;;
        3)
            echo -e "${BLUE}${INFO} Updating modules...${NC}"
            ./scripts/maintenance.sh update modules
            ;;
        4)
            handle_shell_utilities
            ;;
        b|B)
            return 0
            ;;
        *)
            echo -e "${RED}${ERROR} Invalid choice${NC}"
            ;;
    esac
    
    pause_for_user
}

# Handle shell utilities
handle_shell_utilities() {
    show_section_header "🐚 Shell Utilities"
    
    echo -e "${WHITE}Shell configuration options:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}Install ZSH Plugins${NC}    ${DIM}Add syntax highlighting, autosuggestions, etc.${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}Setup Work Aliases${NC}     ${DIM}Create work-specific aliases (safely gitignored)${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}List Current Aliases${NC}   ${DIM}Show all currently loaded aliases${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Reload Configuration${NC}   ${DIM}Refresh shell configurations${NC}"
    echo -e "  ${CYAN}b)${NC} ${BOLD}Back to Module Menu${NC}"
    echo ""
    
    local choice
    echo -ne "${WHITE}${BOLD}Enter your choice [1-4, b]: ${NC}"
    read -r choice
    
    case "$choice" in
        1)
            echo -e "${GREEN}${SUCCESS} Installing ZSH plugins...${NC}"
            ./scripts/module_cli.sh shell install-plugins
            ;;
        2)
            echo -e "${GREEN}${SUCCESS} Setting up work aliases...${NC}"
            ./scripts/module_cli.sh shell setup-work-aliases
            ;;
        3)
            echo -e "${BLUE}${INFO} Listing current aliases...${NC}"
            ./scripts/module_cli.sh shell list-aliases
            ;;
        4)
            echo -e "${BLUE}${INFO} Reloading shell configuration...${NC}"
            ./scripts/module_cli.sh shell reload-aliases
            ;;
        b|B)
            return 0
            ;;
        *)
            echo -e "${RED}${ERROR} Invalid choice${NC}"
            ;;
    esac
    
    pause_for_user
}

# Handle browse available modules
handle_browse_modules() {
    show_section_header "📋 Available Modules"
    
    echo -e "${BLUE}${INFO} Loading available modules...${NC}"
    echo ""
    
    ./scripts/install.sh list-modules
    
    pause_for_user
}

# Handle updates
handle_updates() {
    show_section_header "⬆️ Update Framework"
    
    echo -e "${WHITE}Update options:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}Check for Updates${NC}   ${DIM}See what updates are available${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}Update Framework${NC}    ${DIM}Update to the latest framework version${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}Update Modules${NC}      ${DIM}Update all installed modules${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Update Everything${NC}   ${DIM}Update both framework and modules${NC}"
    echo -e "  ${CYAN}b)${NC} ${BOLD}Back to Main Menu${NC}"
    echo ""
    
    local choice
    echo -ne "${WHITE}${BOLD}Enter your choice [1-4, b]: ${NC}"
    read -r choice
    
    case "$choice" in
        1)
            echo -e "${BLUE}${INFO} Checking for updates...${NC}"
            ./scripts/maintenance.sh update check
            ;;
        2)
            echo -e "${GREEN}${SUCCESS} Updating framework...${NC}"
            ./scripts/maintenance.sh update framework
            ;;
        3)
            echo -e "${GREEN}${SUCCESS} Updating modules...${NC}"
            ./scripts/maintenance.sh update modules
            ;;
        4)
            echo -e "${GREEN}${SUCCESS} Updating everything...${NC}"
            ./scripts/maintenance.sh update framework
            ./scripts/maintenance.sh update modules
            ;;
        b|B)
            return 0
            ;;
        *)
            echo -e "${RED}${ERROR} Invalid choice${NC}"
            ;;
    esac
    
    pause_for_user
}

# Handle backup & restore
handle_backup_restore() {
    show_section_header "💾 Backup & Restore"
    
    echo -e "${WHITE}Backup and restore options:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}Create Backup${NC}       ${DIM}Save current configuration state${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}List Backups${NC}        ${DIM}Show all available backups${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}Restore Backup${NC}      ${DIM}Restore from a previous backup${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Auto Backup${NC}         ${DIM}Create automatic backup before changes${NC}"
    echo -e "  ${CYAN}b)${NC} ${BOLD}Back to Main Menu${NC}"
    echo ""
    
    local choice
    echo -ne "${WHITE}${BOLD}Enter your choice [1-4, b]: ${NC}"
    read -r choice
    
    case "$choice" in
        1)
            echo -e "${GREEN}${SUCCESS} Creating backup...${NC}"
            ./scripts/install.sh backup
            ;;
        2)
            echo -e "${BLUE}${INFO} Listing available backups...${NC}"
            ./scripts/install.sh list-backups
            ;;
        3)
            echo -e "${BLUE}${INFO} Available backups:${NC}"
            ./scripts/install.sh list-backups
            echo ""
            echo -ne "${WHITE}Enter backup ID to restore: ${NC}"
            read -r backup_id
            if [[ -n "$backup_id" ]]; then
                ./scripts/install.sh restore "$backup_id"
            else
                echo -e "${RED}${ERROR} No backup ID specified${NC}"
            fi
            ;;
        4)
            echo -e "${GREEN}${SUCCESS} Creating automatic backup...${NC}"
            ./scripts/maintenance.sh backup
            ;;
        b|B)
            return 0
            ;;
        *)
            echo -e "${RED}${ERROR} Invalid choice${NC}"
            ;;
    esac
    
    pause_for_user
}

# Handle system cleanup
handle_cleanup() {
    show_section_header "🧹 System Cleanup"
    
    echo -e "${WHITE}Cleanup options:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}Preview Cleanup${NC}     ${DIM}See what would be cleaned without doing it${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}Clean Everything${NC}    ${DIM}Clean cache, old backups, and orphaned files${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}Clean Cache Only${NC}    ${DIM}Remove cached downloads and temporary files${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Clean Old Backups${NC}   ${DIM}Remove backups older than retention period${NC}"
    echo -e "  ${CYAN}b)${NC} ${BOLD}Back to Main Menu${NC}"
    echo ""
    
    local choice
    echo -ne "${WHITE}${BOLD}Enter your choice [1-4, b]: ${NC}"
    read -r choice
    
    case "$choice" in
        1)
            echo -e "${BLUE}${INFO} Previewing cleanup actions...${NC}"
            ./scripts/maintenance.sh cleanup --dry-run
            ;;
        2)
            if confirm "This will clean up cache, old backups, and orphaned files. Continue?"; then
                ./scripts/maintenance.sh cleanup
            fi
            ;;
        3)
            echo -e "${GREEN}${SUCCESS} Cleaning cache...${NC}"
            ./scripts/maintenance.sh cleanup cache
            ;;
        4)
            echo -e "${GREEN}${SUCCESS} Cleaning old backups...${NC}"
            ./scripts/maintenance.sh cleanup backups
            ;;
        b|B)
            return 0
            ;;
        *)
            echo -e "${RED}${ERROR} Invalid choice${NC}"
            ;;
    esac
    
    pause_for_user
}

# Handle hook management
handle_hooks() {
    show_section_header "🪝 Hook Management"
    
    echo -e "${WHITE}Hook management allows you to create custom automation:${NC}"
    echo ""
    echo -e "${DIM}Examples:${NC}"
    echo -e "${DIM}• Run tests automatically when saving code${NC}"
    echo -e "${DIM}• Update translations when strings change${NC}"
    echo -e "${DIM}• Backup before major changes${NC}"
    echo ""
    
    echo -e "  ${CYAN}1)${NC} ${BOLD}List Hooks${NC}          ${DIM}Show all available hooks${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}Create Hook${NC}         ${DIM}Create a new automation hook${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}Execute Hooks${NC}       ${DIM}Run hooks for testing${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Initialize System${NC}   ${DIM}Set up hook system for first time${NC}"
    echo -e "  ${CYAN}b)${NC} ${BOLD}Back to Main Menu${NC}"
    echo ""
    
    local choice
    echo -ne "${WHITE}${BOLD}Enter your choice [1-4, b]: ${NC}"
    read -r choice
    
    case "$choice" in
        1)
            echo -e "${BLUE}${INFO} Listing hooks...${NC}"
            ./scripts/hooks_cli.sh list
            ;;
        2)
            echo -e "${GREEN}${SUCCESS} Creating new hook...${NC}"
            echo ""
            echo -e "${WHITE}Hook type (e.g., pre_install, post_install): ${NC}"
            read -r hook_type
            echo -e "${WHITE}Hook name: ${NC}"
            read -r hook_name
            echo -e "${WHITE}Hook scope (global, module, environment): ${NC}"
            read -r hook_scope
            
            if [[ -n "$hook_type" && -n "$hook_name" && -n "$hook_scope" ]]; then
                ./scripts/hooks_cli.sh create "$hook_type" "$hook_name" "$hook_scope"
            else
                echo -e "${RED}${ERROR} All fields are required${NC}"
            fi
            ;;
        3)
            echo -e "${BLUE}${INFO} Available hook types: pre_install, post_install, pre_backup, post_backup${NC}"
            echo -ne "${WHITE}Hook type to execute: ${NC}"
            read -r hook_type
            if [[ -n "$hook_type" ]]; then
                ./scripts/hooks_cli.sh execute "$hook_type" --dry-run
            fi
            ;;
        4)
            echo -e "${GREEN}${SUCCESS} Initializing hook system...${NC}"
            ./scripts/hooks_cli.sh init
            ;;
        b|B)
            return 0
            ;;
        *)
            echo -e "${RED}${ERROR} Invalid choice${NC}"
            ;;
    esac
    
    pause_for_user
}

# Handle plugin system
handle_plugins() {
    show_section_header "🔌 Plugin System"
    
    echo -e "${WHITE}Plugin system extends framework functionality:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}List Plugins${NC}        ${DIM}Show available and installed plugins${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}Search Plugins${NC}      ${DIM}Find plugins by name or category${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}Install Plugin${NC}      ${DIM}Install a new plugin${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Plugin Status${NC}       ${DIM}Show plugin system status${NC}"
    echo -e "  ${CYAN}5)${NC} ${BOLD}Initialize System${NC}   ${DIM}Set up plugin system for first time${NC}"
    echo -e "  ${CYAN}b)${NC} ${BOLD}Back to Main Menu${NC}"
    echo ""
    
    local choice
    echo -ne "${WHITE}${BOLD}Enter your choice [1-5, b]: ${NC}"
    read -r choice
    
    case "$choice" in
        1)
            echo -e "${BLUE}${INFO} Listing plugins...${NC}"
            ./scripts/plugins_cli.sh list
            ;;
        2)
            echo -ne "${WHITE}Search query: ${NC}"
            read -r query
            if [[ -n "$query" ]]; then
                ./scripts/plugins_cli.sh search "$query"
            fi
            ;;
        3)
            echo -ne "${WHITE}Plugin name to install: ${NC}"
            read -r plugin_name
            if [[ -n "$plugin_name" ]]; then
                ./scripts/plugins_cli.sh install "$plugin_name"
            fi
            ;;
        4)
            echo -e "${BLUE}${INFO} Plugin system status...${NC}"
            ./scripts/plugins_cli.sh status
            ;;
        5)
            echo -e "${GREEN}${SUCCESS} Initializing plugin system...${NC}"
            ./scripts/plugins_cli.sh init
            ;;
        b|B)
            return 0
            ;;
        *)
            echo -e "${RED}${ERROR} Invalid choice${NC}"
            ;;
    esac
    
    pause_for_user
}

# Handle system status
handle_status() {
    show_section_header "📊 System Status"
    
    echo -e "${BLUE}${INFO} Gathering system information...${NC}"
    echo ""
    
    ./scripts/maintenance.sh status
    
    pause_for_user
}

# Handle help & documentation
handle_help() {
    show_section_header "📚 Help & Documentation"
    
    echo -e "${WHITE}Documentation and help options:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}Quick Start Guide${NC}   ${DIM}Essential commands and workflows${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}Module Documentation${NC} ${DIM}Detailed module information${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}Troubleshooting${NC}     ${DIM}Common issues and solutions${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Configuration Help${NC}  ${DIM}Configuration file format and options${NC}"
    echo -e "  ${CYAN}5)${NC} ${BOLD}Examples${NC}            ${DIM}Usage examples and workflows${NC}"
    echo -e "  ${CYAN}6)${NC} ${BOLD}View README${NC}         ${DIM}Complete project documentation${NC}"
    echo -e "  ${CYAN}b)${NC} ${BOLD}Back to Main Menu${NC}"
    echo ""
    
    local choice
    echo -ne "${WHITE}${BOLD}Enter your choice [1-6, b]: ${NC}"
    read -r choice
    
    case "$choice" in
        1)
            show_quick_start_guide
            ;;
        2)
            ./scripts/install.sh help modules
            ;;
        3)
            ./scripts/install.sh help troubleshooting
            ;;
        4)
            ./scripts/install.sh help configuration
            ;;
        5)
            ./scripts/install.sh help examples
            ;;
        6)
            if command -v less >/dev/null 2>&1; then
                less README.md
            else
                cat README.md
            fi
            ;;
        b|B)
            return 0
            ;;
        *)
            echo -e "${RED}${ERROR} Invalid choice${NC}"
            ;;
    esac
    
    pause_for_user
}

# Show quick start guide
show_quick_start_guide() {
    clear
    echo -e "${CYAN}${BOLD}🚀 Quick Start Guide${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}1. First Time Setup:${NC}"
    echo -e "   • Run the configuration wizard: ${CYAN}./dotfiles.sh${NC} → Choose option 2"
    echo -e "   • Or quick install essentials: ${CYAN}./dotfiles.sh${NC} → Choose option 1"
    echo ""
    
    echo -e "${WHITE}${BOLD}2. Essential Commands:${NC}"
    echo -e "   • Install modules: ${CYAN}./scripts/install.sh --modules shell,git,vim${NC}"
    echo -e "   • Update everything: ${CYAN}./scripts/maintenance.sh update${NC}"
    echo -e "   • Create backup: ${CYAN}./scripts/install.sh backup${NC}"
    echo -e "   • List modules: ${CYAN}./scripts/install.sh list-modules${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}3. Module Management:${NC}"
    echo -e "   • Shell utilities: ${CYAN}./scripts/module_cli.sh shell <command>${NC}"
    echo -e "   • Available modules: shell, git, vim, tmux, homebrew, developer-tools"
    echo ""
    
    echo -e "${WHITE}${BOLD}4. Advanced Features:${NC}"
    echo -e "   • Hooks: ${CYAN}./scripts/hooks_cli.sh <command>${NC}"
    echo -e "   • Plugins: ${CYAN}./scripts/plugins_cli.sh <command>${NC}"
    echo -e "   • Maintenance: ${CYAN}./scripts/maintenance.sh <command>${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}5. Getting Help:${NC}"
    echo -e "   • Any script help: ${CYAN}<script> --help${NC}"
    echo -e "   • Specific topics: ${CYAN}./install.sh help <topic>${NC}"
    echo -e "   • Documentation: ${CYAN}docs/${NC} directory"
    echo ""
    
    pause_for_user
}

# Show section header
show_section_header() {
    local title="$1"
    clear
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║${NC} ${WHITE}${BOLD}$title${NC}$(printf "%*s" $((76 - ${#title})) "")${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Confirmation helper
confirm() {
    local message="$1"
    local response
    
    if ! safe_read "${WHITE}${message} ${DIM}[y/N]:${NC} " response; then
        # EOF or read error - default to "no"
        echo ""
        return 1
    fi
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Pause for user input
pause_for_user() {
    echo ""
    local dummy
    if ! safe_read "${DIM}Press Enter to continue...${NC}" dummy; then
        # EOF or read error - just continue
        echo ""
    fi
}

# Show version information
show_version() {
    echo -e "${CYAN}${BOLD}Unified Dotfiles Framework${NC}"
    echo -e "Version: ${VERSION}"
    echo -e "Entry Point: ${SCRIPT_DIR}/dotfiles.sh"
    echo ""
}

# Main interactive loop
main_loop() {
    while true; do
        show_header
        show_main_menu
        
        local choice
        choice=$(get_user_choice)
        
        case "$choice" in
            1)
                handle_install_setup
                ;;
            2)
                handle_wizard
                ;;
            3)
                handle_modules
                ;;
            4)
                handle_browse_modules
                ;;
            5)
                handle_updates
                ;;
            6)
                handle_backup_restore
                ;;
            7)
                handle_cleanup
                ;;
            8)
                handle_hooks
                ;;
            9)
                handle_plugins
                ;;
            10)
                handle_status
                ;;
            11)
                handle_help
                ;;
            q|Q)
                echo ""
                echo -e "${GREEN}${SUCCESS} Thanks for using Unified Dotfiles Framework!${NC}"
                echo -e "${DIM}Your development environment is in good hands.${NC}"
                echo ""
                exit 0
                ;;
        esac
    done
}

# Handle command line arguments
handle_args() {
    case "${1:-}" in
        --version|-v)
            show_version
            exit 0
            ;;
        --help|-h)
            show_header
            echo -e "${WHITE}${BOLD}Usage:${NC}"
            echo -e "  ${CYAN}$0${NC}                 ${DIM}Start interactive mode${NC}"
            echo -e "  ${CYAN}$0 --version${NC}       ${DIM}Show version information${NC}"
            echo -e "  ${CYAN}$0 --help${NC}          ${DIM}Show this help message${NC}"
            echo ""
            echo -e "${WHITE}${BOLD}Interactive Mode:${NC}"
            echo -e "The main interface provides easy access to all framework features:"
            echo -e "• Installation and setup"
            echo -e "• Module management"
            echo -e "• Updates and maintenance"
            echo -e "• Advanced features (hooks, plugins)"
            echo -e "• Help and documentation"
            echo ""
            echo -e "${WHITE}${BOLD}Direct Access:${NC}"
            echo -e "You can also run individual scripts directly:"
            echo -e "• ${CYAN}./scripts/install.sh${NC} - Installation and module management"
            echo -e "• ${CYAN}./scripts/maintenance.sh${NC} - Updates and cleanup"
            echo -e "• ${CYAN}./scripts/module_cli.sh${NC} - Module-specific utilities"
            echo -e "• ${CYAN}./scripts/hooks_cli.sh${NC} - Hook management"
            echo -e "• ${CYAN}./scripts/plugins_cli.sh${NC} - Plugin system"
            echo ""
            exit 0
            ;;
        "")
            # No arguments, start interactive mode
            main_loop
            ;;
        *)
            echo -e "${RED}${ERROR} Unknown option: $1${NC}"
            echo -e "Use ${CYAN}$0 --help${NC} for usage information"
            exit 1
            ;;
    esac
}

# Main execution
main() {
    # Set up logging
    setup_logging
    
    # Handle command line arguments or start interactive mode
    handle_args "$@"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi