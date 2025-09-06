# Module Documentation

This document provides comprehensive information about all available modules in the Unified Dotfiles Framework, their configurations, dependencies, and usage.

## Overview

The framework uses a modular architecture where each tool or configuration set is treated as an independent module. Modules can be installed individually or in combination, with automatic dependency resolution.

## Core Modules

### Shell Module

**Name:** `shell`  
**Description:** Comprehensive shell configurations for bash and zsh  
**Platforms:** macOS, Ubuntu, WSL, Amazon Linux 2  
**Dependencies:** None  

**Features:**
- Cross-platform shell configurations
- Extensive alias collections
- Custom functions for productivity
- Environment variable management
- Shell startup performance optimization
- Plugin system integration (oh-my-zsh, bash-it)

**Configuration Options:**
```yaml
# config/user.yaml
modules:
  shell:
    default_shell: "zsh"  # or "bash"
    enable_plugins: true
    performance_mode: true
    custom_aliases: true
    prompt_theme: "minimal"  # minimal, powerline, custom
```

**Files Managed:**
- `~/.zshrc` - Zsh configuration
- `~/.bashrc` - Bash configuration  
- `~/.bash_profile` - Bash profile
- `~/.shell_aliases` - Custom aliases
- `~/.shell_functions` - Custom functions
- `~/.shell_exports` - Environment variables

**Aliases Included:**
```bash
# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# List files
alias l="ls -lF"
alias la="ls -laF"
alias ll="ls -l"
alias lsd="ls -lF | grep --color=never '^d'"

# Git shortcuts (when git module is also installed)
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"

# System utilities
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
alias h="history"
alias j="jobs"
alias path='echo -e ${PATH//:/\\n}'
```

**Functions Included:**
```bash
# Create directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# Extract various archive formats
extract() { 
  # Supports .tar.gz, .zip, .rar, .7z, etc.
}

# Find and kill process by name
killnamed() { kill -9 $(pgrep -f "$1"); }

# Quick server for current directory
serve() { python -m http.server "${1:-8000}"; }
```

### Git Module

**Name:** `git`  
**Description:** Comprehensive git configuration with aliases and workflows  
**Platforms:** macOS, Ubuntu, WSL, Amazon Linux 2  
**Dependencies:** git package  

**Features:**
- Git configuration templates with user substitution
- Extensive git aliases for common workflows
- Global gitignore patterns
- Git signing key configuration
- Platform-specific git tool integration
- Git workflow enhancements

**Configuration Options:**
```yaml
# config/user.yaml
modules:
  git:
    user_name: "Your Name"
    user_email: "your.email@example.com"
    github_username: "yourusername"
    signing_key: "your-gpg-key-id"  # optional
    default_branch: "main"
    enable_signing: false
```

**Files Managed:**
- `~/.gitconfig` - Main git configuration
- `~/.gitignore_global` - Global gitignore patterns
- `~/.gitmessage` - Commit message template

**Git Aliases:**
```bash
# Status and information
git st = status
git s = status --short
git sb = status --short --branch

# Add and commit
git a = add
git aa = add --all
git c = commit
git cm = commit --message
git ca = commit --amend
git can = commit --amend --no-edit

# Branch management
git co = checkout
git cob = checkout -b
git br = branch
git bra = branch --all
git brd = branch --delete

# Log and history
git l = log --oneline
git lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'
git ll = log --stat
git lp = log --patch

# Remote operations
git f = fetch
git fa = fetch --all
git p = push
git pl = pull
git plo = pull origin
git plu = pull upstream

# Diff operations
git d = diff
git dc = diff --cached
git ds = diff --stat
git dw = diff --word-diff

# Stash operations
git st = stash
git stp = stash pop
git stl = stash list
git sts = stash show

# Reset operations
git r = reset
git rh = reset --hard
git rs = reset --soft

# Utilities
git unstage = reset HEAD --
git discard = checkout --
git visual = !gitk
git type = cat-file -t
git dump = cat-file -p
```

**Global Gitignore Patterns:**
```gitignore
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
logs/

# Dependencies
node_modules/
vendor/
.env
.env.local
```

### Vim Module

**Name:** `vim`  
**Description:** Comprehensive vim configuration with plugins and customizations  
**Platforms:** macOS, Ubuntu, WSL, Amazon Linux 2  
**Dependencies:** vim  

**Features:**
- Modern vim configuration with sensible defaults
- Plugin management with vim-plug
- Syntax highlighting and language support
- Custom key mappings and shortcuts
- IDE-like features (file explorer, fuzzy finder, etc.)
- Performance optimizations

**Configuration Options:**
```yaml
# config/user.yaml
modules:
  vim:
    plugin_manager: "vim-plug"  # vim-plug, vundle, pathogen
    enable_plugins: true
    color_scheme: "molokai"  # molokai, solarized, gruvbox
    enable_powerline: true
    tab_width: 4
    enable_mouse: true
```

**Files Managed:**
- `~/.vimrc` - Main vim configuration
- `~/.vim/` - Vim directory structure
- `~/.vim/autoload/plug.vim` - Plugin manager

