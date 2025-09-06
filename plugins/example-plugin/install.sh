#!/bin/bash

# Example Plugin Installation Script
# This script demonstrates comprehensive plugin installation

set -euo pipefail

echo "Installing $PLUGIN_NAME v1.2.0..."
echo "Plugin directory: $PLUGIN_DIR"
echo "Platform: $PLATFORM"
echo "API Version: $PLUGIN_API_VERSION"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "[DRY RUN] Would perform comprehensive plugin installation"
    exit 0
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p "$HOME/.config/example"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/example"

# Platform-specific installation
case "$PLATFORM" in
    "macos")
        echo "Installing on macOS..."
        mkdir -p "$HOME/Library/Caches/example"
        mkdir -p "$HOME/Library/Logs/example"
        
        # Create launchd service file if needed
        if [[ ! -f "$HOME/Library/LaunchAgents/com.example.plugin.plist" ]]; then
            mkdir -p "$HOME/Library/LaunchAgents"
            cat > "$HOME/Library/LaunchAgents/com.example.plugin.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.plugin</string>
    <key>ProgramArguments</key>
    <array>
        <string>$HOME/.local/bin/example-tool</string>
        <string>daemon</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF
        fi
        ;;
    "ubuntu"|"wsl"|"amazon-linux")
        echo "Installing on Linux..."
        mkdir -p "$HOME/.cache/example"
        mkdir -p "$HOME/.local/share/example/logs"
        
        # Create systemd user service file if needed
        if [[ ! -f "$HOME/.config/systemd/user/example-plugin.service" ]]; then
            mkdir -p "$HOME/.config/systemd/user"
            cat > "$HOME/.config/systemd/user/example-plugin.service" << EOF
[Unit]
Description=Example Plugin Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=$HOME/.local/bin/example-tool daemon
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
        fi
        ;;
    *)
        echo "Installing on $PLATFORM..."
        mkdir -p "$HOME/.cache/example"
        ;;
esac

# Install additional tools or dependencies
echo "Installing additional components..."

# Example: Download and install a helper script
if command -v curl >/dev/null 2>&1; then
    echo "Downloading helper scripts..."
    # This is just an example - in a real plugin you might download actual tools
    echo '#!/bin/bash
echo "Example helper script v1.2.0"
echo "Platform: '$PLATFORM'"
echo "Plugin directory: '$PLUGIN_DIR'"
' > "$HOME/.local/bin/example-helper"
    chmod +x "$HOME/.local/bin/example-helper"
fi

# Create initial configuration if it doesn't exist
config_file="$HOME/.config/example/config"
if [[ ! -f "$config_file" ]]; then
    echo "Creating initial configuration..."
    cat > "$config_file" << EOF
# Example Plugin Configuration
# Generated on $(date)

[general]
enabled = true
debug = false
log_level = "info"

[user]
name = "$(whoami)"
email = "${USER_EMAIL:-user@example.com}"

[paths]
data = "$HOME/.local/share/example"
cache = "$HOME/.cache/example"
logs = "$HOME/.local/share/example/logs"

[metadata]
version = "1.2.0"
installed = "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
platform = "$PLATFORM"
EOF
fi

# Set up logging
log_dir="$HOME/.local/share/example/logs"
mkdir -p "$log_dir"
echo "$(date): Example plugin v1.2.0 installed" >> "$log_dir/install.log"

# Create plugin info file
cat > "$HOME/.config/example/plugin_info" << EOF
plugin_name=$PLUGIN_NAME
installed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
platform=$PLATFORM
api_version=$PLUGIN_API_VERSION
version=1.2.0
EOF

# Verify installation
if [[ -f "$HOME/.local/bin/example-tool" ]]; then
    echo "Verifying installation..."
    if "$HOME/.local/bin/example-tool" --version >/dev/null 2>&1; then
        echo "✓ example-tool is working correctly"
    else
        echo "⚠ example-tool may not be working correctly"
    fi
fi

echo ""
echo "=== INSTALLATION COMPLETE ==="
echo "Plugin: $PLUGIN_NAME"
echo "Version: 1.2.0"
echo "Platform: $PLATFORM"
echo "Configuration: $HOME/.config/example/"
echo "Binary: $HOME/.local/bin/example-tool"
echo ""
echo "Next steps:"
echo "1. Restart your shell or run: source ~/.config/example/shell-integration.sh"
echo "2. Run 'example-tool --help' to see available commands"
echo "3. Edit configuration: $config_file"

echo "$PLUGIN_NAME v1.2.0 installed successfully"