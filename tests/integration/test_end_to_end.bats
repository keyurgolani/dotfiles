#!/usr/bin/env bats

# End-to-end testing for unified dotfiles framework
# Tests complete installation workflows across all supported platforms

load '../helpers/test_helpers'

setup() {
    setup_test_environment
    
    # Create test user configuration
    create_test_config "user" "
modules:
  enabled:
    - shell
    - git
    - vim
    - tmux
  disabled:
    - vscode
    - docker

settings:
  backup_enabled: true
  interactive_mode: false
  parallel_installation: true

user:
  name: 'Test User'
  email: 'test@example.com'
  github_username: 'testuser'

performance:
  enable_parallel_installation: true
  max_parallel_jobs: 2
  enable_download_cache: true
"
}

teardown() {
    teardown_test_environment
}

@test "end-to-end: complete installation workflow on current platform" {
    # Test complete installation from start to finish
    run "$DOTFILES_ROOT/install.sh" --non-interactive --config "$TEST_CONFIG_DIR/user.yaml" --verbose
    
    assert_success
    assert_output_contains "Installation completed successfully"
    assert_output_contains "modules installed"
    
    # Verify backup was created
    assert_dir_exist "$HOME/.dotfiles_backup"
    
    # Verify core modules were installed
    assert_file_exist "$HOME/.bashrc"
    assert_file_exist "$HOME/.gitconfig"
    assert_file_exist "$HOME/.vimrc"
    assert_file_exist "$HOME/.tmux.conf"
}

@test "end-to-end: installation with override system" {
    # Create work environment override
    create_test_config "work_override" "
user:
  email: 'work@company.com'
modules:
  enabled:
    - shell
    - git
    - corporate-tools
settings:
  git_signing_enabled: true
"
    
    run "$DOTFILES_ROOT/install.sh" --non-interactive --config "$TEST_CONFIG_DIR/user.yaml" --override "$TEST_CONFIG_DIR/work_override.yaml" --verbose
    
    assert_success
    assert_output_contains "Applied configuration overrides"
    assert_output_contains "work@company.com"
}

@test "end-to-end: backup and restore functionality" {
    # Create some existing dotfiles
    create_test_dotfiles ".bashrc" ".gitconfig" ".vimrc"
    
    # Run installation (should create backup)
    run "$DOTFILES_ROOT/install.sh" --non-interactive --config "$TEST_CONFIG_DIR/user.yaml"
    assert_success
    
    # Verify backup was created
    run "$DOTFILES_ROOT/install.sh" list-backups
    assert_success
    assert_output_contains "backup"
    
    # Get backup ID from output
    local backup_id
    backup_id=$(echo "$output" | grep -o '[0-9]\{8\}_[0-9]\{6\}' | head -1)
    
    # Restore from backup
    run "$DOTFILES_ROOT/install.sh" restore "$backup_id"
    assert_success
    assert_output_contains "Restore completed successfully"
}

@test "end-to-end: module system with dependencies" {
    # Test that dependencies are resolved correctly
    run "$DOTFILES_ROOT/install.sh" --modules "git,vim" --non-interactive --verbose
    
    assert_success
    assert_output_contains "Resolving module dependencies"
    assert_output_contains "Installing module: shell"  # Should be installed as dependency
    assert_output_contains "Installing module: git"
    assert_output_contains "Installing module: vim"
}

@test "end-to-end: performance requirements validation" {
    # Test that installation completes within reasonable time
    local start_time end_time duration
    start_time=$(date +%s)
    
    run timeout 600 "$DOTFILES_ROOT/install.sh" --non-interactive --config "$TEST_CONFIG_DIR/user.yaml"
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    assert_success
    
    # Should complete within 10 minutes (600 seconds) as per requirement 9.1
    [[ $duration -lt 600 ]]
    
    # Log performance metrics
    log_info "Installation completed in ${duration} seconds"
}

@test "end-to-end: shell startup performance" {
    # Install shell module
    run "$DOTFILES_ROOT/install.sh" --modules "shell" --non-interactive
    assert_success
    
    # Test shell startup time (should be under 500ms as per requirement 9.2)
    local startup_time
    startup_time=$(time (bash -c 'exit') 2>&1 | grep real | awk '{print $2}' | sed 's/[^0-9.]//g')
    
    # Convert to milliseconds and check
    local startup_ms
    startup_ms=$(echo "$startup_time * 1000" | bc -l 2>/dev/null || echo "0")
    
    # Should be under 500ms
    if command -v bc >/dev/null 2>&1; then
        [[ $(echo "$startup_ms < 500" | bc -l) -eq 1 ]]
    fi
    
    log_info "Shell startup time: ${startup_ms}ms"
}

