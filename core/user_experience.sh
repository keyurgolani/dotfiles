#!/bin/bash

# Unified Dotfiles Framework - User Experience
# Handles user interaction, wizards, and experience improvements

# Configuration wizard
run_configuration_wizard() {
    local output_file="$1"
    
    echo ""
    log_info "🧙 CONFIGURATION WIZARD"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Welcome! This wizard will help you configure your dotfiles framework."
    echo ""
    
    # Collect user information
    local user_name user_email github_username
    
    echo "👤 User Information"
    echo "─────────────────────"
    echo "This information will be used for git configuration and other tools."
    echo ""
    
    # Get current git config if available
    local current_git_name current_git_email
    if command -v git >/dev/null 2>&1; then
        current_git_name=$(git config --global user.name 2>/dev/null || echo "")
        current_git_email=$(git config --global user.email 2>/dev/null || echo "")
        
        if [[ -n "$current_git_name" ]]; then
            echo "Current git user name: $current_git_name"
        fi
        if [[ -n "$current_git_email" ]]; then
            echo "Current git user email: $current_git_email"
        fi
        echo ""
    fi
    
    # Prompt for user name with current value as default
    if [[ -n "$current_git_name" ]]; then
        read -r -p "Your full name [$current_git_name]: " user_name
        user_name="${user_name:-$current_git_name}"
    else
        read -r -p "Your full name: " user_name
    fi
    
    # Prompt for email with validation
    while true; do
        if [[ -n "$current_git_email" ]]; then
            read -r -p "Your email address [$current_git_email]: " user_email
            user_email="${user_email:-$current_git_email}"
        else
            read -r -p "Your email address: " user_email
        fi
        
        if [[ -z "$user_email" ]] || is_valid_email "$user_email"; then
            break
        else
            echo "Please enter a valid email address."
        fi
    done
    
    read -r -p "GitHub username (optional): " github_username
    
    echo ""
    
    # Module selection
    echo "📦 Module Selection"
    echo "──────────────────"
    echo "Select the modules you'd like to install:"
    echo ""
    
    local selected_modules=()
    
    # Show available modules with descriptions
    for i in "${!AVAILABLE_MODULES[@]}"; do
        local module="${AVAILABLE_MODULES[$i]}"
        local description
        description=$(get_module_description "$module")
        
        echo "  $((i+1)). $module - $description"
    done
    
    echo ""
    echo "Enter module numbers (e.g., 1,2,3), 'all' for all modules, or 'recommended' for essential modules:"
    read -r module_selection
    
    case "$module_selection" in
        all)
            selected_modules=("${AVAILABLE_MODULES[@]}")
            ;;
        recommended)
            selected_modules=("shell" "git")
            # Add other modules if they exist
            for module in "vim" "tmux"; do
                if array_contains "$module" "${AVAILABLE_MODULES[@]}"; then
                    selected_modules+=("$module")
                fi
            done
            ;;
        *)
            IFS=',' read -ra indices <<< "$module_selection"
            for index in "${indices[@]}"; do
                index=$(echo "$index" | tr -d ' ')
                if [[ "$index" =~ ^[0-9]+$ ]] && [[ $index -ge 1 && $index -le ${#AVAILABLE_MODULES[@]} ]]; then
                    local module="${AVAILABLE_MODULES[$((index-1))]}"
                    selected_modules+=("$module")
                fi
            done
            ;;
    esac
    
    echo ""
    
    # Performance preferences
    echo "⚡ Performance Preferences"
    echo "─────────────────────────"
    
    local enable_parallel enable_cache enable_progress
    
    if confirm "Enable parallel installation for faster setup?" "y"; then
        enable_parallel="true"
    else
        enable_parallel="false"
    fi
    
    if confirm "Enable download caching to speed up repeated installations?" "y"; then
        enable_cache="true"
    else
        enable_cache="false"
    fi
    
    if confirm "Show progress indicators during installation?" "y"; then
        enable_progress="true"
    else
        enable_progress="false"
    fi
    
    echo ""
    
    # Backup preferences
    echo "💾 Backup Preferences"
    echo "────────────────────"
    
    local enable_backup backup_retention
    
    if confirm "Enable automatic backups of existing dotfiles?" "y"; then
        enable_backup="true"
        
        echo "How many days should backups be retained? (default: 30)"
        read -r backup_retention
        if [[ ! "$backup_retention" =~ ^[0-9]+$ ]]; then
            backup_retention="30"
        fi
    else
        enable_backup="false"
        backup_retention="30"
    fi
    
    echo ""
    
    # Apply git configuration immediately if git is available
    if [[ -n "$user_name" && -n "$user_email" ]] && command -v git >/dev/null 2>&1; then
        echo ""
        log_info "Applying git configuration..."
        
        git config --global user.name "$user_name"
        git config --global user.email "$user_email"
        
        # Verify configuration
        local set_name set_email
        set_name=$(git config --global user.name 2>/dev/null || echo "")
        set_email=$(git config --global user.email 2>/dev/null || echo "")
        
        if [[ "$set_name" == "$user_name" && "$set_email" == "$user_email" ]]; then
            log_success "✅ Git user configuration applied successfully"
        else
            log_warn "⚠️  Git configuration may not have been set correctly"
        fi
    fi
    
    # Generate configuration
    log_info "Generating configuration file..."
    
    generate_wizard_config "$output_file" \
        "$user_name" "$user_email" "$github_username" \
        "${selected_modules[@]}" \
        "$enable_parallel" "$enable_cache" "$enable_progress" \
        "$enable_backup" "$backup_retention"
    
    echo ""
    log_success "Configuration wizard completed!"
    echo "Configuration saved to: $output_file"
    
    return 0
}

# Get module description
get_module_description() {
    local module_name="$1"
    local module_dir="$MODULES_DIR/$module_name"
    
    # Try to get description from module.yaml
    local module_config="$module_dir/module.yaml"
    if [[ -f "$module_config" ]]; then
        local description
        description=$(get_yaml_value "$module_config" "description" "")
        if [[ -n "$description" ]]; then
            echo "$description"
            return 0
        fi
    fi
    
    # Fallback descriptions
    case "$module_name" in
        shell)
            echo "Shell configuration (bash/zsh aliases, functions, prompt)"
            ;;
        git)
            echo "Git configuration, aliases, and global settings"
            ;;
        vim)
            echo "Vim editor configuration and plugins"
            ;;
        tmux)
            echo "Terminal multiplexer configuration"
            ;;
        homebrew)
            echo "Homebrew package manager setup (macOS)"
            ;;
        developer-tools)
            echo "Essential development tools and utilities"
            ;;
        *)
            echo "Configuration for $module_name"
            ;;
    esac
}

