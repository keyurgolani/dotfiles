#!/bin/bash

# Unified Dotfiles Framework - Simple Module Management
# Basic module system for installation and management

# Module system variables
MODULES_DIR=""
AVAILABLE_MODULES=()
INSTALL_QUEUE=()
MODULE_DEPENDENCIES=()

# Initialize module system
init_module_system() {
    local framework_root="$1"
    
    MODULES_DIR="$framework_root/modules"
    
    if [[ ! -d "$MODULES_DIR" ]]; then
        log_error "Modules directory not found: $MODULES_DIR"
        return 1
    fi
    
    # Discover available modules
    discover_modules
    
    log_debug "Module system initialized with ${#AVAILABLE_MODULES[@]} modules"
    return 0
}

# Discover available modules
discover_modules() {
    AVAILABLE_MODULES=()
    
    if [[ ! -d "$MODULES_DIR" ]]; then
        return 1
    fi
    
    for module_dir in "$MODULES_DIR"/*; do
        if [[ -d "$module_dir" ]]; then
            local module_name
            module_name="$(basename "$module_dir")"
            
            # Skip hidden directories and .gitkeep
            if [[ "$module_name" == .* || "$module_name" == ".gitkeep" ]]; then
                continue
            fi
            
            # Check if module has required files
            if [[ -f "$module_dir/module.yaml" ]] || [[ -f "$module_dir/install.sh" ]]; then
                AVAILABLE_MODULES+=("$module_name")
                log_debug "Discovered module: $module_name"
            fi
        fi
    done
}

# List available modules
list_available_modules() {
    local format="${1:-simple}"
    
    if [[ ${#AVAILABLE_MODULES[@]} -eq 0 ]]; then
        echo "No modules available"
        return 0
    fi
    
    case "$format" in
        detailed)
            echo "Available Modules:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            for module in "${AVAILABLE_MODULES[@]}"; do
                show_module_info "$module"
                echo ""
            done
            ;;
        *)
            echo "Available modules: ${AVAILABLE_MODULES[*]}"
            ;;
    esac
}

# Show module information
show_module_info() {
    local module_name="$1"
    local module_dir="$MODULES_DIR/$module_name"
    
    if [[ ! -d "$module_dir" ]]; then
        echo "Module not found: $module_name"
        return 1
    fi
    
    echo "📦 $module_name"
    
    # Try to get description from module.yaml
    local module_config="$module_dir/module.yaml"
    if [[ -f "$module_config" ]]; then
        local description
        description=$(get_yaml_value "$module_config" "description" "")
        if [[ -n "$description" ]]; then
            echo "   Description: $description"
        fi
        
        local version
        version=$(get_yaml_value "$module_config" "version" "")
        if [[ -n "$version" ]]; then
            echo "   Version: $version"
        fi
        
        # Show supported platforms
        if grep -q "platforms:" "$module_config"; then
            local platforms
            platforms=$(grep -A 10 "platforms:" "$module_config" | grep "^[[:space:]]*-" | sed 's/^[[:space:]]*-[[:space:]]*//' | tr '\n' ' ')
            if [[ -n "$platforms" ]]; then
                echo "   Platforms: $platforms"
            fi
        fi
    else
        echo "   Description: Basic module configuration"
    fi
    
    # Check if module is installed
    if is_module_installed "$module_name"; then
        echo "   Status: ✅ Installed"
    else
        echo "   Status: ⚪ Not installed"
    fi
}

# Check if module is installed
is_module_installed() {
    local module_name="$1"
    local module_dir="$MODULES_DIR/$module_name"
    
    # Simple check - look for installed marker or common config files
    case "$module_name" in
        git)
            [[ -f "$HOME/.gitconfig" ]]
            ;;
        vim)
            [[ -f "$HOME/.vimrc" ]]
            ;;
        tmux)
            [[ -f "$HOME/.tmux.conf" ]]
            ;;
        shell)
            [[ -f "$HOME/.bashrc" ]] || [[ -f "$HOME/.zshrc" ]]
            ;;
        *)
            # Generic check for module marker
            [[ -f "$HOME/.dotfiles/installed/$module_name" ]]
            ;;
    esac
}

