#!/bin/bash

# Git Module Post-Installation Hook
# Executed after the git module is installed

set -euo pipefail

# Source the logger
source "$DOTFILES_ROOT/core/logger.sh"

log_info "Running Git module post-installation hook"

# Check and preserve user configuration
check_git_user_config() {
    local git_name git_email
    local config_preserved=false
    
    # First, check if user configuration exists and preserve it
    if git config --global user.name >/dev/null 2>&1; then
        git_name=$(git config --global user.name)
    else
        git_name=""
    fi
    
    if git config --global user.email >/dev/null 2>&1; then
        git_email=$(git config --global user.email)
    else
        git_email=""
    fi
    
    # If no configuration found, try to restore from backup file
    if [[ -z "$git_name" || -z "$git_email" ]]; then
        if [[ -f "$HOME/.git_user_backup" ]]; then
            log_info "Attempting to restore git configuration from backup..."
            source "$HOME/.git_user_backup"
            
            if [[ -n "${GIT_USER_NAME:-}" && -n "${GIT_USER_EMAIL:-}" ]]; then
                git config --global user.name "$GIT_USER_NAME"
                git config --global user.email "$GIT_USER_EMAIL"
                git_name="$GIT_USER_NAME"
                git_email="$GIT_USER_EMAIL"
                rm -f "$HOME/.git_user_backup"  # Clean up backup file
                log_success "✅ Git user configuration restored from backup"
                config_preserved=true
            fi
        fi
    fi
    
    # Check if the configuration contains template placeholders (indicating it was overwritten)
    if [[ "$git_name" == *"{{GIT_USER_NAME}}"* ]] || [[ "$git_email" == *"{{GIT_USER_EMAIL}}"* ]]; then
        log_warn "Git configuration contains unprocessed template variables"
        
        # Try to restore from user config file
        local user_config_file="$DOTFILES_ROOT/config/user.yaml"
        if [[ -f "$user_config_file" ]]; then
            local config_name config_email
            config_name=$(grep -E "^\s*name:" "$user_config_file" | sed 's/.*name:\s*["\x27]\?\([^"\x27]*\)["\x27]\?.*/\1/' | head -1)
            config_email=$(grep -E "^\s*email:" "$user_config_file" | sed 's/.*email:\s*["\x27]\?\([^"\x27]*\)["\x27]\?.*/\1/' | head -1)
            
            if [[ -n "$config_name" && -n "$config_email" ]]; then
                log_info "Restoring git configuration from user config..."
                git config --global user.name "$config_name"
                git config --global user.email "$config_email"
                git_name="$config_name"
                git_email="$config_email"
                config_preserved=true
                log_success "✅ Git user configuration restored from user config"
            fi
        fi
        
        # If we couldn't restore from config, clear the template placeholders
        if [[ "$config_preserved" == "false" ]]; then
            if [[ "$git_name" == *"{{GIT_USER_NAME}}"* ]]; then
                git config --global --unset user.name 2>/dev/null || true
                git_name=""
            fi
            if [[ "$git_email" == *"{{GIT_USER_EMAIL}}"* ]]; then
                git config --global --unset user.email 2>/dev/null || true
                git_email=""
            fi
        fi
    fi
    
    # Report final status
    if [[ -n "$git_name" && -n "$git_email" ]]; then
        log_success "✅ Git user configuration is complete:"
        log_info "   Name: $git_name"
        log_info "   Email: $git_email"
        return 0
    else
        log_info "Git user configuration status:"
        if [[ -z "$git_name" ]]; then
            log_info "   user.name: not set"
        else
            log_info "   user.name: $git_name"
        fi
        if [[ -z "$git_email" ]]; then
            log_info "   user.email: not set"
        else
            log_info "   user.email: $git_email"
        fi
        
        if [[ -z "$git_name" || -z "$git_email" ]]; then
            log_info "Note: Git user configuration can be set with:"
            log_info "   git config --global user.name \"Your Name\""
            log_info "   git config --global user.email \"your.email@example.com\""
        fi
        return 0  # Don't fail the installation for this
    fi
}

if [[ "$DRY_RUN" != "true" ]]; then
    # Check user configuration first
    check_git_user_config
    # Set up platform-specific Git credential helper
    case "$PLATFORM" in
        macos)
            if ! git config --global credential.helper >/dev/null 2>&1; then
                log_debug "Setting up macOS keychain credential helper"
                git config --global credential.helper osxkeychain
            fi
            ;;
        ubuntu|wsl|amazon-linux)
            if command -v git-credential-store >/dev/null 2>&1; then
                if ! git config --global credential.helper >/dev/null 2>&1; then
                    log_debug "Setting up store credential helper"
                    git config --global credential.helper store
                fi
            fi
            ;;
    esac
    
    # Verify Git LFS installation
    if command -v git-lfs >/dev/null 2>&1; then
        log_success "Git LFS is available"
    else
        log_warn "Git LFS is not installed. Large file support will be limited."
    fi
    
    # Check for git-flow and attempt installation if missing
    if command -v git-flow >/dev/null 2>&1; then
        log_success "git-flow is available"
    else
        log_warn "git-flow is not available"
        case "$PLATFORM" in
            macos)
                if command -v brew >/dev/null 2>&1; then
                    log_info "Attempting to install git-flow via Homebrew..."
                    if brew install git-flow-avh 2>/dev/null; then
                        log_success "git-flow installed successfully"
                    else
                        log_warn "Failed to install git-flow automatically. Install manually with: brew install git-flow-avh"
                    fi
                else
                    log_warn "Homebrew not available. Install git-flow manually with: brew install git-flow-avh"
                fi
                ;;
            ubuntu|wsl)
                if command -v apt >/dev/null 2>&1; then
                    log_info "git-flow can be installed with: sudo apt install git-flow"
                fi
                ;;
            amazon-linux)
                if command -v yum >/dev/null 2>&1; then
                    log_info "git-flow can be installed with: sudo yum install gitflow"
                elif command -v dnf >/dev/null 2>&1; then
                    log_info "git-flow can be installed with: sudo dnf install git-flow"
                fi
                ;;
        esac
    fi
    
    # Check if global gitignore is properly configured
    gitignore_path=$(git config --global core.excludesfile 2>/dev/null || echo "")
    if [[ -n "$gitignore_path" ]]; then
        if [[ -f "$gitignore_path" ]]; then
            log_success "Global gitignore is configured: $gitignore_path"
        else
            log_warn "Global gitignore configured but file missing: $gitignore_path"
            log_info "Creating default global gitignore file..."
            
            # Expand tilde in path
            gitignore_path="${gitignore_path/#\~/$HOME}"
            
            # Create directory if it doesn't exist
            mkdir -p "$(dirname "$gitignore_path")"
            
            # Create default gitignore content
            cat > "$gitignore_path" << 'EOF'
# Global gitignore file
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# Logs
*.log

# Runtime data
pids
*.pid
*.seed

# Dependency directories
node_modules/
bower_components/

# Temporary files
*.tmp
*.temp
EOF
            log_success "Created default global gitignore: $gitignore_path"
        fi
    else
        log_info "No global gitignore configured (this is optional)"
    fi
else
    log_info "[DRY RUN] Would configure platform-specific Git settings"
fi

log_success "Git module post-installation hook completed"