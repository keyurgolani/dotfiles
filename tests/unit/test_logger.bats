#!/usr/bin/env bats

# Unit tests for logging system

load '../helpers/test_helpers.bash'

setup() {
    setup_test_environment
    source_core_function "logger.sh"
    
    # Set up test log file
    export DOTFILES_LOG_FILE="$TEST_TEMP_DIR/test.log"
    export DOTFILES_LOG_LEVEL="DEBUG"
}

teardown() {
    teardown_test_environment
}

@test "log_debug writes debug messages when debug level enabled" {
    export DOTFILES_LOG_LEVEL="DEBUG"
    
    run log_debug "This is a debug message"
    assert_success
    
    # Check message was written to log file
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "DEBUG"
        assert_file_contains "$DOTFILES_LOG_FILE" "This is a debug message"
    fi
}

@test "log_debug is silent when debug level disabled" {
    export DOTFILES_LOG_LEVEL="INFO"
    
    run log_debug "This debug message should not appear"
    assert_success
    
    # Debug message should not appear in output
    [[ "$output" != *"This debug message should not appear"* ]]
}

@test "log_info writes info messages" {
    run log_info "This is an info message"
    assert_success
    assert_output_contains "This is an info message"
    
    # Check message was written to log file
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "INFO"
        assert_file_contains "$DOTFILES_LOG_FILE" "This is an info message"
    fi
}

@test "log_warn writes warning messages" {
    run log_warn "This is a warning message"
    assert_success
    assert_output_contains "This is a warning message"
    
    # Check message was written to log file
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "WARN"
        assert_file_contains "$DOTFILES_LOG_FILE" "This is a warning message"
    fi
}

@test "log_error writes error messages" {
    run log_error "This is an error message"
    assert_success
    assert_output_contains "This is an error message"
    
    # Check message was written to log file
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "ERROR"
        assert_file_contains "$DOTFILES_LOG_FILE" "This is an error message"
    fi
}

@test "log_success writes success messages" {
    run log_success "This is a success message"
    assert_success
    assert_output_contains "This is a success message"
    
    # Check message was written to log file
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "SUCCESS"
        assert_file_contains "$DOTFILES_LOG_FILE" "This is a success message"
    fi
}

@test "log messages include timestamp" {
    run log_info "Test message with timestamp"
    assert_success
    
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        # Check that log entry includes timestamp pattern
        run grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}" "$DOTFILES_LOG_FILE"
        assert_success
    fi
}

@test "log messages include log level" {
    run log_info "Test message"
    assert_success
    
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "[INFO]"
    fi
    
    run log_error "Error message"
    assert_success
    
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "[ERROR]"
    fi
}

@test "log_level_enabled checks if log level is enabled" {
    export DOTFILES_LOG_LEVEL="INFO"
    
    run log_level_enabled "DEBUG"
    assert_failure
    
    run log_level_enabled "INFO"
    assert_success
    
    run log_level_enabled "WARN"
    assert_success
    
    run log_level_enabled "ERROR"
    assert_success
}

@test "log_level_enabled handles invalid log levels" {
    run log_level_enabled "INVALID"
    assert_failure
    
    run log_level_enabled ""
    assert_failure
}

@test "init_logging creates log file and directory" {
    local test_log_dir="$TEST_TEMP_DIR/logs"
    local test_log_file="$test_log_dir/dotfiles.log"
    
    export DOTFILES_LOG_FILE="$test_log_file"
    
    run init_logging
    assert_success
    
    assert_dir_exist "$test_log_dir"
    assert_file_exist "$test_log_file"
}

@test "init_logging handles existing log file" {
    # Create existing log file
    echo "Existing log content" > "$DOTFILES_LOG_FILE"
    
    run init_logging
    assert_success
    
    # Should preserve existing content
    assert_file_contains "$DOTFILES_LOG_FILE" "Existing log content"
}

@test "rotate_log_file rotates large log files" {
    # Create a large log file
    for i in {1..1000}; do
        echo "Log line $i" >> "$DOTFILES_LOG_FILE"
    done
    
    run rotate_log_file
    assert_success
    
    # Check that rotated file was created
    assert_file_exist "${DOTFILES_LOG_FILE}.1"
    
    # Check that current log file is smaller
    local current_size rotated_size
    current_size=$(wc -l < "$DOTFILES_LOG_FILE")
    rotated_size=$(wc -l < "${DOTFILES_LOG_FILE}.1")
    
    [[ $current_size -lt $rotated_size ]]
}

