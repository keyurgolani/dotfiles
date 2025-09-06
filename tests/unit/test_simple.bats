#!/usr/bin/env bats

# Simple test to verify testing framework is working

load '../helpers/test_helpers.bash'

@test "basic test framework functionality" {
    run echo "Hello, World!"
    assert_success
    assert_output "Hello, World!"
}

@test "test environment setup works" {
    setup_test_environment
    
    # Check that test temp directory was created
    [[ -n "$TEST_TEMP_DIR" ]]
    [[ -d "$TEST_TEMP_DIR" ]]
    
    teardown_test_environment
}

@test "mock command functionality works" {
    mock_command "test_cmd" "echo 'mocked output'"
    
    run test_cmd
    assert_success
    assert_output "mocked output"
    
    restore_command "test_cmd"
}

@test "file creation helpers work" {
    setup_test_environment
    
    create_test_dotfiles ".testrc"
    assert_file_exist "$HOME/.testrc"
    
    teardown_test_environment
}

@test "platform mocking works" {
    mock_platform "macos"
    [[ "$PLATFORM_OVERRIDE" == "macos" ]]
    
    mock_platform "ubuntu"
    [[ "$PLATFORM_OVERRIDE" == "ubuntu" ]]
}