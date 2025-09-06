#!/usr/bin/env bats

# Platform-specific testing for unified dotfiles framework
# Tests platform detection, package manager integration, and platform-specific configurations

load '../helpers/test_helpers'

setup() {
    setup_test_environment
}

teardown() {
    teardown_test_environment
}

@test "platform: macOS detection and package manager integration" {
    skip_unless_platform "macos"
    
    # Test platform detection
    run "$DOTFILES_ROOT/core/platform.sh" detect_platform
    assert_success
    assert_output "macos"
    
    # Test Homebrew detection/installation
    run "$DOTFILES_ROOT/install.sh" --modules "homebrew" --non-interactive --dry-run
    assert_success
    assert_output_contains "Would install Homebrew"
    
    # Test macOS-specific module installation
    run "$DOTFILES_ROOT/install.sh" --modules "shell,git" --non-interactive --dry-run
    assert_success
    assert_output_contains "Platform: macOS"
    assert_output_contains "Package manager: brew"
}

@test "platform: Ubuntu detection and package manager integration" {
    skip_unless_platform "ubuntu"
    
    # Test platform detection
    run "$DOTFILES_ROOT/core/platform.sh" detect_platform
    assert_success
    assert_output "ubuntu"
    
    # Test apt package manager integration
    run "$DOTFILES_ROOT/install.sh" --modules "git,vim" --non-interactive --dry-run
    assert_success
    assert_output_contains "Platform: Ubuntu"
    assert_output_contains "Package manager: apt"
    assert_output_contains "Would install: git"
    assert_output_contains "Would install: vim"
}

@test "platform: WSL detection and configuration" {
    skip_unless_platform "wsl"
    
    # Test WSL detection
    run "$DOTFILES_ROOT/core/platform.sh" detect_platform
    assert_success
    assert_output "wsl"
    
    # Test WSL-specific configurations
    run "$DOTFILES_ROOT/install.sh" --modules "shell" --non-interactive --dry-run
    assert_success
    assert_output_contains "Platform: WSL"
    assert_output_contains "WSL-specific configuration"
}

@test "platform: Amazon Linux 2 detection and package manager integration" {
    skip_unless_platform "amazon-linux"
    
    # Test platform detection
    run "$DOTFILES_ROOT/core/platform.sh" detect_platform
    assert_success
    assert_output "amazon-linux"
    
    # Test yum/dnf package manager integration
    run "$DOTFILES_ROOT/install.sh" --modules "git,vim" --non-interactive --dry-run
    assert_success
    assert_output_contains "Platform: Amazon Linux"
    assert_output_contains "Package manager: yum"
}

@test "platform: cross-platform module compatibility" {
    # Test that core modules work on all platforms
    local current_platform
    current_platform=$(detect_current_platform)
    
    # Test shell module on current platform
    run "$DOTFILES_ROOT/install.sh" --modules "shell" --non-interactive --dry-run
    assert_success
    assert_output_contains "Platform: "
    assert_output_contains "Would install module: shell"
    
    # Test git module on current platform
    run "$DOTFILES_ROOT/install.sh" --modules "git" --non-interactive --dry-run
    assert_success
    assert_output_contains "Would install module: git"
}

@test "platform: package manager detection and validation" {
    local current_platform
    current_platform=$(detect_current_platform)
    
    # Test package manager detection
    run "$DOTFILES_ROOT/core/platform.sh" get_package_manager
    assert_success
    
    case "$current_platform" in
        macos)
            assert_output "brew"
            ;;
        ubuntu|wsl)
            assert_output "apt"
            ;;
        amazon-linux)
            [[ "$output" == "yum" || "$output" == "dnf" ]]
            ;;
    esac
}

@test "platform: platform-specific configuration overrides" {
    local current_platform
    current_platform=$(detect_current_platform)
    
    # Create platform-specific override
    create_test_config "platform_override" "
platform:
  ${current_platform}:
    modules:
      enabled:
        - platform-specific-tool
    settings:
      platform_setting: true
"
    
    run "$DOTFILES_ROOT/install.sh" --override "$TEST_CONFIG_DIR/platform_override.yaml" --dry-run --verbose
    assert_success
    assert_output_contains "Applied platform override for: $current_platform"
}

@test "platform: minimum OS version validation" {
    # Test that minimum OS version requirements are checked
    run "$DOTFILES_ROOT/core/platform.sh" check_minimum_version
    assert_success
    
    # Should not fail on supported platforms
    local current_platform
    current_platform=$(detect_current_platform)
    [[ "$current_platform" != "unsupported" ]]
}

@test "platform: platform-specific dependency installation" {
    local current_platform
    current_platform=$(detect_current_platform)
    
    # Test that platform-specific dependencies are identified
    run "$DOTFILES_ROOT/install.sh" --modules "developer-tools" --non-interactive --dry-run --verbose
    assert_success
    
    case "$current_platform" in
        macos)
            assert_output_contains "xcode-select"
            ;;
        ubuntu)
            assert_output_contains "build-essential"
            ;;
        amazon-linux)
            assert_output_contains "Development Tools"
            ;;
    esac
}

@test "platform: unsupported platform handling" {
    # Mock unsupported platform
    export PLATFORM_OVERRIDE="unsupported"
    
    run "$DOTFILES_ROOT/install.sh" --non-interactive
    assert_failure
    assert_output_contains "Unsupported platform"
    assert_output_contains "supported platforms"
}

# Helper function to detect current platform
detect_current_platform() {
    case "$OSTYPE" in
        darwin*) echo "macos" ;;
        linux-gnu*)
            if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
                echo "wsl"
            elif [[ -f /etc/os-release ]]; then
                if grep -q "ID=amzn" /etc/os-release; then
                    echo "amazon-linux"
                else
                    echo "ubuntu"
                fi
            else
                echo "ubuntu"
            fi
            ;;
        *) echo "unsupported" ;;
    esac
}

# Helper function to skip tests unless on specific platform
skip_unless_platform() {
    local required_platform="$1"
    local current_platform
    current_platform=$(detect_current_platform)
    
    if [[ "$current_platform" != "$required_platform" ]]; then
        skip "Test requires platform: $required_platform (current: $current_platform)"
    fi
}