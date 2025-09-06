#!/bin/bash

# ZSH Plugin Installer
# This script installs optional zsh plugins that enhance the shell experience

set -e

echo "🔧 Installing optional ZSH plugins..."

# Create directories
mkdir -p ~/.zsh

# Install zsh-autosuggestions
if [[ ! -d ~/.zsh/zsh-autosuggestions ]]; then
    echo "📦 Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    echo "✅ zsh-autosuggestions installed"
else
    echo "✅ zsh-autosuggestions already installed"
fi

# Install zsh-syntax-highlighting
if [[ ! -d ~/.zsh/zsh-syntax-highlighting ]]; then
    echo "📦 Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
    echo "✅ zsh-syntax-highlighting installed"
else
    echo "✅ zsh-syntax-highlighting already installed"
fi

# Install oh-my-zsh (optional)
if [[ ! -d ~/.oh-my-zsh ]]; then
    echo "📦 Installing oh-my-zsh (optional)..."
    echo "This will install oh-my-zsh which provides additional shell enhancements."
    read -p "Do you want to install oh-my-zsh? (y/N): " install_omz
    
    if [[ $install_omz =~ ^[Yy]$ ]]; then
        # Install oh-my-zsh without running it (to avoid shell switch)
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        echo "✅ oh-my-zsh installed"
    else
        echo "⏭️  Skipping oh-my-zsh installation"
    fi
else
    echo "✅ oh-my-zsh already installed"
fi

echo ""
echo "🎉 ZSH plugin installation complete!"
echo ""
echo "The following plugins are now available:"
echo "  • zsh-autosuggestions: Suggests commands as you type"
echo "  • zsh-syntax-highlighting: Highlights command syntax"
if [[ -d ~/.oh-my-zsh ]]; then
    echo "  • oh-my-zsh: Additional shell enhancements and themes"
fi
echo ""
echo "These plugins will be automatically loaded by your zsh configuration."
echo "Restart your terminal or run 'source ~/.zshrc' to activate them."