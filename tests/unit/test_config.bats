#!/usr/bin/env bats

# Unit tests for configuration management system

load '../helpers/test_helpers.bash'

setup() {
    setup_test_environment
    source_core_function "config.sh"
}

teardown() {
    teardown_test_environment
}

@test "detect_yaml_parser finds yq when available" {
    mock_command "yq" "echo 'yq (https://github.com/mikefarah/yq/) version 4.30.8'"
    
    run detect_yaml_parser
    assert_success
    assert_output "yq"
}

@test "detect_yaml_parser finds python3 with PyYAML when yq not available" {
    mock_command "python3" "
        if [[ \"\$1\" == \"-c\" && \"\$2\" == \"import yaml\" ]]; then
            exit 0
        fi
        echo 'Python 3.9.0'
    "
    
    run detect_yaml_parser
    assert_success
    assert_output "python3"
}

@test "detect_yaml_parser returns none when no parser available" {
    # Don't mock any YAML parsers
    
    run detect_yaml_parser
    assert_success
    assert_output "none"
}

@test "load_config loads valid YAML configuration" {
    local config_content='
modules:
  enabled:
    - shell
    - git
user:
  name: "Test User"
  email: "test@example.com"
'
    local config_file
    config_file=$(create_temp_file "$config_content" "test_config.yaml")
    
    mock_command "yq" "
        case \"\$1\" in
            'eval') echo 'modules.enabled=[\"shell\",\"git\"]' ;;
            *) cat \"\$2\" ;;
        esac
    "
    
    run load_config "$config_file"
    assert_success
}

@test "load_config fails with invalid YAML" {
    local invalid_config='
modules:
  enabled:
    - shell
    - git
  invalid_yaml: [
'
    local config_file
    config_file=$(create_temp_file "$invalid_config" "invalid_config.yaml")
    
    run load_config "$config_file"
    assert_failure
}

@test "validate_config succeeds with valid configuration" {
    local valid_config='
modules:
  enabled:
    - shell
    - git
user:
  name: "Test User"
  email: "test@example.com"
'
    local config_file
    config_file=$(create_temp_file "$valid_config" "valid_config.yaml")
    
    run validate_config "$config_file"
    assert_success
}

@test "validate_config fails with missing required fields" {
    local incomplete_config='
modules:
  enabled:
    - shell
# Missing user section
'
    local config_file
    config_file=$(create_temp_file "$incomplete_config" "incomplete_config.yaml")
    
    run validate_config "$config_file"
    assert_failure
}

@test "merge_configs combines multiple configuration files" {
    local base_config='
modules:
  enabled:
    - shell
user:
  name: "Base User"
'
    local override_config='
modules:
  enabled:
    - shell
    - git
user:
  email: "override@example.com"
'
    
    local base_file override_file
    base_file=$(create_temp_file "$base_config" "base.yaml")
    override_file=$(create_temp_file "$override_config" "override.yaml")
    
    mock_command "yq" "
        case \"\$*\" in
            *'merge'*) echo 'modules.enabled=[\"shell\",\"git\"]' ;;
            *) cat \"\$2\" ;;
        esac
    "
    
    run merge_configs "$base_file" "$override_file"
    assert_success
}

@test "substitute_variables replaces environment variables in config" {
    export TEST_USER="Test User"
    export TEST_EMAIL="test@example.com"
    
    local config_with_vars='
user:
  name: "${TEST_USER}"
  email: "${TEST_EMAIL}"
'
    local config_file
    config_file=$(create_temp_file "$config_with_vars" "config_with_vars.yaml")
    
    run substitute_variables "$config_file"
    assert_success
    
    # Check that variables were substituted
    run cat "$config_file"
    assert_output_contains "Test User"
    assert_output_contains "test@example.com"
}

@test "get_config_value retrieves specific configuration values" {
    local config_content='
user:
  name: "Test User"
  email: "test@example.com"
modules:
  enabled:
    - shell
    - git
'
    local config_file
    config_file=$(create_temp_file "$config_content" "test_config.yaml")
    
    mock_command "yq" "
        case \"\$2\" in
            '.user.name') echo 'Test User' ;;
            '.user.email') echo 'test@example.com' ;;
            '.modules.enabled[]') echo -e 'shell\ngit' ;;
            *) echo 'null' ;;
        esac
    "
    
    run get_config_value "$config_file" ".user.name"
    assert_success
    assert_output "Test User"
    
    run get_config_value "$config_file" ".user.email"
    assert_success
    assert_output "test@example.com"
}