@test "cleanup_old_logs removes old log files" {
    # Create old log files
    touch "${DOTFILES_LOG_FILE}.1"
    touch "${DOTFILES_LOG_FILE}.2"
    touch "${DOTFILES_LOG_FILE}.3"
    
    # Make them appear old
    touch -d "10 days ago" "${DOTFILES_LOG_FILE}.2"
    touch -d "20 days ago" "${DOTFILES_LOG_FILE}.3"
    
    run cleanup_old_logs 7
    assert_success
    
    # Recent log should still exist
    assert_file_exist "${DOTFILES_LOG_FILE}.1"
    
    # Old logs should be removed
    assert_file_not_exist "${DOTFILES_LOG_FILE}.2"
    assert_file_not_exist "${DOTFILES_LOG_FILE}.3"
}

@test "log_command logs command execution" {
    run log_command "echo 'test command'"
    assert_success
    
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "Executing command"
        assert_file_contains "$DOTFILES_LOG_FILE" "echo 'test command'"
    fi
}

@test "log_command captures command output" {
    run log_command "echo 'command output'"
    assert_success
    assert_output_contains "command output"
    
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "command output"
    fi
}

@test "log_command handles command failures" {
    run log_command "false"
    assert_failure
    
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "Command failed"
    fi
}

@test "log_progress shows progress indicators" {
    run log_progress "Installing packages" 50
    assert_success
    assert_output_contains "Installing packages"
    assert_output_contains "50%"
}

@test "log_progress handles invalid percentages" {
    run log_progress "Test" 150
    assert_success
    assert_output_contains "100%"
    
    run log_progress "Test" -10
    assert_success
    assert_output_contains "0%"
}

@test "log_section creates section headers" {
    run log_section "Test Section"
    assert_success
    assert_output_contains "Test Section"
    
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "Test Section"
    fi
}

@test "log_step logs installation steps" {
    run log_step "Step 1" "Installing dependencies"
    assert_success
    assert_output_contains "Step 1"
    assert_output_contains "Installing dependencies"
}

@test "log_result logs operation results" {
    run log_result "success" "Operation completed successfully"
    assert_success
    assert_output_contains "Operation completed successfully"
    
    run log_result "failure" "Operation failed"
    assert_success
    assert_output_contains "Operation failed"
}

@test "log_summary creates summary reports" {
    run log_summary "Installation Summary" "Modules installed: 5" "Time taken: 2m 30s"
    assert_success
    assert_output_contains "Installation Summary"
    assert_output_contains "Modules installed: 5"
    assert_output_contains "Time taken: 2m 30s"
}

@test "set_log_level changes current log level" {
    run set_log_level "ERROR"
    assert_success
    
    # Debug messages should not appear
    run log_debug "This should not appear"
    [[ "$output" != *"This should not appear"* ]]
    
    # Error messages should appear
    run log_error "This should appear"
    assert_output_contains "This should appear"
}

@test "get_log_level returns current log level" {
    export DOTFILES_LOG_LEVEL="WARN"
    
    run get_log_level
    assert_success
    assert_output "WARN"
}

@test "log_to_file writes only to file without console output" {
    run log_to_file "INFO" "File-only message"
    assert_success
    
    # Should not appear in console output
    [[ "$output" != *"File-only message"* ]]
    
    # Should appear in log file
    if [[ -f "$DOTFILES_LOG_FILE" ]]; then
        assert_file_contains "$DOTFILES_LOG_FILE" "File-only message"
    fi
}

@test "log_with_color uses colors when terminal supports it" {
    # Mock tput to simulate color support
    mock_command "tput" "
        case \"\$1\" in
            colors) echo '256' ;;
            setaf) echo -n '\033[3${2}m' ;;
            sgr0) echo -n '\033[0m' ;;
            *) echo '' ;;
        esac
    "
    
    run log_with_color "red" "Red message"
    assert_success
    # Output should contain ANSI color codes
    [[ "$output" == *$'\033['* ]]
}

@test "log_with_color falls back when no color support" {
    # Mock tput to simulate no color support
    mock_command "tput" "echo '0'"
    
    run log_with_color "red" "Plain message"
    assert_success
    assert_output "Plain message"
    # Output should not contain ANSI color codes
    [[ "$output" != *$'\033['* ]]
}