**Key Features:**
```vim
" Leader key
let mapleader = ","

" File operations
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" Navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Search and replace
nnoremap <leader>s :%s/
vnoremap <leader>s :s/

" Plugin shortcuts
nnoremap <leader>t :NERDTreeToggle<CR>
nnoremap <leader>f :FZF<CR>
nnoremap <leader>b :Buffers<CR>
```

**Plugins Included:**
- **NERDTree** - File explorer
- **fzf.vim** - Fuzzy finder
- **vim-airline** - Status line
- **vim-fugitive** - Git integration
- **vim-surround** - Surround text objects
- **vim-commentary** - Comment/uncomment
- **vim-gitgutter** - Git diff in gutter
- **ale** - Asynchronous linting
- **vim-polyglot** - Language pack

### Tmux Module

**Name:** `tmux`  
**Description:** Terminal multiplexer configuration with custom key bindings  
**Platforms:** macOS, Ubuntu, WSL, Amazon Linux 2  
**Dependencies:** tmux  

**Features:**
- Custom tmux configuration with sensible defaults
- Intuitive key bindings
- Status bar customization
- Session management enhancements
- Plugin system integration
- Mouse support and copy-paste improvements

**Configuration Options:**
```yaml
# config/user.yaml
modules:
  tmux:
    prefix_key: "C-a"  # or "C-b"
    enable_mouse: true
    status_position: "bottom"  # top, bottom
    enable_plugins: true
    color_scheme: "dark"  # dark, light
```

**Files Managed:**
- `~/.tmux.conf` - Main tmux configuration
- `~/.tmux/` - Tmux directory for plugins and scripts

**Key Bindings:**
```bash
# Prefix key (default: Ctrl-a)
set -g prefix C-a
unbind C-b

# Pane splitting
bind | split-window -h
bind - split-window -v

# Pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Window navigation
bind -n M-Left previous-window
bind -n M-Right next-window

# Pane resizing
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Copy mode
bind v copy-mode
bind p paste-buffer
```

**Status Bar Configuration:**
```bash
# Status bar
set -g status-bg black
set -g status-fg white
set -g status-left '#[fg=green]#S '
set -g status-right '#[fg=yellow]%Y-%m-%d %H:%M'
set -g status-interval 60
```

## Platform-Specific Modules

### Homebrew Module (macOS)

**Name:** `homebrew`  
**Description:** Homebrew package manager setup and package installation  
**Platforms:** macOS  
**Dependencies:** None (installs Homebrew if needed)  

**Features:**
- Automatic Homebrew installation
- Package list management
- Cask application installation
- Tap repository management
- Cleanup and maintenance scripts

**Configuration Options:**
```yaml
# config/user.yaml
modules:
  homebrew:
    auto_update: true
    install_casks: true
    cleanup_frequency: "weekly"
    taps:
      - homebrew/cask-fonts
      - homebrew/cask-versions
    packages:
      - git
      - vim
      - tmux
      - node
      - python
    casks:
      - iterm2
      - visual-studio-code
      - google-chrome
```

### Developer Tools Module

**Name:** `developer-tools`  
**Description:** Essential development tools and utilities  
**Platforms:** macOS, Ubuntu, WSL, Amazon Linux 2  
**Dependencies:** Platform package manager  

**Features:**
- Programming language installations
- Development utilities
- Build tools and compilers
- Version managers (nvm, rbenv, pyenv)
- Database tools

**Configuration Options:**
```yaml
# config/user.yaml
modules:
  developer-tools:
    languages:
      - node
      - python
      - ruby
      - go
    tools:
      - docker
      - kubectl
      - terraform
    databases:
      - postgresql
      - redis
    version_managers:
      - nvm
      - pyenv
      - rbenv
```

### iTerm Module (macOS)

**Name:** `iterm`  
**Description:** iTerm2 terminal configuration and preferences  
**Platforms:** macOS  
**Dependencies:** iTerm2  

**Features:**
- iTerm2 preference configuration
- Custom color schemes
- Profile management
- Key binding customization
- Integration with shell configurations

**Configuration Options:**
```yaml
# config/user.yaml
modules:
  iterm:
    color_scheme: "Solarized Dark"
    font_family: "Fira Code"
    font_size: 14
    enable_ligatures: true
    profiles:
      - name: "Default"
        command: "/bin/zsh"
      - name: "SSH"
        command: "ssh"
```

### Sublime Text Module

**Name:** `sublime`  
**Description:** Sublime Text editor configuration and packages  
**Platforms:** macOS, Ubuntu, WSL, Amazon Linux 2  
**Dependencies:** Sublime Text  

**Features:**
- Sublime Text settings synchronization
- Package management
- Custom key bindings
- Theme and color scheme configuration
- Project-specific settings

**Configuration Options:**
```yaml
# config/user.yaml
modules:
  sublime:
    theme: "Adaptive"
    color_scheme: "Monokai"
    font_family: "Fira Code"
    font_size: 12
    packages:
      - "Package Control"
      - "SublimeLinter"
      - "GitGutter"
      - "BracketHighlighter"
```

