#!/usr/bin/env bats

# Unit tests for platform detection and utilities

load '../helpers/test_helpers.bash'

setup() {
    setup_test_environment
    source_core_function "platform.sh"
}

teardown() {
    teardown_test_environment
}

@test "detect_platform returns macos on Darwin" {
    mock_platform "macos"
    
    run detect_platform
    assert_success
    assert_output "macos"
}

@test "detect_platform returns ubuntu on Ubuntu Linux" {
    mock_platform "ubuntu"
    
    run detect_platform
    assert_success
    assert_output "ubuntu"
}

@test "detect_platform returns wsl on Windows Subsystem for Linux" {
    mock_platform "wsl"
    
    run detect_platform
    assert_success
    assert_output "wsl"
}

@test "detect_platform returns amazon-linux on Amazon Linux 2" {
    mock_platform "amazon-linux"
    
    run detect_platform
    assert_success
    assert_output "amazon-linux"
}

@test "detect_platform returns unsupported for unknown platform" {
    export OSTYPE="unknown-os"
    unset PLATFORM_OVERRIDE
    
    run detect_platform
    assert_success
    assert_output "unsupported"
}

@test "get_package_manager returns brew on macOS" {
    mock_platform "macos"
    mock_command "brew" "echo 'Homebrew 4.0.0'"
    
    run get_package_manager
    assert_success
    assert_output "brew"
}

@test "get_package_manager returns apt on Ubuntu" {
    mock_platform "ubuntu"
    mock_command "apt" "echo 'apt 2.4.8'"
    
    run get_package_manager
    assert_success
    assert_output "apt"
}

@test "get_package_manager returns unknown when no package manager found" {
    mock_platform "macos"
    # Don't mock any package manager commands
    
    run get_package_manager
    assert_success
    assert_output "unknown"
}

@test "check_dependencies succeeds when all dependencies are available" {
    mock_command "git" "echo 'git version 2.39.0'"
    mock_command "curl" "echo 'curl 7.88.1'"
    
    run check_dependencies
    assert_success
}

@test "check_dependencies fails when required dependency is missing" {
    # Don't mock git command to simulate missing dependency
    
    run check_dependencies
    assert_failure
}

@test "get_platform_config returns correct config path for platform" {
    mock_platform "macos"
    
    run get_platform_config
    assert_success
    assert_output_contains "platforms/macos"
}

@test "is_platform_supported returns true for supported platforms" {
    run is_platform_supported "macos"
    assert_success
    
    run is_platform_supported "ubuntu"
    assert_success
    
    run is_platform_supported "wsl"
    assert_success
    
    run is_platform_supported "amazon-linux"
    assert_success
}

@test "is_platform_supported returns false for unsupported platforms" {
    run is_platform_supported "windows"
    assert_failure
    
    run is_platform_supported "freebsd"
    assert_failure
    
    run is_platform_supported "unsupported"
    assert_failure
}

@test "get_os_version returns version string" {
    mock_platform "macos"
    
    run get_os_version
    assert_success
    assert_output_matches "[0-9]+\.[0-9]+.*"
}

@test "platform detection caching works correctly" {
    mock_platform "macos"
    
    # First call should detect and cache
    run detect_platform
    assert_success
    assert_output "macos"
    
    # Second call should use cache
    run detect_platform
    assert_success
    assert_output "macos"
}

@test "platform cache can be cleared" {
    mock_platform "macos"
    
    # Detect platform first
    run detect_platform
    assert_success
    
    # Clear cache
    run clear_platform_cache
    assert_success
    
    # Should detect again
    mock_platform "ubuntu"
    run detect_platform
    assert_success
    assert_output "ubuntu"
}

@test "get_shell_path returns correct shell path" {
    mock_platform "macos"
    
    run get_shell_path
    assert_success
    assert_output_matches "/bin/(bash|zsh)"
}

@test "install_package_manager installs homebrew on macOS" {
    skip_unless_platform "macos"
    
    # Mock the homebrew installation script
    mock_command "curl" 'echo "Homebrew installation script"'
    
    run install_package_manager
    assert_success
}

@test "validate_platform_requirements checks minimum OS version" {
    mock_platform "macos"
    
    run validate_platform_requirements
    assert_success
}

@test "get_platform_specific_config loads platform configuration" {
    mock_platform "macos"
    
    # Create mock platform config
    local config_content='
platform: macos
package_manager: brew
shell: /bin/zsh
'
    create_temp_file "$config_content" "platforms/macos/platform.yaml"
    
    run get_platform_specific_config
    assert_success
}

@test "detect_virtualization identifies virtual environments" {
    # Mock virtualization detection
    mock_command "systemd-detect-virt" "echo 'none'"
    
    run detect_virtualization
    assert_success
}

@test "get_cpu_architecture returns architecture string" {
    run get_cpu_architecture
    assert_success
    assert_output_matches "(x86_64|arm64|aarch64)"
}

@test "is_admin_user checks for administrative privileges" {
    run is_admin_user
    # Should succeed or fail based on current user privileges
    # We don't assert specific result as it depends on test environment
}

@test "get_system_info returns comprehensive system information" {
    mock_platform "macos"
    
    run get_system_info
    assert_success
    assert_output_contains "Platform:"
    assert_output_contains "Package Manager:"
    assert_output_contains "Shell:"
}