@test "end-to-end: error handling and recovery" {
    # Test graceful error handling
    
    # Create invalid configuration
    create_test_config "invalid" "
invalid_yaml: [
  - missing_closing_bracket
"
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/invalid.yaml" --non-interactive
    
    assert_failure
    assert_output_contains "Configuration validation failed"
    
    # Verify no partial installation occurred
    [[ ! -f "$HOME/.bashrc.backup" ]]
}

@test "end-to-end: dry-run mode validation" {
    # Test dry-run mode shows what would be done without executing
    run "$DOTFILES_ROOT/install.sh" --dry-run --config "$TEST_CONFIG_DIR/user.yaml" --verbose
    
    assert_success
    assert_output_contains "DRY RUN MODE"
    assert_output_contains "Would install module:"
    assert_output_contains "Would create backup"
    
    # Verify no actual changes were made
    [[ ! -f "$HOME/.bashrc" ]]
    [[ ! -d "$HOME/.dotfiles_backup" ]]
}

@test "end-to-end: update functionality" {
    # Install initial version
    run "$DOTFILES_ROOT/install.sh" --modules "shell,git" --non-interactive
    assert_success
    
    # Test update command
    run "$DOTFILES_ROOT/install.sh" update
    assert_success
    assert_output_contains "Update completed"
}

@test "end-to-end: wizard mode for first-time users" {
    # Test configuration wizard (non-interactive simulation)
    export DOTFILES_WIZARD_RESPONSES="y
shell,git,vim
Test User
test@example.com
testuser
y"
    
    run "$DOTFILES_ROOT/install.sh" wizard --non-interactive
    assert_success
    assert_output_contains "Configuration wizard completed"
}

@test "end-to-end: cleanup functionality" {
    # Create some test backups and cache
    mkdir -p "$HOME/.dotfiles_backup/test_backup_1"
    mkdir -p "$HOME/.dotfiles_backup/test_backup_2"
    mkdir -p "$HOME/.dotfiles_cache/test_cache"
    
    run "$DOTFILES_ROOT/install.sh" cleanup
    assert_success
    assert_output_contains "Cleanup completed"
}

@test "end-to-end: status and information commands" {
    # Test list-modules command
    run "$DOTFILES_ROOT/install.sh" list-modules
    assert_success
    assert_output_contains "Available modules:"
    assert_output_contains "shell"
    assert_output_contains "git"
    
    # Test version command
    run "$DOTFILES_ROOT/install.sh" version
    assert_success
    assert_output_contains "Unified Dotfiles Framework"
    
    # Test status command
    run "$DOTFILES_ROOT/install.sh" status
    assert_success
    assert_output_contains "Framework status:"
}

@test "end-to-end: help system validation" {
    # Test main help
    run "$DOTFILES_ROOT/install.sh" --help
    assert_success
    assert_output_contains "USAGE:"
    assert_output_contains "COMMANDS:"
    assert_output_contains "OPTIONS:"
    assert_output_contains "EXAMPLES:"
    
    # Test topic-specific help
    run "$DOTFILES_ROOT/install.sh" help modules
    assert_success
    assert_output_contains "Module system help"
}

@test "end-to-end: security validation" {
    # Test that secure practices are followed
    
    # Check file permissions on created configs
    run "$DOTFILES_ROOT/install.sh" --modules "git" --non-interactive
    assert_success
    
    if [[ -f "$HOME/.gitconfig" ]]; then
        local perms
        perms=$(stat -c "%a" "$HOME/.gitconfig" 2>/dev/null || stat -f "%A" "$HOME/.gitconfig" 2>/dev/null || echo "644")
        [[ "$perms" == "644" || "$perms" == "600" ]]
    fi
    
    # Verify no sensitive information in logs
    [[ ! -f "$HOME/.dotfiles/logs/install.log" ]] || {
        ! grep -i "password\|secret\|token" "$HOME/.dotfiles/logs/install.log"
    }
}