#!/usr/bin/env bats

# Override system testing for unified dotfiles framework
# Tests environment-specific overrides, conditional configurations, and configuration inheritance

load '../helpers/test_helpers'

setup() {
    setup_test_environment
    
    # Create base configuration
    create_test_config "base" "
modules:
  enabled:
    - shell
    - git
  disabled:
    - docker

settings:
  backup_enabled: true
  interactive_mode: false

user:
  name: 'Base User'
  email: 'base@example.com'
  github_username: 'baseuser'
"
}

teardown() {
    teardown_test_environment
}

@test "override: platform-based overrides" {
    local current_platform
    current_platform=$(detect_current_platform)
    
    # Create platform-specific override
    create_test_config "platform_override" "
platform:
  ${current_platform}:
    modules:
      enabled:
        - shell
        - git
        - platform-specific-tool
    user:
      email: 'platform@example.com'
    settings:
      platform_optimized: true
"
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/base.yaml" --override "$TEST_CONFIG_DIR/platform_override.yaml" --dry-run --verbose
    
    assert_success
    assert_output_contains "Applied platform override for: $current_platform"
    assert_output_contains "platform@example.com"
    assert_output_contains "platform_optimized: true"
}

@test "override: hostname-based overrides" {
    local current_hostname
    current_hostname=$(hostname)
    
    # Create hostname-specific override
    create_test_config "hostname_override" "
hostname:
  '${current_hostname}':
    modules:
      enabled:
        - shell
        - git
        - hostname-specific-tool
    user:
      email: 'hostname@example.com'
    settings:
      hostname_config: true
"
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/base.yaml" --override "$TEST_CONFIG_DIR/hostname_override.yaml" --dry-run --verbose
    
    assert_success
    assert_output_contains "Applied hostname override for: $current_hostname"
    assert_output_contains "hostname@example.com"
}

@test "override: environment variable based overrides" {
    # Set test environment variable
    export TEST_ENV="work"
    
    # Create environment-based override
    create_test_config "env_override" "
environment:
  TEST_ENV:
    modules:
      enabled:
        - shell
        - git
        - work-tools
    user:
      email: 'work@company.com'
    settings:
      work_mode: true
"
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/base.yaml" --override "$TEST_CONFIG_DIR/env_override.yaml" --dry-run --verbose
    
    assert_success
    assert_output_contains "Applied environment override for: TEST_ENV=work"
    assert_output_contains "work@company.com"
    
    unset TEST_ENV
}

@test "override: custom condition overrides" {
    # Create condition-based override
    create_test_config "condition_override" "
conditions:
  - condition: 'test -d /tmp'
    overrides:
      modules:
        enabled:
          - shell
          - git
          - tmp-tools
      settings:
        tmp_available: true
  - condition: 'command -v git >/dev/null 2>&1'
    overrides:
      settings:
        git_available: true
"
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/base.yaml" --override "$TEST_CONFIG_DIR/condition_override.yaml" --dry-run --verbose
    
    assert_success
    assert_output_contains "Applied condition override"
    assert_output_contains "tmp_available: true"
    assert_output_contains "git_available: true"
}

@test "override: multiple override precedence" {
    local current_platform current_hostname
    current_platform=$(detect_current_platform)
    current_hostname=$(hostname)
    
    # Create multiple overrides with different precedence
    create_test_config "multi_override" "
# Platform override (lower precedence)
platform:
  ${current_platform}:
    user:
      email: 'platform@example.com'
    settings:
      source: 'platform'

# Hostname override (higher precedence)
hostname:
  '${current_hostname}':
    user:
      email: 'hostname@example.com'
    settings:
      source: 'hostname'
      hostname_specific: true
"
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/base.yaml" --override "$TEST_CONFIG_DIR/multi_override.yaml" --dry-run --verbose
    
    assert_success
    # Hostname should override platform
    assert_output_contains "hostname@example.com"
    assert_output_contains "source: 'hostname'"
    assert_output_contains "hostname_specific: true"
}

