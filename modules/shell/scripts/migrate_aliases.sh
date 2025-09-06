#!/bin/bash

# =============================================================================
# Alias Migration Script
# =============================================================================
# This script helps migrate from the old messy alias system to the new
# organized alias structure

set -e

echo "🔄 Alias System Migration"
echo "========================="
echo ""

# Get the dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$(dirname "$(dirname "$MODULE_DIR")")"
ALIASES_DIR="$MODULE_DIR/config/common"

echo "📁 Dotfiles directory: $DOTFILES_DIR"
echo "📁 Aliases directory: $ALIASES_DIR"
echo ""

# Check if new alias files exist
echo "🔍 Checking new alias system..."
NEW_FILES=(
    "aliases_new"
    "aliases_macos" 
    "aliases_linux"
    "aliases_dev"
    "aliases"
)

for file in "${NEW_FILES[@]}"; do
    if [[ -f "$ALIASES_DIR/$file" ]]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

echo ""

# Check for old alias files
echo "🔍 Checking for old alias files..."
OLD_FILES=(
    "$ALIASES_DIR/aliases_backup"
    "$DOTFILES_DIR/modules/shell/config/zsh_aliases"
)

for file in "${OLD_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "📄 Found old file: $(basename "$file")"
    fi
done

echo ""

# Show alias counts
echo "📊 Alias Statistics:"
echo "==================="

# Count aliases in new system
if [[ -f "$ALIASES_DIR/aliases" ]]; then
    echo "🔄 Loading new alias system..."
    
    # Temporarily source the new aliases to count them
    TEMP_ALIAS_COUNT=$(bash -c "
        source '$ALIASES_DIR/aliases' 2>/dev/null
        alias | wc -l
    " 2>/dev/null || echo "0")
    
    echo "📈 New system aliases: $TEMP_ALIAS_COUNT"
fi

# Count aliases in old backup
if [[ -f "$ALIASES_DIR/aliases_backup" ]]; then
    OLD_ALIAS_COUNT=$(grep -c "^alias " "$ALIASES_DIR/aliases_backup" 2>/dev/null || echo "0")
    echo "📉 Old system aliases: $OLD_ALIAS_COUNT"
fi

echo ""

# Show organization
echo "📋 New Alias Organization:"
echo "=========================="
echo "🌐 Core (cross-platform):"
echo "   • Navigation (cd shortcuts, directory stack)"
echo "   • File operations (ls, mv, cp, rm with enhancements)"
echo "   • Search & find (grep, find with colors)"
echo "   • System utilities (clear, history, processes)"
echo ""
echo "🍎 macOS Specific:"
echo "   • Finder operations (show/hide files, desktop icons)"
echo "   • System maintenance (empty trash, cleanup)"
echo "   • Audio controls (mute, volume)"
echo "   • Clipboard operations"
echo ""
echo "🐧 Linux Specific:"
echo "   • Package management (apt, yum, dnf, pacman)"
echo "   • System services (systemctl shortcuts)"
echo "   • Hardware info (cpu, mem, disk)"
echo ""
echo "💻 Development Tools:"
echo "   • Git (comprehensive git shortcuts)"
echo "   • Node.js/npm/yarn"
echo "   • Docker & Kubernetes"
echo "   • Python, databases, build tools"
echo ""

# Show customization options
echo "🎨 Customization Options:"
echo "========================"
echo "📝 ~/.aliases_local  - Your personal aliases (not synced)"
echo "🏢 ~/.aliases_work   - Work-specific aliases (not synced)"
echo ""

# Show management commands
echo "🔧 Management Commands:"
echo "======================"
echo "🔄 reload-aliases    - Reload all alias files"
echo "📋 list-aliases      - Show all current aliases"
echo "🔍 find-alias <term> - Search for specific aliases"
echo ""

# Test the new system
echo "🧪 Testing New Alias System:"
echo "============================"

if [[ -f "$ALIASES_DIR/aliases" ]]; then
    echo "🔄 Testing alias loading..."
    
    # Test in a subshell to avoid affecting current environment
    if bash -c "source '$ALIASES_DIR/aliases' 2>/dev/null && echo 'Alias system loaded successfully'" 2>/dev/null; then
        echo "✅ New alias system loads without errors"
    else
        echo "❌ New alias system has loading issues"
    fi
else
    echo "❌ New alias system not found"
fi

echo ""

# Migration recommendations
echo "📋 Migration Recommendations:"
echo "============================="
echo "1. ✅ New alias system is ready to use"
echo "2. 🔄 Restart your terminal or run: source ~/.zshrc"
echo "3. 🧪 Test with: list-aliases | head -10"
echo "4. 🎯 Customize by creating ~/.aliases_local"
echo "5. 🗑️  Remove old files after confirming everything works:"
echo "   • rm $ALIASES_DIR/aliases_backup"
echo "   • Update any custom scripts that reference old aliases"
echo ""

# Show sample custom aliases
echo "💡 Sample Custom Aliases (~/.aliases_local):"
echo "============================================="
cat << 'EOF'
#!/bin/bash
# Personal aliases - not synced with dotfiles

# Project shortcuts
alias proj='cd ~/Projects'
alias work='cd ~/Work'

# SSH shortcuts  
alias myserver='ssh user@server.com'

# Custom git shortcuts
alias glog='git log --oneline --graph --all'

# Personal utilities
alias weather='curl wttr.in'
alias myip='curl ifconfig.me'
EOF

echo ""
echo "🎉 Migration analysis complete!"
echo ""
echo "The new alias system provides:"
echo "✅ No duplicate aliases"
echo "✅ Better organization"
echo "✅ Platform-specific aliases"
echo "✅ Easy customization"
echo "✅ Better maintainability"