# Generate wizard configuration file
generate_wizard_config() {
    local output_file="$1"
    local user_name="$2"
    local user_email="$3"
    local github_username="$4"
    shift 4
    
    # Get remaining parameters
    local modules=()
    local enable_parallel enable_cache enable_progress enable_backup backup_retention
    
    # Extract modules (everything until we hit the boolean flags)
    while [[ $# -gt 5 ]]; do
        modules+=("$1")
        shift
    done
    
    enable_parallel="$1"
    enable_cache="$2"
    enable_progress="$3"
    enable_backup="$4"
    backup_retention="$5"
    
    # Create configuration file
    cat > "$output_file" << EOF
# Configuration generated by wizard on $(date)

user:
  name: "$user_name"
  email: "$user_email"
  github_username: "$github_username"

modules:
  enabled:
$(for module in "${modules[@]}"; do echo "    - $module"; done)
  disabled: []

settings:
  backup_enabled: $enable_backup
  backup_retention_days: $backup_retention
  interactive_mode: false
  parallel_installation: $enable_parallel

performance:
  enable_parallel_installation: $enable_parallel
  enable_download_cache: $enable_cache
  enable_platform_cache: true
  enable_progress_indicators: $enable_progress
  shell_startup_optimization: true
  max_parallel_jobs: 4
  cache_ttl_seconds: 3600
EOF
    
    log_debug "Wizard configuration written to: $output_file"
}

# Show welcome message
show_welcome_message() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🏠 Unified Dotfiles Framework                             ║"
    echo "║                                                                              ║"
    echo "║  A comprehensive, cross-platform dotfiles management system                 ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        echo "Welcome! This installer will help you set up your development environment."
        echo ""
        
        # Show platform information
        echo "Detected platform: $DETECTED_OS"
        if [[ "$DETECTED_DISTRO" != "n/a" ]]; then
            echo "Distribution: $DETECTED_DISTRO $DETECTED_VERSION"
        fi
        echo "Architecture: $DETECTED_ARCH"
        echo "Shell: $DETECTED_SHELL"
        echo ""
        
        # Show quick start options
        echo "Quick start options:"
        echo "  • Press Enter to continue with interactive setup"
        echo "  • Type 'wizard' to run the configuration wizard"
        echo "  • Type 'help' to see all available options"
        echo ""
        
        read -r -p "Press Enter to continue or type an option: " quick_option
        
        case "$quick_option" in
            wizard)
                WIZARD_MODE=true
                ;;
            help)
                show_usage
                exit 0
                ;;
            "")
                # Continue with normal flow
                ;;
        esac
    fi
}