@test "override: configuration inheritance" {
    # Create parent configuration
    create_test_config "parent" "
modules:
  enabled:
    - shell
    - git
settings:
  parent_setting: true
user:
  name: 'Parent User'
"
    
    # Create child configuration that extends parent
    create_test_config "child" "
extends: '${TEST_CONFIG_DIR}/parent.yaml'
modules:
  enabled:
    - shell
    - git
    - vim  # Additional module
settings:
  child_setting: true
  parent_setting: false  # Override parent setting
user:
  email: 'child@example.com'  # Additional field
"
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/child.yaml" --dry-run --verbose
    
    assert_success
    assert_output_contains "Loaded configuration inheritance"
    assert_output_contains "child@example.com"
    assert_output_contains "child_setting: true"
    assert_output_contains "parent_setting: false"  # Should be overridden
}

@test "override: work environment complete scenario" {
    # Set up work environment
    export WORK_ENV="true"
    export COMPANY_DOMAIN="company.com"
    
    # Create comprehensive work override
    create_test_config "work_complete" "
# Environment-based override
environment:
  WORK_ENV:
    modules:
      enabled:
        - shell
        - git
        - corporate-vpn
        - company-tools
      disabled:
        - personal-tools
    user:
      email: 'user@company.com'
    settings:
      git_signing_enabled: true
      corporate_proxy: true

# Hostname-based override for work laptop
hostname:
  'work-laptop':
    modules:
      enabled:
        - shell
        - git
        - corporate-vpn
        - company-tools
        - laptop-specific
    settings:
      mobile_optimizations: true

# Condition-based overrides
conditions:
  - condition: 'test -d /opt/company'
    overrides:
      modules:
        enabled:
          - company-integration
  - condition: 'ping -c 1 corporate.intranet >/dev/null 2>&1'
    overrides:
      settings:
        intranet_available: true
"
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/base.yaml" --override "$TEST_CONFIG_DIR/work_complete.yaml" --dry-run --verbose
    
    assert_success
    assert_output_contains "Applied environment override for: WORK_ENV=true"
    assert_output_contains "user@company.com"
    assert_output_contains "corporate-vpn"
    assert_output_contains "git_signing_enabled: true"
    
    unset WORK_ENV COMPANY_DOMAIN
}

@test "override: personal environment complete scenario" {
    # Set up personal environment
    export PERSONAL_ENV="true"
    
    # Create comprehensive personal override
    create_test_config "personal_complete" "
environment:
  PERSONAL_ENV:
    modules:
      enabled:
        - shell
        - git
        - vim
        - tmux
        - media-tools
        - gaming-tools
      disabled:
        - corporate-tools
    user:
      email: 'personal@gmail.com'
    settings:
      fun_mode: true
      performance_optimized: true

# Condition-based overrides for personal setup
conditions:
  - condition: 'command -v steam >/dev/null 2>&1'
    overrides:
      modules:
        enabled:
          - gaming-enhancements
  - condition: 'test -d ~/Music'
    overrides:
      modules:
        enabled:
          - music-tools
"
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/base.yaml" --override "$TEST_CONFIG_DIR/personal_complete.yaml" --dry-run --verbose
    
    assert_success
    assert_output_contains "Applied environment override for: PERSONAL_ENV=true"
    assert_output_contains "personal@gmail.com"
    assert_output_contains "media-tools"
    assert_output_contains "fun_mode: true"
    
    unset PERSONAL_ENV
}

@test "override: invalid override handling" {
    # Create invalid override configuration
    create_test_config "invalid_override" "
invalid_section:
  unknown_key: value
platform:
  invalid_platform:
    modules:
      enabled: [invalid-module]
"
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/base.yaml" --override "$TEST_CONFIG_DIR/invalid_override.yaml" --dry-run
    
    # Should handle invalid overrides gracefully
    assert_success
    assert_output_contains "Warning: Unknown override section"
}

@test "override: dynamic override generation" {
    # Test dynamic override generation based on system state
    run "$DOTFILES_ROOT/install.sh" --generate-override "auto" --dry-run --verbose
    
    assert_success
    assert_output_contains "Generated automatic overrides"
    assert_output_contains "Platform:"
    assert_output_contains "Hostname:"
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