# Install a single module
install_module() {
    local module_name="$1"
    local dry_run="${2:-false}"
    local module_dir="$MODULES_DIR/$module_name"
    
    if [[ ! -d "$module_dir" ]]; then
        log_error "Module not found: $module_name"
        return 1
    fi
    
    # Clear progress line before printing module info
    if [[ "$(type -t clear_progress_line)" == "function" ]]; then
        clear_progress_line
    fi
    
    log_info "Installing module: $module_name"
    
    # Check platform compatibility
    if ! is_platform_supported "$module_dir"; then
        log_warn "Module $module_name is not supported on $DETECTED_OS"
        return 1
    fi
    
    # Ensure module dependencies are installed
    if [[ "$dry_run" == "false" ]]; then
        ensure_module_dependencies "$module_name"
    fi
    
    # Run pre-install script if it exists
    local pre_install_script="$module_dir/scripts/pre_install.sh"
    if [[ -f "$pre_install_script" ]]; then
        log_debug "Running pre-install script for $module_name"
        if [[ "$dry_run" == "false" ]]; then
            # Export necessary environment variables for the script
            export DOTFILES_ROOT="${DOTFILES_ROOT:-$SCRIPT_DIR}"
            export PLATFORM="${DETECTED_OS:-$PLATFORM}"
            export DRY_RUN="$dry_run"
            export MODULE_NAME="$module_name"
            export MODULE_DIR="$module_dir"
            
            # Validate critical environment variables
            if [[ -z "${DOTFILES_ROOT:-}" ]]; then
                log_error "DOTFILES_ROOT is not set for module script execution"
                return 1
            fi
            
            if ! bash "$pre_install_script"; then
                log_error "Pre-install script failed for $module_name"
                return 1
            fi
        fi
    fi
    
    # Install module files
    if ! install_module_files "$module_name" "$dry_run"; then
        log_error "Failed to install files for module: $module_name"
        return 1
    fi
    
    # Run post-install script if it exists
    local post_install_script="$module_dir/scripts/post_install.sh"
    if [[ -f "$post_install_script" ]]; then
        log_debug "Running post-install script for $module_name"
        if [[ "$dry_run" == "false" ]]; then
            # Export necessary environment variables for the script
            export DOTFILES_ROOT="${DOTFILES_ROOT:-$SCRIPT_DIR}"
            export PLATFORM="${DETECTED_OS:-$PLATFORM}"
            export DRY_RUN="$dry_run"
            export MODULE_NAME="$module_name"
            export MODULE_DIR="$module_dir"
            
            # Validate critical environment variables
            if [[ -z "${DOTFILES_ROOT:-}" ]]; then
                log_error "DOTFILES_ROOT is not set for module script execution"
                return 1
            fi
            
            if ! bash "$post_install_script"; then
                log_warn "Post-install script failed for $module_name (continuing anyway)"
            fi
        fi
    fi
    
    # Mark module as installed
    if [[ "$dry_run" == "false" ]]; then
        mark_module_installed "$module_name"
    fi
    
    log_success "Module installed successfully: $module_name"
    return 0
}

# Install module files
install_module_files() {
    local module_name="$1"
    local dry_run="$2"
    local module_dir="$MODULES_DIR/$module_name"
    
    # Check for module.yaml configuration
    local module_config="$module_dir/module.yaml"
    if [[ -f "$module_config" ]]; then
        install_module_files_from_config "$module_name" "$dry_run"
    else
        install_module_files_generic "$module_name" "$dry_run"
    fi
}

