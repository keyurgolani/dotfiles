#!/bin/bash

# Unified Dotfiles Framework - Logging System
# Provides consistent logging functionality across all scripts

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Log levels
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4

# Default log level (can be overridden by environment variable)
LOG_LEVEL="${DOTFILES_LOG_LEVEL:-INFO}"

# Convert log level name to number
get_log_level_number() {
    local level_upper
    level_upper=$(echo "$LOG_LEVEL" | tr '[:lower:]' '[:upper:]')
    
    case "$level_upper" in
        ERROR) echo $LOG_LEVEL_ERROR ;;
        WARN|WARNING) echo $LOG_LEVEL_WARN ;;
        INFO) echo $LOG_LEVEL_INFO ;;
        DEBUG) echo $LOG_LEVEL_DEBUG ;;
        *) echo $LOG_LEVEL_INFO ;;
    esac
}

# Check if message should be logged based on level
should_log() {
    local message_level="$1"
    local current_level
    current_level=$(get_log_level_number)
    
    [[ $message_level -le $current_level ]]
}

# Get timestamp for logging
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Log error message
log_error() {
    local message="$1"
    if should_log $LOG_LEVEL_ERROR; then
        echo -e "${RED}[ERROR]${NC} $message" >&2
        
        # Also log to file if LOG_FILE is set
        if [[ -n "${DOTFILES_LOG_FILE:-}" ]]; then
            echo "[$(get_timestamp)] [ERROR] $message" >> "$DOTFILES_LOG_FILE"
        fi
    fi
}

# Log warning message
log_warn() {
    local message="$1"
    if should_log $LOG_LEVEL_WARN; then
        echo -e "${YELLOW}[WARN]${NC} $message" >&2
        
        if [[ -n "${DOTFILES_LOG_FILE:-}" ]]; then
            echo "[$(get_timestamp)] [WARN] $message" >> "$DOTFILES_LOG_FILE"
        fi
    fi
}

# Log info message
log_info() {
    local message="$1"
    if should_log $LOG_LEVEL_INFO; then
        echo -e "${BLUE}[INFO]${NC} $message"
        
        if [[ -n "${DOTFILES_LOG_FILE:-}" ]]; then
            echo "[$(get_timestamp)] [INFO] $message" >> "$DOTFILES_LOG_FILE"
        fi
    fi
}

# Log success message
log_success() {
    local message="$1"
    if should_log $LOG_LEVEL_INFO; then
        echo -e "${GREEN}[SUCCESS]${NC} $message"
        
        if [[ -n "${DOTFILES_LOG_FILE:-}" ]]; then
            echo "[$(get_timestamp)] [SUCCESS] $message" >> "$DOTFILES_LOG_FILE"
        fi
    fi
}

# Log debug message
log_debug() {
    local message="$1"
    if should_log $LOG_LEVEL_DEBUG; then
        echo -e "${PURPLE}[DEBUG]${NC} $message" >&2
        
        if [[ -n "${DOTFILES_LOG_FILE:-}" ]]; then
            echo "[$(get_timestamp)] [DEBUG] $message" >> "$DOTFILES_LOG_FILE"
        fi
    fi
}

# Initialize logging system
init_logging() {
    local log_dir="${1:-$HOME/.dotfiles/logs}"
    
    # Create log directory if it doesn't exist
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
    fi
    
    # Set log file if not already set
    if [[ -z "${DOTFILES_LOG_FILE:-}" ]]; then
        export DOTFILES_LOG_FILE="$log_dir/install.log"
    fi
    
    # Initialize log file with session header
    if [[ -n "${DOTFILES_LOG_FILE:-}" ]]; then
        echo "" >> "$DOTFILES_LOG_FILE"
        echo "=== Dotfiles Framework Session Started: $(get_timestamp) ===" >> "$DOTFILES_LOG_FILE"
    fi
}

# Set log level
set_log_level() {
    local level="$1"
    export LOG_LEVEL="$level"
}

# Enable verbose logging
enable_verbose_logging() {
    set_log_level "DEBUG"
}

# Disable logging (except errors)
disable_logging() {
    set_log_level "ERROR"
}

# Setup logging system (main initialization function)
setup_logging() {
    local verbose="${1:-false}"
    
    # Set log level based on verbose flag
    if [[ "$verbose" == "true" ]]; then
        enable_verbose_logging
    fi
    
    # Initialize logging system
    init_logging
    
    log_debug "Logging system initialized (level: $LOG_LEVEL)"
}