@test "set_config_value updates configuration values" {
    local config_content='
user:
  name: "Old Name"
  email: "old@example.com"
'
    local config_file
    config_file=$(create_temp_file "$config_content" "test_config.yaml")
    
    mock_command "yq" "
        if [[ \"\$1\" == 'eval' && \"\$2\" == '.user.name = \"New Name\"' ]]; then
            sed 's/Old Name/New Name/' \"\$4\"
        else
            cat \"\$4\"
        fi
    "
    
    run set_config_value "$config_file" ".user.name" "New Name"
    assert_success
}

@test "validate_schema checks configuration against JSON schema" {
    skip_if_missing "jsonschema"
    
    local config_content='
{
  "user": {
    "name": "Test User",
    "email": "test@example.com"
  },
  "modules": {
    "enabled": ["shell", "git"]
  }
}
'
    local config_file
    config_file=$(create_temp_file "$config_content" "test_config.json")
    
    # Mock schema file
    local schema_content='
{
  "type": "object",
  "properties": {
    "user": {
      "type": "object",
      "properties": {
        "name": {"type": "string"},
        "email": {"type": "string"}
      },
      "required": ["name", "email"]
    }
  },
  "required": ["user"]
}
'
    local schema_file
    schema_file=$(create_temp_file "$schema_content" "test_schema.json")
    
    run validate_schema "$config_file" "$schema_file"
    assert_success
}

@test "load_user_config loads user-specific configuration" {
    local user_config='
user:
  name: "User Name"
  email: "user@example.com"
  github_username: "username"
preferences:
  editor: "vim"
  shell: "/bin/zsh"
'
    create_test_config "user" "$user_config"
    
    run load_user_config
    assert_success
}

@test "load_modules_config loads module configuration" {
    local modules_config='
modules:
  enabled:
    - shell
    - git
    - vim
  disabled:
    - docker
settings:
  backup_enabled: true
  interactive_mode: false
'
    create_test_config "modules" "$modules_config"
    
    run load_modules_config
    assert_success
}

@test "get_enabled_modules returns list of enabled modules" {
    local modules_config='
modules:
  enabled:
    - shell
    - git
    - vim
'
    create_test_config "modules" "$modules_config"
    
    mock_command "yq" "echo -e 'shell\ngit\nvim'"
    
    run get_enabled_modules
    assert_success
    assert_output_contains "shell"
    assert_output_contains "git"
    assert_output_contains "vim"
}

@test "is_module_enabled checks if specific module is enabled" {
    local modules_config='
modules:
  enabled:
    - shell
    - git
  disabled:
    - vim
'
    create_test_config "modules" "$modules_config"
    
    mock_command "yq" "
        case \"\$2\" in
            *'shell'*) exit 0 ;;
            *'git'*) exit 0 ;;
            *'vim'*) exit 1 ;;
            *) exit 1 ;;
        esac
    "
    
    run is_module_enabled "shell"
    assert_success
    
    run is_module_enabled "git"
    assert_success
    
    run is_module_enabled "vim"
    assert_failure
}

@test "get_config_dir returns correct configuration directory" {
    run get_config_dir
    assert_success
    assert_output_contains "config"
}

@test "backup_config creates backup of configuration files" {
    local config_content='
user:
  name: "Test User"
'
    local config_file
    config_file=$(create_temp_file "$config_content" "test_config.yaml")
    
    run backup_config "$config_file"
    assert_success
    
    # Check backup was created
    assert_file_exist "${config_file}.backup"
}

@test "restore_config restores configuration from backup" {
    local original_content='user:\n  name: "Original User"'
    local modified_content='user:\n  name: "Modified User"'
    
    local config_file
    config_file=$(create_temp_file "$original_content" "test_config.yaml")
    
    # Create backup
    cp "$config_file" "${config_file}.backup"
    
    # Modify original
    echo -e "$modified_content" > "$config_file"
    
    run restore_config "$config_file"
    assert_success
    
    # Check original content was restored
    run cat "$config_file"
    assert_output_contains "Original User"
}