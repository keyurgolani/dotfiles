#!/bin/bash

# Test helper functions for unified dotfiles framework
# Provides common utilities and setup functions for bats tests

# Load bats helper libraries
HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
load "${HELPERS_DIR}/bats-helpers/bats-support/load.bash"
load "${HELPERS_DIR}/bats-helpers/bats-assert/load.bash"
load "${HELPERS_DIR}/bats-helpers/bats-file/load.bash"

# Test configuration
TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_FIXTURES_DIR="$TEST_ROOT/fixtures"
TEST_CONFIG_DIR="$TEST_TEMP_DIR/config"

if [[ -f "$TEST_ROOT/test_config.sh" ]]; then
    source "$TEST_ROOT/test_config.sh"
fi

# Common test setup
setup_test_environment() {
    # Create temporary test directory
    export TEST_TEMP_DIR="${BATS_TMPDIR}/dotfiles_test_$$"
    mkdir -p "$TEST_TEMP_DIR"
    
    # Set test configuration directory
    export TEST_CONFIG_DIR="$TEST_TEMP_DIR/config"
    mkdir -p "$TEST_CONFIG_DIR"
    
    # Set test-specific environment variables
    export DOTFILES_ROOT="$TEST_ROOT/.."
    export DOTFILES_BACKUP_DIR="$TEST_TEMP_DIR/backups"
    export DOTFILES_LOG_LEVEL="ERROR"  # Reduce noise in tests
    export HOME="$TEST_TEMP_DIR/home"
    
    # Create mock home directory
    mkdir -p "$HOME"
    
    # Copy test fixtures
    if [[ -d "$TEST_FIXTURES_DIR" ]]; then
        cp -r "$TEST_FIXTURES_DIR"/* "$TEST_TEMP_DIR/" 2>/dev/null || true
    fi
}

# Common test teardown
teardown_test_environment() {
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Mock platform detection
mock_platform() {
    local platform="$1"
    export PLATFORM_OVERRIDE="$platform"
    
    case "$platform" in
        "macos")
            export OSTYPE="darwin"
            source "$TEST_FIXTURES_DIR/mock_environments/macos.sh" 2>/dev/null || true
            ;;
        "ubuntu")
            export OSTYPE="linux-gnu"
            source "$TEST_FIXTURES_DIR/mock_environments/ubuntu.sh" 2>/dev/null || true
            ;;
        "wsl")
            export OSTYPE="linux-gnu"
            export WSL_DISTRO_NAME="Ubuntu"
            ;;
        "amazon-linux")
            export OSTYPE="linux-gnu"
            export PLATFORM_ID="amzn"
            ;;
    esac
}

# Create test dotfiles
create_test_dotfiles() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        local filepath="$HOME/$file"
        mkdir -p "$(dirname "$filepath")"
        echo "# Test content for $file" > "$filepath"
    done
}

# Create test configuration
create_test_config() {
    local config_type="$1"
    local content="$2"
    
    local config_dir="$TEST_TEMP_DIR/config"
    mkdir -p "$config_dir"
    
    echo "$content" > "$config_dir/${config_type}.yaml"
}

# Assert file exists and has content
assert_file_contains() {
    local file="$1"
    local expected_content="$2"
    
    assert_file_exist "$file"
    run grep -q "$expected_content" "$file"
    assert_success
}

# Assert command output contains string
assert_output_contains() {
    local expected="$1"
    run echo "$output"
    assert_output --partial "$expected"
}

# Assert command output matches pattern
assert_output_matches() {
    local pattern="$1"
    [[ "$output" =~ $pattern ]]
}

# Mock command for testing
mock_command() {
    local command_name="$1"
    local mock_behavior="$2"
    
    # Create mock command in test temp directory
    local mock_dir="$TEST_TEMP_DIR/mock_bin"
    mkdir -p "$mock_dir"
    
    cat > "$mock_dir/$command_name" << EOF
#!/bin/bash
$mock_behavior
EOF
    
    chmod +x "$mock_dir/$command_name"
    export PATH="$mock_dir:$PATH"
}

# Restore original command
restore_command() {
    local command_name="$1"
    local mock_dir="$TEST_TEMP_DIR/mock_bin"
    
    if [[ -f "$mock_dir/$command_name" ]]; then
        rm "$mock_dir/$command_name"
    fi
}

# Wait for condition with timeout
wait_for_condition() {
    local condition="$1"
    local timeout="${2:-10}"
    local interval="${3:-1}"
    
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if eval "$condition"; then
            return 0
        fi
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
    
    return 1
}

# Generate random string for testing
random_test_string() {
    local length="${1:-8}"
    LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

# Create temporary file with content
create_temp_file() {
    local content="$1"
    local filename="${2:-$(random_test_string).tmp}"
    
    local filepath="$TEST_TEMP_DIR/$filename"
    echo "$content" > "$filepath"
    echo "$filepath"
}

# Source core functions for testing
source_core_function() {
    local function_file="$1"
    local core_path="$DOTFILES_ROOT/core/$function_file"
    
    if [[ -f "$core_path" ]]; then
        source "$core_path"
    else
        skip "Core function file not found: $core_path"
    fi
}

# Skip test if dependency not available
skip_if_missing() {
    local dependency="$1"
    local message="${2:-Dependency not available: $dependency}"
    
    if ! command -v "$dependency" >/dev/null 2>&1; then
        skip "$message"
    fi
}

# Skip test on specific platform
skip_on_platform() {
    local platform="$1"
    local message="${2:-Test not supported on $platform}"
    
    if [[ "${PLATFORM_OVERRIDE:-}" == "$platform" ]] || [[ "$OSTYPE" == "$platform"* ]]; then
        skip "$message"
    fi
}

# Skip test unless on specific platform
skip_unless_platform() {
    local platform="$1"
    local message="${2:-Test only supported on $platform}"
    
    if [[ "${PLATFORM_OVERRIDE:-}" != "$platform" ]] && [[ "$OSTYPE" != "$platform"* ]]; then
        skip "$message"
    fi
}

# Assert log message was written
assert_log_contains() {
    local expected_message="$1"
    local log_file="${DOTFILES_LOG_FILE:-$TEST_TEMP_DIR/dotfiles.log}"
    
    if [[ -f "$log_file" ]]; then
        run grep -q "$expected_message" "$log_file"
        assert_success
    else
        fail "Log file not found: $log_file"
    fi
}

# Setup mock git repository
setup_mock_git_repo() {
    local repo_dir="${1:-$TEST_TEMP_DIR/mock_repo}"
    
    mkdir -p "$repo_dir"
    cd "$repo_dir"
    
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    echo "# Test repository" > README.md
    git add README.md
    git commit --quiet -m "Initial commit"
    
    echo "$repo_dir"
}

# Cleanup mock git repository
cleanup_mock_git_repo() {
    local repo_dir="${1:-$TEST_TEMP_DIR/mock_repo}"
    
    if [[ -d "$repo_dir" ]]; then
        rm -rf "$repo_dir"
    fi
}

# Assert backup was created
assert_backup_created() {
    local backup_dir="${DOTFILES_BACKUP_DIR:-$TEST_TEMP_DIR/backups}"
    
    assert_dir_exist "$backup_dir"
    
    # Check if any backup directories exist
    local backup_count
    backup_count=$(find "$backup_dir" -maxdepth 1 -type d -name "backup_*" | wc -l)
    
    [[ $backup_count -gt 0 ]]
}

# Assert configuration was applied
assert_config_applied() {
    local config_file="$1"
    local expected_content="$2"
    
    assert_file_exist "$config_file"
    
    if [[ -n "$expected_content" ]]; then
        assert_file_contains "$config_file" "$expected_content"
    fi
}

# Setup test module
setup_test_module() {
    local module_name="$1"
    local module_dir="$TEST_TEMP_DIR/modules/$module_name"
    
    mkdir -p "$module_dir/config"
    
    # Create basic module.yaml
    cat > "$module_dir/module.yaml" << EOF
name: "$module_name"
version: "1.0.0"
description: "Test module for $module_name"
platforms:
  - macos
  - ubuntu
files:
  - source: "config/${module_name}rc"
    target: "~/.${module_name}rc"
EOF
    
    # Create basic config file
    echo "# Test $module_name configuration" > "$module_dir/config/${module_name}rc"
    
    # Create install script
    cat > "$module_dir/install.sh" << 'EOF'
#!/bin/bash
echo "Installing test module"
EOF
    chmod +x "$module_dir/install.sh"
    
    echo "$module_dir"
}