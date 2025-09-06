# Example Plugin Shell Integration
# This file demonstrates template processing with environment variables

# Plugin information
export EXAMPLE_PLUGIN_VERSION="1.2.0"
export EXAMPLE_PLUGIN_HOME="${HOME}/.config/example"

# User configuration
export EXAMPLE_USER_NAME="${USER_NAME:-$(whoami)}"
export EXAMPLE_USER_EMAIL="${USER_EMAIL:-user@example.com}"

# Platform-specific settings
case "${PLATFORM:-$(uname -s | tr '[:upper:]' '[:lower:]')}" in
    "darwin")
        export EXAMPLE_PLATFORM="macos"
        export EXAMPLE_BROWSER="open"
        ;;
    "linux")
        export EXAMPLE_PLATFORM="linux"
        export EXAMPLE_BROWSER="${BROWSER:-firefox}"
        ;;
    *)
        export EXAMPLE_PLATFORM="unknown"
        export EXAMPLE_BROWSER="echo"
        ;;
esac

# Aliases
alias example-config="$EDITOR $EXAMPLE_PLUGIN_HOME/config"
alias example-logs="tail -f $EXAMPLE_PLUGIN_HOME/logs/example.log"
alias example-status="example-tool status"

# Functions
example_help() {
    echo "Example Plugin Help"
    echo "Commands:"
    echo "  example-tool status    - Show plugin status"
    echo "  example-tool config    - Edit configuration"
    echo "  example-tool update    - Update plugin data"
    echo "  example-config         - Edit main config file"
    echo "  example-logs           - View plugin logs"
}

# Auto-completion (if supported)
if [[ -n "${BASH_VERSION:-}" ]]; then
    complete -W "status config update help" example-tool
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    compdef '_arguments "1:command:(status config update help)"' example-tool
fi

# Initialization message
if [[ "${EXAMPLE_PLUGIN_VERBOSE:-false}" == "true" ]]; then
    echo "Example Plugin v$EXAMPLE_PLUGIN_VERSION loaded for $EXAMPLE_PLATFORM"
fi