# Install files based on module.yaml configuration
install_module_files_from_config() {
    local module_name="$1"
    local dry_run="$2"
    local module_dir="$MODULES_DIR/$module_name"
    local module_config="$module_dir/module.yaml"
    
    # For git module, use the specialized installation function to preserve config
    if [[ "$module_name" == "git" ]]; then
        install_git_module "$dry_run"
        return $?
    fi
    
    # Simple file installation based on common patterns
    # In a full implementation, you'd parse the YAML properly
    
    # Look for config directory
    local config_dir="$module_dir/config"
    if [[ -d "$config_dir" ]]; then
        for config_file in "$config_dir"/*; do
            if [[ -f "$config_file" ]]; then
                local filename
                filename="$(basename "$config_file")"
                local target="$HOME/.$filename"
                
                if [[ "$dry_run" == "true" ]]; then
                    log_info "Would install: $config_file -> $target"
                else
                    copy_file "$config_file" "$target" true
                fi
            fi
        done
    fi
    
    # Look for dotfiles directory
    local dotfiles_dir="$module_dir/dotfiles"
    if [[ -d "$dotfiles_dir" ]]; then
        for dotfile in "$dotfiles_dir"/.*; do
            if [[ -f "$dotfile" ]]; then
                local filename
                filename="$(basename "$dotfile")"
                local target="$HOME/$filename"
                
                if [[ "$dry_run" == "true" ]]; then
                    log_info "Would install: $dotfile -> $target"
                else
                    copy_file "$dotfile" "$target" true
                fi
            fi
        done
    fi
}

# Generic module file installation
install_module_files_generic() {
    local module_name="$1"
    local dry_run="$2"
    local module_dir="$MODULES_DIR/$module_name"
    
    # Install based on module name conventions
    case "$module_name" in
        git)
            install_git_module "$dry_run"
            ;;
        vim)
            install_vim_module "$dry_run"
            ;;
        tmux)
            install_tmux_module "$dry_run"
            ;;
        shell)
            install_shell_module "$dry_run"
            ;;
        *)
            log_warn "No specific installation method for module: $module_name"
            ;;
    esac
}

# Install git module
install_git_module() {
    local dry_run="$1"
    local module_dir="$MODULES_DIR/git"
    
    if [[ "$dry_run" == "false" ]]; then
        # Preserve existing git configuration before installing
        if preserve_git_config; then
            log_debug "Git user configuration backed up"
        fi
    fi
    
    # Install gitconfig (use static config instead of template to avoid placeholder issues)
    local gitconfig="$module_dir/config/gitconfig"
    if [[ -f "$gitconfig" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log_info "Would install: $gitconfig -> $HOME/.gitconfig"
        else
            copy_file "$gitconfig" "$HOME/.gitconfig" true
        fi
    fi
    
    # Install gitignore
    local gitignore="$module_dir/config/gitignore_global"
    if [[ -f "$gitignore" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log_info "Would install: $gitignore -> $HOME/.gitignore_global"
        else
            copy_file "$gitignore" "$HOME/.gitignore_global" true
            # Set the global gitignore in git config
            git config --global core.excludesfile "$HOME/.gitignore_global"
        fi
    fi
    
    if [[ "$dry_run" == "false" ]]; then
        # Restore user configuration from backup
        if restore_git_config; then
            log_debug "Git user configuration restored from backup"
        fi
    fi
}

# Install vim module
install_vim_module() {
    local dry_run="$1"
    local module_dir="$MODULES_DIR/vim"
    
    if [[ "$dry_run" == "false" ]]; then
        # Create required vim directories
        mkdir -p "$HOME/.vim/backups"
        mkdir -p "$HOME/.vim/swaps"
        mkdir -p "$HOME/.vim/undos"
        mkdir -p "$HOME/.vim/plugins"
        mkdir -p "$HOME/.vim/autoload"
        
        # Install vim-plug plugin manager
        if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
            log_info "Installing vim-plug plugin manager..."
            if command -v curl >/dev/null 2>&1; then
                curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
                    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
            elif command -v wget >/dev/null 2>&1; then
                wget -O "$HOME/.vim/autoload/plug.vim" --create-dirs \
                    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
            else
                log_warn "Neither curl nor wget available, vim-plug installation skipped"
            fi
        fi
    fi
    
    # Install vimrc
    local vimrc="$module_dir/config/vimrc"
    if [[ -f "$vimrc" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log_info "Would install: $vimrc -> $HOME/.vimrc"
        else
            copy_file "$vimrc" "$HOME/.vimrc" true
        fi
    fi
}

# Install tmux module
install_tmux_module() {
    local dry_run="$1"
    local module_dir="$MODULES_DIR/tmux"
    
    if [[ "$dry_run" == "false" ]]; then
        # Create required directories
        mkdir -p "$HOME/.config/tmux"
        mkdir -p "$HOME/.tmux/plugins"
        
        # Install tmux if not available (macOS)
        if ! command -v tmux >/dev/null 2>&1; then
            if command -v brew >/dev/null 2>&1; then
                log_info "Installing tmux via Homebrew..."
                brew install tmux
            fi
        fi
        
        # Install clipboard integration tool for macOS
        if [[ "$(uname)" == "Darwin" ]] && ! command -v reattach-to-user-namespace >/dev/null 2>&1; then
            if command -v brew >/dev/null 2>&1; then
                log_info "Installing reattach-to-user-namespace for clipboard support..."
                brew install reattach-to-user-namespace
            fi
        fi
    fi
    
    # Install tmux.conf
    local tmux_conf="$module_dir/config/tmux.conf"
    if [[ -f "$tmux_conf" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log_info "Would install: $tmux_conf -> $HOME/.tmux.conf"
        else
            copy_file "$tmux_conf" "$HOME/.tmux.conf" true
        fi
    fi
}

# Install shell module
install_shell_module() {
    local dry_run="$1"
    local module_dir="$MODULES_DIR/shell"
    
    # Install all shell configuration files
    local config_dir="$module_dir/config"
    if [[ -d "$config_dir" ]]; then
        for config_file in "$config_dir"/*; do
            if [[ -f "$config_file" ]]; then
                local filename
                filename="$(basename "$config_file")"
                local target="$HOME/.$filename"
                
                if [[ "$dry_run" == "true" ]]; then
                    log_info "Would install: $config_file -> $target"
                else
                    copy_file "$config_file" "$target" true
                fi
            fi
        done
    fi
}

# Mark module as installed
mark_module_installed() {
    local module_name="$1"
    local installed_dir="$HOME/.dotfiles/installed"
    
    if [[ ! -d "$installed_dir" ]]; then
        mkdir -p "$installed_dir"
    fi
    
    echo "$(date)" > "$installed_dir/$module_name"
}

# Resolve module dependencies
resolve_dependencies() {
    local modules=("$@")
    INSTALL_QUEUE=()
    
    # Simple dependency resolution - just add modules to queue
    # In a full implementation, you'd parse dependencies from module.yaml
    
    for module in "${modules[@]}"; do
        # Check if module is already in queue (handle empty array case)
        if [[ ${#INSTALL_QUEUE[@]} -eq 0 ]] || ! array_contains "$module" "${INSTALL_QUEUE[@]}"; then
            INSTALL_QUEUE+=("$module")
        fi
    done
    
    log_debug "Install queue: ${INSTALL_QUEUE[*]}"
    return 0
}

# Interactive module selection
interactive_module_selection() {
    local -n selected_modules_ref=$1
    
    echo ""
    log_info "📦 MODULE SELECTION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo "Available modules:"
    for i in "${!AVAILABLE_MODULES[@]}"; do
        local module="${AVAILABLE_MODULES[$i]}"
        local status="⚪"
        if is_module_installed "$module"; then
            status="✅"
        fi
        echo "  $((i+1)). $status $module"
    done
    
    echo ""
    echo "Enter module numbers to install (e.g., 1,2,3) or 'all' for all modules:"
    read -r selection
    
    selected_modules_ref=()
    
    if [[ "$selection" == "all" ]]; then
        selected_modules_ref=("${AVAILABLE_MODULES[@]}")
    else
        IFS=',' read -ra indices <<< "$selection"
        for index in "${indices[@]}"; do
            # Remove whitespace
            index=$(echo "$index" | tr -d ' ')
            
            if [[ "$index" =~ ^[0-9]+$ ]] && [[ $index -ge 1 && $index -le ${#AVAILABLE_MODULES[@]} ]]; then
                local module="${AVAILABLE_MODULES[$((index-1))]}"
                selected_modules_ref+=("$module")
            fi
        done
    fi
    
    if [[ ${#selected_modules_ref[@]} -eq 0 ]]; then
        log_warn "No modules selected"
        return 1
    fi
    
    log_info "Selected modules: ${selected_modules_ref[*]}"
    return 0
}

# Run dry-run preview
run_dry_run_preview() {
    local modules=("$@")
    
    echo ""
    log_info "🔍 DRY RUN PREVIEW"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    log_info "The following actions would be performed:"
    
    for module in "${modules[@]}"; do
        echo ""
        log_info "Module: $module"
        install_module "$module" true
    done
    
    echo ""
    log_info "No changes were made (dry run mode)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Interactive installation confirmation
interactive_installation_confirmation() {
    local modules=("$@")
    
    echo ""
    log_info "📋 INSTALLATION CONFIRMATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo "The following modules will be installed:"
    for module in "${modules[@]}"; do
        local status="⚪"
        if is_module_installed "$module"; then
            status="🔄"  # Will be updated
        fi
        echo "  $status $module"
    done
    
    echo ""
    if confirm "Proceed with installation?"; then
        return 0
    else
        return 1
    fi
}
# Show installation summary with issue resolution
show_installation_summary_enhanced() {
    local installed_modules=("$@")
    
    echo ""
    log_info "📋 INSTALLATION SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    log_info "✅ Successfully installed ${#installed_modules[@]} modules:"
    for module in "${installed_modules[@]}"; do
        echo "• $module"
    done
    
    echo ""
    log_info "🔧 NEXT STEPS:"
    echo "1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    echo "2. Verify shell configurations are working: alias"
    
    # Git-specific instructions
    if array_contains "git" "${installed_modules[@]}"; then
        echo "3. ✅ Git is configured with:"
        if command -v git >/dev/null 2>&1; then
            echo "   Name: $(git config --global user.name 2>/dev/null || echo 'Not set')"
            echo "   Email: $(git config --global user.email 2>/dev/null || echo 'Not set')"
        fi
    fi
    
    # Tmux-specific instructions
    if array_contains "tmux" "${installed_modules[@]}"; then
        if ! command -v tmux >/dev/null 2>&1; then
            echo "4. ⚠️  Install tmux: brew install tmux (macOS) or apt install tmux (Linux)"
        fi
        if [[ "$(uname)" == "Darwin" ]] && ! command -v reattach-to-user-namespace >/dev/null 2>&1; then
            echo "5. ⚠️  Install clipboard support: brew install reattach-to-user-namespace"
        fi
    fi
    
    # Vim-specific instructions
    if array_contains "vim" "${installed_modules[@]}"; then
        if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
            echo "6. 📦 Install vim-plug: curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
        fi
        echo "7. 🔌 Install vim plugins: vim +PlugInstall +qall"
    fi
    
    echo "8. Create a backup before making changes: ./install.sh backup"
    echo "9. Update configurations anytime: ./install.sh update"
    echo "10. View available modules: ./install.sh list-modules"
    
    echo ""
    log_info "📚 DOCUMENTATION:"
    echo "• README.md - Comprehensive usage guide"
    echo "• docs/ - Detailed documentation for all features"
    echo "• ./install.sh help [topic] - Topic-specific help"
    
    echo ""
    log_info "🔍 TROUBLESHOOTING:"
    echo "• If you encounter issues: ./install.sh help troubleshooting"
    echo "• Enable debug mode: DEBUG=1 ./install.sh --verbose"
    echo "• Check logs: ~/.dotfiles/logs/install.log"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}