# Vim Plugin Installation

This document explains how the vim module handles plugin installation to avoid timeout issues.

## Problem

Previously, the vim module would attempt to install plugins during the post-installation phase using:
```bash
timeout 60 vim --not-a-term -c "PlugInstall --sync" -c "qall"
```

This caused several issues:
- **Timeouts**: Plugin installation often took longer than 60 seconds
- **Network issues**: Unreliable internet connections caused failures
- **Non-interactive mode**: vim-plug doesn't work well in non-interactive mode
- **Timing issues**: Attempting to install plugins before vim-plug was ready

## Solution

The new approach uses a multi-stage installation process:

### 1. Pre-Installation (modules/vim/scripts/pre_install.sh)
- Checks system requirements (vim, curl, git, Node.js)
- Pre-installs vim-plug to avoid later timeout issues
- Validates permissions and environment

### 2. Vim Configuration (modules/vim/config/vimrc)
- Improved vim-plug auto-installation with fallbacks
- Better error handling for plugin installation
- Conditional plugin installation only when needed

### 3. Post-Installation (modules/vim/scripts/post_install.sh)
- Verifies vim-plug installation
- **Skips automatic plugin installation** to avoid timeouts
- Lets vim handle plugin installation on first startup (as designed)
- Provides clear instructions for manual installation if needed

## How It Works Now

1. **During dotfiles installation**: vim-plug is installed but plugins are not
2. **On first vim startup**: vim automatically detects missing plugins and installs them
3. **Manual installation**: Users can run `vim +PlugInstall +qall` if needed

## Benefits

- **No more timeouts**: Installation completes quickly
- **Better reliability**: Network issues don't block the entire installation
- **Cleaner logs**: No confusing timeout messages
- **User control**: Users can choose when to install plugins
- **Graceful degradation**: Works even without internet connection

## Troubleshooting

If plugins don't install automatically:

1. **Check vim-plug**: Ensure `~/.vim/autoload/plug.vim` exists
2. **Manual installation**: Run `vim +PlugInstall +qall`
3. **Check network**: Ensure internet connection is available
4. **Check permissions**: Ensure `~/.vim/plugins/` is writable

## Environment Variables

- `VIM_ENABLE_PLUGINS=false`: Disable plugin installation entirely
- `VIM_PLUGIN_MANAGER=plug`: Use vim-plug (default)

## Files

- `modules/vim/scripts/install_vim_plug.sh`: Standalone vim-plug installer
- `modules/vim/scripts/pre_install.sh`: Pre-installation checks and setup
- `modules/vim/scripts/post_install.sh`: Post-installation verification
- `modules/vim/config/vimrc`: Main vim configuration with improved plugin handling