# Interactive user configuration setup
interactive_user_configuration() {
    echo ""
    log_info "👤 USER CONFIGURATION SETUP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Let's configure your user information for git and other tools."
    echo ""
    
    local user_name user_email github_username
    local current_git_name current_git_email
    local needs_git_config=false
    
    # Check current git configuration
    if command -v git >/dev/null 2>&1; then
        current_git_name=$(git config --global user.name 2>/dev/null || echo "")
        current_git_email=$(git config --global user.email 2>/dev/null || echo "")
        
        if [[ -z "$current_git_name" || -z "$current_git_email" ]]; then
            needs_git_config=true
            echo "⚠️  Git user information is not fully configured."
        else
            echo "✅ Current git configuration:"
            echo "   Name: $current_git_name"
            echo "   Email: $current_git_email"
        fi
        echo ""
    fi
    
    # Ask if user wants to configure/update information
    local should_configure=false
    if [[ "$needs_git_config" == "true" ]]; then
        if confirm "Would you like to configure your git user information now?" "y"; then
            should_configure=true
        fi
    else
        if confirm "Would you like to update your user configuration?" "n"; then
            should_configure=true
        fi
    fi
    
    if [[ "$should_configure" == "true" ]]; then
        echo ""
        echo "📝 Enter your information:"
        echo ""
        
        # Get user name
        if [[ -n "$current_git_name" ]]; then
            read -r -p "Full name [$current_git_name]: " user_name
            user_name="${user_name:-$current_git_name}"
        else
            while [[ -z "$user_name" ]]; do
                read -r -p "Full name: " user_name
                if [[ -z "$user_name" ]]; then
                    echo "Name is required for git configuration."
                fi
            done
        fi
        
        # Get email with validation
        while true; do
            if [[ -n "$current_git_email" ]]; then
                read -r -p "Email address [$current_git_email]: " user_email
                user_email="${user_email:-$current_git_email}"
            else
                read -r -p "Email address: " user_email
            fi
            
            if [[ -z "$user_email" ]]; then
                echo "Email is required for git configuration."
                continue
            elif is_valid_email "$user_email"; then
                break
            else
                echo "Please enter a valid email address."
            fi
        done
        
        # Get GitHub username (optional)
        read -r -p "GitHub username (optional): " github_username
        
        echo ""
        
        # Apply git configuration immediately
        if command -v git >/dev/null 2>&1; then
            log_info "Configuring git..."
            
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "Would set git config user.name to: $user_name"
                log_info "Would set git config user.email to: $user_email"
            else
                git config --global user.name "$user_name"
                git config --global user.email "$user_email"
                log_success "Git user configuration updated!"
                
                # Verify the configuration was set
                local set_name set_email
                set_name=$(git config --global user.name 2>/dev/null || echo "")
                set_email=$(git config --global user.email 2>/dev/null || echo "")
                
                if [[ "$set_name" == "$user_name" && "$set_email" == "$user_email" ]]; then
                    log_success "✅ Git configuration verified successfully"
                else
                    log_warn "⚠️  Git configuration may not have been set correctly"
                fi
            fi
        fi
        
        # Update user configuration file
        update_user_config_file "$user_name" "$user_email" "$github_username"
        
        echo ""
        log_success "User configuration completed!"
    else
        log_info "Skipping user configuration setup."
    fi
    
    return 0
}

