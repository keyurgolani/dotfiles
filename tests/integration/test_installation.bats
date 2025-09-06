#!/usr/bin/env bats

# Integration tests for complete installation workflows

load '../helpers/test_helpers.bash'

setup() {
    setup_test_environment
    
    # Source all core functions
    source_core_function "platform.sh"
    source_core_function "config.sh"
    source_core_function "backup.sh"
    source_core_function "modules.sh"
    source_core_function "logger.sh"
    source_core_function "utils.sh"
}

teardown() {
    teardown_test_environment
}

@test "complete installation workflow on macOS" {
    mock_platform "macos"
    
    # Create test configuration
    local modules_config='
modules:
  enabled:
    - shell
    - git
settings:
  backup_enabled: true
  interactive_mode: false
'
    create_test_config "modules" "$modules_config"
    
    local user_config='
user:
  name: "Test User"
  email: "test@example.com"
  github_username: "testuser"
'
    create_test_config "user" "$user_config"
    
    # Create existing dotfiles to test backup
    create_test_dotfiles ".bashrc" ".gitconfig"
    
    # Mock package manager
    mock_command "brew" "echo 'Installing packages...'"
    
    # Run installation
    run "$DOTFILES_ROOT/install.sh" --non-interactive
    assert_success
    
    # Verify backup was created
    assert_backup_created
    
    # Verify configurations were applied
    assert_config_applied "$HOME/.bashrc"
    assert_config_applied "$HOME/.gitconfig"
}

@test "complete installation workflow on Ubuntu" {
    mock_platform "ubuntu"
    
    # Create test configuration
    local modules_config='
modules:
  enabled:
    - shell
    - git
    - vim
settings:
  backup_enabled: true
  interactive_mode: false
'
    create_test_config "modules" "$modules_config"
    
    # Mock package manager
    mock_command "apt" "echo 'Installing packages...'"
    mock_command "sudo" "echo 'Running with sudo: $*'"
    
    # Run installation
    run "$DOTFILES_ROOT/install.sh" --platform ubuntu --non-interactive
    assert_success
    
    # Verify platform-specific configurations
    assert_config_applied "$HOME/.bashrc"
    assert_config_applied "$HOME/.vimrc"
}

@test "installation with module selection" {
    mock_platform "macos"
    
    # Create configuration with specific modules
    local modules_config='
modules:
  enabled:
    - git
    - vim
  disabled:
    - shell
    - tmux
'
    create_test_config "modules" "$modules_config"
    
    # Run installation with module selection
    run "$DOTFILES_ROOT/install.sh" --modules "git,vim" --non-interactive
    assert_success
    
    # Verify only selected modules were installed
    assert_config_applied "$HOME/.gitconfig"
    assert_config_applied "$HOME/.vimrc"
    
    # Verify disabled modules were not installed
    assert_file_not_exist "$HOME/.tmux.conf"
}

@test "installation with backup and restore" {
    mock_platform "macos"
    
    # Create existing dotfiles
    create_test_dotfiles ".bashrc" ".vimrc"
    echo "original bashrc content" > "$HOME/.bashrc"
    echo "original vimrc content" > "$HOME/.vimrc"
    
    # Run installation
    run "$DOTFILES_ROOT/install.sh" --backup --non-interactive
    assert_success
    
    # Verify backup was created
    assert_backup_created
    
    # Verify new configurations were applied
    assert_config_applied "$HOME/.bashrc"
    assert_config_applied "$HOME/.vimrc"
    
    # Test restore functionality
    run "$DOTFILES_ROOT/install.sh" --restore-latest
    assert_success
    
    # Verify original content was restored
    run cat "$HOME/.bashrc"
    assert_output_contains "original bashrc content"
}

@test "installation with override system" {
    mock_platform "macos"
    
    # Create base configuration
    local base_config='
modules:
  enabled:
    - shell
    - git
user:
  name: "Base User"
  email: "base@example.com"
'
    create_test_config "modules" "$base_config"
    
    # Create platform override
    local override_config='
modules:
  enabled:
    - shell
    - git
    - homebrew
user:
  email: "macos@example.com"
'
    mkdir -p "$TEST_TEMP_DIR/config/overrides/platform"
    echo "$override_config" > "$TEST_TEMP_DIR/config/overrides/platform/macos.yaml"
    
    # Run installation
    run "$DOTFILES_ROOT/install.sh" --apply-overrides --non-interactive
    assert_success
    
    # Verify override was applied
    assert_config_applied "$HOME/.gitconfig" "macos@example.com"
}

@test "installation with dependency resolution" {
    mock_platform "ubuntu"
    
    # Create modules with dependencies
    setup_test_module "base"
    setup_test_module "dependent"
    
    # Add dependency to dependent module
    cat >> "$TEST_TEMP_DIR/modules/dependent/module.yaml" << 'EOF'
dependencies:
  - base
EOF
    
    local modules_config='
modules:
  enabled:
    - dependent
'
    create_test_config "modules" "$modules_config"
    
    # Run installation
    run "$DOTFILES_ROOT/install.sh" --non-interactive
    assert_success
    
    # Verify both modules were installed in correct order
    assert_config_applied "$HOME/.baserc"
    assert_config_applied "$HOME/.dependentrc"
}

