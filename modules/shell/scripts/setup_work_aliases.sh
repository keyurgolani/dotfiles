#!/bin/bash

# =============================================================================
# Work Aliases Setup Script
# =============================================================================
# This script helps users set up their work-specific aliases safely

set -e

echo "🏢 Work Aliases Setup"
echo "===================="
echo ""

# Get the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"
TEMPLATE_FILE="$DOTFILES_DIR/modules/shell/config/common/aliases_work_template"
WORK_ALIASES_FILE="$HOME/.aliases_work"

echo "📁 Dotfiles directory: $DOTFILES_DIR"
echo "📄 Template file: $TEMPLATE_FILE"
echo "🎯 Target file: $WORK_ALIASES_FILE"
echo ""

# Check if template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "❌ Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Check if work aliases file already exists
if [[ -f "$WORK_ALIASES_FILE" ]]; then
    echo "⚠️  Work aliases file already exists: $WORK_ALIASES_FILE"
    echo ""
    read -p "Do you want to backup and replace it? (y/N): " replace_existing
    
    if [[ $replace_existing =~ ^[Yy]$ ]]; then
        backup_file="${WORK_ALIASES_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$WORK_ALIASES_FILE" "$backup_file"
        echo "✅ Backed up existing file to: $backup_file"
    else
        echo "ℹ️  Keeping existing file. You can manually update it using the template."
        echo "📄 Template location: $TEMPLATE_FILE"
        exit 0
    fi
fi

# Copy template to work aliases file
echo "📋 Creating work aliases file from template..."
cp "$TEMPLATE_FILE" "$WORK_ALIASES_FILE"

# Make it executable
chmod +x "$WORK_ALIASES_FILE"

echo "✅ Work aliases file created: $WORK_ALIASES_FILE"
echo ""

# Show security reminder
echo "🔒 Security Reminders:"
echo "======================"
echo "• The ~/.aliases_work file is automatically gitignored"
echo "• Never commit server names, usernames, or IP addresses to git"
echo "• Use SSH config files (~/.ssh/config) for complex SSH setups"
echo "• Consider using environment variables for sensitive data"
echo ""

# Show next steps
echo "📝 Next Steps:"
echo "=============="
echo "1. Edit your work aliases file:"
echo "   \$EDITOR ~/.aliases_work"
echo ""
echo "2. Add your work-specific aliases, for example:"
echo "   alias myserver='ssh username@work-server.com'"
echo "   alias workproj='cd ~/Work/main-project'"
echo ""
echo "3. Reload your shell or run:"
echo "   source ~/.zshrc"
echo ""
echo "4. Test your aliases:"
echo "   list-aliases | grep work"
echo ""

# Offer to open the file for editing
read -p "Would you like to edit the work aliases file now? (y/N): " edit_now

if [[ $edit_now =~ ^[Yy]$ ]]; then
    echo "🔧 Opening work aliases file for editing..."
    ${EDITOR:-vim} "$WORK_ALIASES_FILE"
fi

echo ""
echo "🎉 Work aliases setup complete!"
echo ""
echo "Your work-specific aliases are now ready to use and will be"
echo "automatically loaded by the shell without being synced to git."