# Update user configuration file
update_user_config_file() {
    local user_name="$1"
    local user_email="$2"
    local github_username="$3"
    local user_config_file="$SCRIPT_DIR/config/user.yaml"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would update user configuration file: $user_config_file"
        return 0
    fi
    
    # Create backup of existing config
    if [[ -f "$user_config_file" ]]; then
        cp "$user_config_file" "${user_config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Update the user section in the config file
    local temp_file
    temp_file=$(mktemp)
    
    # Read existing config and update user section
    if [[ -f "$user_config_file" ]]; then
        awk -v name="$user_name" -v email="$user_email" -v github="$github_username" '
        BEGIN { in_user_section = 0 }
        /^user:/ { 
            in_user_section = 1
            print $0
            print "  name: \"" name "\""
            print "  email: \"" email "\""
            if (github != "") {
                print "  github_username: \"" github "\""
            } else {
                print "  github_username: \"\""
            }
            next
        }
        /^[a-zA-Z_]/ && in_user_section { in_user_section = 0 }
        !in_user_section || !/^  (name|email|github_username):/ { print }
        ' "$user_config_file" > "$temp_file"
    else
        # Create new config file
        cat > "$temp_file" << EOF
# User-specific configuration for Unified Dotfiles Framework
user:
  name: "$user_name"
  email: "$user_email"
  github_username: "$github_username"
  shell: "\${SHELL##*/}"
  editor: "\${EDITOR:-vim}"
  timezone: "\${TZ:-}"

preferences:
  theme: "\${THEME:-auto}"
  color_scheme: "\${COLOR_SCHEME:-}"
  font_family: "\${FONT_FAMILY:-}"
  font_size: 12

modules:
  enabled: []
  disabled: []

settings:
  backup_enabled: true
  interactive_mode: true
  log_level: "\${LOG_LEVEL:-info}"
EOF
    fi
    
    mv "$temp_file" "$user_config_file"
    log_debug "Updated user configuration file: $user_config_file"
}

# Enhanced interactive setup with comprehensive configuration
interactive_setup_complete() {
    local modules=("$@")
    
    echo ""
    log_info "🎯 INTERACTIVE SETUP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Welcome to the interactive dotfiles setup! This will guide you through"
    echo "configuring your development environment step by step."
    echo ""
    
    # First, handle user configuration
    interactive_user_configuration
    
    # Then handle module selection if no modules were specified
    if [[ ${#modules[@]} -eq 0 ]]; then
        echo ""
        local selected_modules=()
        interactive_module_selection selected_modules
        
        # Update the modules array reference
        for module in "${selected_modules[@]}"; do
            modules+=("$module")
        done
    fi
    
    # Additional configuration options
    echo ""
    log_info "⚙️  ADDITIONAL CONFIGURATION"
    echo "─────────────────────────────────"
    
    # Ask about backup preferences
    if confirm "Would you like to enable automatic backups of existing dotfiles?" "y"; then
        log_info "✅ Automatic backups enabled"
        # This will be handled by the existing backup system
    else
        log_info "⚠️  Automatic backups disabled"
    fi
    
    # Ask about performance optimizations
    if confirm "Enable performance optimizations (parallel installation, caching)?" "y"; then
        log_info "✅ Performance optimizations enabled"
        # These are already enabled by default in the configuration
    else
        log_info "⚪ Using standard installation speed"
    fi
    
    echo ""
    log_success "Interactive setup configuration completed!"
    
    return 0
}

# Show completion message
show_completion_message() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                          🎉 Installation Complete!                          ║"
    echo "║                                                                              ║"
    echo "║  Your dotfiles have been successfully installed and configured.              ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "🚀 Next steps:"
    echo "  1. Restart your terminal or run: source ~/.${DETECTED_SHELL}rc"
    echo "  2. Verify everything is working: which git && git --version"
    echo "  3. Customize your configuration files as needed"
    echo ""
    
    echo "📚 Useful commands:"
    echo "  • Update framework: $0 update"
    echo "  • Create backup: $0 backup"
    echo "  • List modules: $0 list-modules"
    echo "  • Get help: $0 help"
    echo ""
    
    echo "Happy coding! 🎯"
    echo ""
}