@test "installation with hook execution" {
    mock_platform "macos"
    
    # Create test module with hooks
    local module_dir
    module_dir=$(setup_test_module "hooked")
    
    # Create pre-install hook
    mkdir -p "$module_dir/scripts"
    cat > "$module_dir/scripts/pre_install.sh" << 'EOF'
#!/bin/bash
echo "Pre-install hook executed" > "$HOME/.pre_install_marker"
EOF
    chmod +x "$module_dir/scripts/pre_install.sh"
    
    # Create post-install hook
    cat > "$module_dir/scripts/post_install.sh" << 'EOF'
#!/bin/bash
echo "Post-install hook executed" > "$HOME/.post_install_marker"
EOF
    chmod +x "$module_dir/scripts/post_install.sh"
    
    # Update module configuration to include hooks
    cat >> "$module_dir/module.yaml" << 'EOF'
hooks:
  pre_install: "scripts/pre_install.sh"
  post_install: "scripts/post_install.sh"
EOF
    
    local modules_config='
modules:
  enabled:
    - hooked
'
    create_test_config "modules" "$modules_config"
    
    # Run installation
    run "$DOTFILES_ROOT/install.sh" --non-interactive
    assert_success
    
    # Verify hooks were executed
    assert_file_exist "$HOME/.pre_install_marker"
    assert_file_exist "$HOME/.post_install_marker"
    assert_file_contains "$HOME/.pre_install_marker" "Pre-install hook executed"
    assert_file_contains "$HOME/.post_install_marker" "Post-install hook executed"
}

@test "installation with template processing" {
    mock_platform "macos"
    
    # Set environment variables for template processing
    export DOTFILES_USER_NAME="Template User"
    export DOTFILES_USER_EMAIL="template@example.com"
    
    # Create module with template
    local module_dir
    module_dir=$(setup_test_module "templated")
    
    # Create template file
    cat > "$module_dir/config/templatedrc" << 'EOF'
# Configuration for {{USER_NAME}}
user_name={{USER_NAME}}
user_email={{USER_EMAIL}}
platform={{PLATFORM}}
EOF
    
    # Update module to use template
    cat > "$module_dir/module.yaml" << 'EOF'
name: "templated"
version: "1.0.0"
files:
  - source: "config/templatedrc"
    target: "~/.templatedrc"
    template: true
EOF
    
    local modules_config='
modules:
  enabled:
    - templated
'
    create_test_config "modules" "$modules_config"
    
    # Run installation
    run "$DOTFILES_ROOT/install.sh" --non-interactive
    assert_success
    
    # Verify template was processed
    assert_config_applied "$HOME/.templatedrc" "Template User"
    assert_config_applied "$HOME/.templatedrc" "template@example.com"
    assert_config_applied "$HOME/.templatedrc" "macos"
}

@test "installation with error handling and recovery" {
    mock_platform "macos"
    
    # Create module that will fail
    local module_dir
    module_dir=$(setup_test_module "failing")
    
    # Create failing install script
    cat > "$module_dir/install.sh" << 'EOF'
#!/bin/bash
echo "This module will fail"
exit 1
EOF
    chmod +x "$module_dir/install.sh"
    
    local modules_config='
modules:
  enabled:
    - failing
'
    create_test_config "modules" "$modules_config"
    
    # Run installation (should fail gracefully)
    run "$DOTFILES_ROOT/install.sh" --non-interactive
    assert_failure
    
    # Verify error was logged
    assert_output_contains "Installation failed"
    
    # Verify cleanup was performed
    # (specific cleanup behavior depends on implementation)
}

@test "installation with parallel module processing" {
    mock_platform "macos"
    
    # Create multiple independent modules
    setup_test_module "parallel1"
    setup_test_module "parallel2"
    setup_test_module "parallel3"
    
    local modules_config='
modules:
  enabled:
    - parallel1
    - parallel2
    - parallel3
settings:
  parallel_installation: true
'
    create_test_config "modules" "$modules_config"
    
    # Run installation with parallel processing
    run "$DOTFILES_ROOT/install.sh" --parallel --non-interactive
    assert_success
    
    # Verify all modules were installed
    assert_config_applied "$HOME/.parallel1rc"
    assert_config_applied "$HOME/.parallel2rc"
    assert_config_applied "$HOME/.parallel3rc"
}

@test "installation dry-run mode" {
    mock_platform "macos"
    
    # Create test configuration
    local modules_config='
modules:
  enabled:
    - shell
    - git
'
    create_test_config "modules" "$modules_config"
    
    # Run dry-run installation
    run "$DOTFILES_ROOT/install.sh" --dry-run --non-interactive
    assert_success
    
    # Verify no actual changes were made
    assert_file_not_exist "$HOME/.bashrc"
    assert_file_not_exist "$HOME/.gitconfig"
    
    # Verify dry-run output shows what would be done
    assert_output_contains "Would install"
    assert_output_contains "shell"
    assert_output_contains "git"
}

@test "installation with configuration validation" {
    mock_platform "macos"
    
    # Create invalid configuration
    local invalid_config='
modules:
  enabled:
    - nonexistent_module
user:
  # Missing required email field
  name: "Test User"
'
    create_test_config "modules" "$invalid_config"
    
    # Run installation (should fail validation)
    run "$DOTFILES_ROOT/install.sh" --validate --non-interactive
    assert_failure
    
    # Verify validation errors are reported
    assert_output_contains "Configuration validation failed"
}

@test "installation update mode" {
    mock_platform "macos"
    
    # Create initial configuration
    local modules_config='
modules:
  enabled:
    - shell
'
    create_test_config "modules" "$modules_config"
    
    # Run initial installation
    run "$DOTFILES_ROOT/install.sh" --non-interactive
    assert_success
    
    # Modify configuration to add module
    local updated_config='
modules:
  enabled:
    - shell
    - git
'
    create_test_config "modules" "$updated_config"
    
    # Run update installation
    run "$DOTFILES_ROOT/install.sh" --update --non-interactive
    assert_success
    
    # Verify new module was added
    assert_config_applied "$HOME/.gitconfig"
    
    # Verify existing module was preserved
    assert_config_applied "$HOME/.bashrc"
}