### VS Code Module

**Name:** `vscode`  
**Description:** Visual Studio Code settings and extensions  
**Platforms:** macOS, Ubuntu, WSL, Amazon Linux 2  
**Dependencies:** Visual Studio Code  

**Features:**
- VS Code settings synchronization
- Extension management
- Workspace configuration
- Keybinding customization
- Theme and appearance settings

**Configuration Options:**
```yaml
# config/user.yaml
modules:
  vscode:
    theme: "Dark+ (default dark)"
    font_family: "Fira Code"
    font_size: 14
    enable_ligatures: true
    extensions:
      - ms-python.python
      - ms-vscode.vscode-typescript-next
      - bradlc.vscode-tailwindcss
      - esbenp.prettier-vscode
```

## Module Dependencies

### Dependency Resolution

The framework automatically resolves module dependencies:

```yaml
# Example dependency chain
shell: []  # No dependencies
git: [shell]  # Requires shell for aliases
vim: [shell]  # Requires shell for integration
tmux: [shell]  # Requires shell for integration
developer-tools: [shell, git]  # Requires shell and git
```

### Installation Order

Modules are installed in dependency order:
1. `shell` (base module)
2. `git` (depends on shell)
3. `vim`, `tmux` (depend on shell)
4. `developer-tools` (depends on shell and git)
5. Platform-specific modules (`homebrew`, `iterm`, `vscode`)

## Module Management

### List Available Modules

```bash
# List all available modules
./install.sh list-modules

# List modules with detailed information
./install.sh list-modules --detailed

# List only enabled modules
./install.sh list-modules --enabled
```

### Install Specific Modules

```bash
# Install single module
./install.sh --modules shell

# Install multiple modules
./install.sh --modules shell,git,vim,tmux

# Install all modules
./install.sh --modules all

# Install with dependencies
./install.sh --modules vim --include-dependencies
```

### Module Configuration

```bash
# Show module configuration
./install.sh show-config --module git

# Validate module configuration
./install.sh validate --module git

# Test module installation (dry run)
./install.sh --modules git --dry-run
```

## Custom Module Creation

### Module Structure

```
modules/my-module/
├── module.yaml          # Module metadata
├── install.sh          # Installation script
├── uninstall.sh        # Uninstallation script
├── config/             # Configuration files
│   ├── common/         # Cross-platform configs
│   ├── macos/          # macOS-specific configs
│   └── ubuntu/         # Ubuntu-specific configs
├── templates/          # Template files
└── scripts/            # Helper scripts
```

### Module Configuration File

```yaml
# modules/my-module/module.yaml
name: "my-module"
version: "1.0.0"
description: "My custom module"
category: "development"
author: "Your Name"
platforms:
  - macos
  - ubuntu
dependencies:
  - shell
  - git
conflicts: []
files:
  - source: "config/my-config"
    target: "~/.my-config"
    template: true
    backup: true
packages:
  macos:
    - my-package
  ubuntu:
    - my-package
hooks:
  pre_install: "scripts/pre_install.sh"
  post_install: "scripts/post_install.sh"
settings:
  configurable: true
  user_prompts:
    - name: "api_key"
      description: "Enter your API key"
      type: "password"
      required: true
```

### Installation Script Template

```bash
#!/bin/bash
# modules/my-module/install.sh

set -euo pipefail

# Source framework utilities
source "$(dirname "$0")/../../core/utils.sh"
source "$(dirname "$0")/../../core/logger.sh"

MODULE_NAME="my-module"
MODULE_DIR="$(dirname "$0")"

install_my_module() {
    log_info "Installing $MODULE_NAME module..."
    
    # Install packages
    install_packages_for_module "$MODULE_NAME"
    
    # Copy configuration files
    install_config_files "$MODULE_NAME"
    
    # Run custom installation logic
    if [[ -f "$MODULE_DIR/scripts/custom_install.sh" ]]; then
        bash "$MODULE_DIR/scripts/custom_install.sh"
    fi
    
    log_success "$MODULE_NAME module installed successfully"
}

# Run installation
install_my_module "$@"
```

## Module Best Practices

### Configuration Management

1. **Use templates** for dynamic configuration generation
2. **Support multiple platforms** when possible
3. **Provide sensible defaults** with user customization options
4. **Document all configuration options** in module.yaml

### Installation Scripts

1. **Use error handling** with `set -euo pipefail`
2. **Log progress** with framework logging functions
3. **Check dependencies** before installation
4. **Provide cleanup** on installation failure

### File Management

1. **Backup existing files** before overwriting
2. **Use appropriate file permissions** (600 for configs, 755 for scripts)
3. **Support both symlinks and copies** as needed
4. **Organize files** in logical directory structures

### Testing

1. **Test on all supported platforms**
2. **Provide dry-run capability**
3. **Include uninstallation scripts**
4. **Validate configuration files**

This comprehensive module documentation provides all the information needed to understand, use, and extend the modular system of the Unified Dotfiles Framework.