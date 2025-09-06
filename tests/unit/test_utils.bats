#!/usr/bin/env bats

# Unit tests for utility functions

load '../helpers/test_helpers.bash'

setup() {
    setup_test_environment
    source_core_function "utils.sh"
}

teardown() {
    teardown_test_environment
}

@test "command_exists returns true for existing commands" {
    run command_exists "echo"
    assert_success
    
    run command_exists "ls"
    assert_success
    
    run command_exists "bash"
    assert_success
}

@test "command_exists returns false for non-existing commands" {
    run command_exists "nonexistent_command_12345"
    assert_failure
    
    run command_exists "fake_utility"
    assert_failure
}

@test "ensure_dir creates directory with correct permissions" {
    local test_dir="$TEST_TEMP_DIR/test_directory"
    
    run ensure_dir "$test_dir" 755
    assert_success
    assert_dir_exist "$test_dir"
    
    # Check permissions (on systems that support it)
    if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
        local perms
        perms=$(stat -c "%a" "$test_dir" 2>/dev/null || stat -f "%A" "$test_dir" 2>/dev/null || echo "755")
        [[ "$perms" == "755" ]]
    fi
}

@test "ensure_dir handles existing directories" {
    local test_dir="$TEST_TEMP_DIR/existing_directory"
    mkdir -p "$test_dir"
    
    run ensure_dir "$test_dir" 755
    assert_success
    assert_dir_exist "$test_dir"
}

@test "random_string generates string of correct length" {
    run random_string 8
    assert_success
    [[ ${#output} -eq 8 ]]
    
    run random_string 16
    assert_success
    [[ ${#output} -eq 16 ]]
}

@test "random_string generates different strings" {
    local string1 string2
    string1=$(random_string 10)
    string2=$(random_string 10)
    
    [[ "$string1" != "$string2" ]]
}

@test "is_numeric returns true for numbers" {
    run is_numeric "123"
    assert_success
    
    run is_numeric "0"
    assert_success
    
    run is_numeric "999"
    assert_success
}

@test "is_numeric returns false for non-numbers" {
    run is_numeric "abc"
    assert_failure
    
    run is_numeric "12a"
    assert_failure
    
    run is_numeric ""
    assert_failure
}

@test "trim_whitespace removes leading and trailing spaces" {
    run trim_whitespace "  hello world  "
    assert_success
    assert_output "hello world"
    
    run trim_whitespace "	test	"
    assert_success
    assert_output "test"
}

@test "trim_whitespace handles empty strings" {
    run trim_whitespace ""
    assert_success
    assert_output ""
    
    run trim_whitespace "   "
    assert_success
    assert_output ""
}

@test "join_array joins array elements with delimiter" {
    local arr=("one" "two" "three")
    
    run join_array "," "${arr[@]}"
    assert_success
    assert_output "one,two,three"
    
    run join_array " | " "${arr[@]}"
    assert_success
    assert_output "one | two | three"
}

@test "join_array handles single element" {
    local arr=("single")
    
    run join_array "," "${arr[@]}"
    assert_success
    assert_output "single"
}

@test "join_array handles empty array" {
    local arr=()
    
    run join_array "," "${arr[@]}"
    assert_success
    assert_output ""
}

@test "url_encode encodes special characters" {
    run url_encode "hello world"
    assert_success
    assert_output "hello%20world"
    
    run url_encode "test@example.com"
    assert_success
    assert_output "test%40example.com"
}

@test "url_decode decodes encoded characters" {
    run url_decode "hello%20world"
    assert_success
    assert_output "hello world"
    
    run url_decode "test%40example.com"
    assert_success
    assert_output "test@example.com"
}

@test "get_file_extension returns correct extension" {
    run get_file_extension "test.txt"
    assert_success
    assert_output "txt"
    
    run get_file_extension "archive.tar.gz"
    assert_success
    assert_output "gz"
    
    run get_file_extension "no_extension"
    assert_success
    assert_output ""
}

@test "get_filename_without_extension removes extension" {
    run get_filename_without_extension "test.txt"
    assert_success
    assert_output "test"
    
    run get_filename_without_extension "path/to/file.conf"
    assert_success
    assert_output "path/to/file"
}

@test "is_absolute_path detects absolute paths" {
    run is_absolute_path "/absolute/path"
    assert_success
    
    run is_absolute_path "~/home/path"
    assert_success
    
    run is_absolute_path "relative/path"
    assert_failure
    
    run is_absolute_path "./relative"
    assert_failure
}

@test "resolve_path resolves relative paths" {
    local current_dir
    current_dir=$(pwd)
    
    run resolve_path "."
    assert_success
    assert_output "$current_dir"
    
    run resolve_path "./test"
    assert_success
    assert_output "$current_dir/test"
}

@test "safe_rm removes files safely" {
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    echo "test content" > "$test_file"
    
    run safe_rm "$test_file"
    assert_success
    assert_file_not_exist "$test_file"
}

@test "safe_rm fails on dangerous paths" {
    run safe_rm "/"
    assert_failure
    
    run safe_rm "/usr"
    assert_failure
    
    run safe_rm "/home"
    assert_failure
}

@test "backup_file creates backup with timestamp" {
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    echo "original content" > "$test_file"
    
    run backup_file "$test_file"
    assert_success
    
    # Check backup was created
    local backup_file="${test_file}.backup"
    assert_file_exist "$backup_file"
    
    # Check backup has same content
    run cat "$backup_file"
    assert_output "original content"
}

@test "restore_file restores from backup" {
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    local backup_file="${test_file}.backup"
    
    echo "original content" > "$test_file"
    cp "$test_file" "$backup_file"
    echo "modified content" > "$test_file"
    
    run restore_file "$test_file"
    assert_success
    
    # Check original content was restored
    run cat "$test_file"
    assert_output "original content"
}

@test "calculate_checksum generates consistent checksums" {
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    echo "test content for checksum" > "$test_file"
    
    local checksum1 checksum2
    checksum1=$(calculate_checksum "$test_file")
    checksum2=$(calculate_checksum "$test_file")
    
    [[ "$checksum1" == "$checksum2" ]]
    [[ -n "$checksum1" ]]
}

@test "verify_checksum validates file integrity" {
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    echo "test content" > "$test_file"
    
    local checksum
    checksum=$(calculate_checksum "$test_file")
    
    run verify_checksum "$test_file" "$checksum"
    assert_success
    
    # Modify file and verify checksum fails
    echo "modified content" > "$test_file"
    run verify_checksum "$test_file" "$checksum"
    assert_failure
}

@test "download_file downloads files with curl" {
    skip_if_missing "curl"
    
    # Mock curl command
    mock_command "curl" "echo 'downloaded content' > \"\$4\""
    
    local output_file="$TEST_TEMP_DIR/downloaded_file.txt"
    
    run download_file "https://example.com/file.txt" "$output_file"
    assert_success
    assert_file_exist "$output_file"
    assert_file_contains "$output_file" "downloaded content"
}

@test "download_file falls back to wget" {
    skip_if_missing "wget"
    
    # Mock wget command (don't mock curl to test fallback)
    mock_command "wget" "echo 'downloaded with wget' > \"\$2\""
    
    local output_file="$TEST_TEMP_DIR/downloaded_file.txt"
    
    run download_file "https://example.com/file.txt" "$output_file"
    assert_success
    assert_file_exist "$output_file"
    assert_file_contains "$output_file" "downloaded with wget"
}

@test "retry_command retries failed commands" {
    local attempt_count=0
    
    # Create a command that fails twice then succeeds
    mock_command "flaky_command" "
        attempt_file=\"$TEST_TEMP_DIR/attempt_count\"
        if [[ -f \"\$attempt_file\" ]]; then
            count=\$(cat \"\$attempt_file\")
        else
            count=0
        fi
        count=\$((count + 1))
        echo \$count > \"\$attempt_file\"
        
        if [[ \$count -lt 3 ]]; then
            echo \"Attempt \$count failed\"
            exit 1
        else
            echo \"Attempt \$count succeeded\"
            exit 0
        fi
    "
    
    run retry_command 3 1 flaky_command
    assert_success
    assert_output_contains "succeeded"
}

@test "retry_command fails after max attempts" {
    # Create a command that always fails
    mock_command "always_fails" "echo 'Failed'; exit 1"
    
    run retry_command 2 1 always_fails
    assert_failure
}

@test "wait_for_condition waits for condition to be true" {
    # Create a condition that becomes true after some time
    local marker_file="$TEST_TEMP_DIR/condition_marker"
    
    # Start background process that creates marker after delay
    (sleep 2 && touch "$marker_file") &
    
    run wait_for_condition "test -f '$marker_file'" 5 1
    assert_success
    
    assert_file_exist "$marker_file"
}

@test "wait_for_condition times out when condition never becomes true" {
    run wait_for_condition "test -f '/nonexistent/file'" 2 1
    assert_failure
}

@test "get_user_input handles non-interactive mode" {
    export DOTFILES_INTERACTIVE=false
    
    run get_user_input "Test prompt" "default_value"
    assert_success
    assert_output "default_value"
}

@test "validate_email accepts valid email addresses" {
    run validate_email "test@example.com"
    assert_success
    
    run validate_email "user.name+tag@domain.co.uk"
    assert_success
}

@test "validate_email rejects invalid email addresses" {
    run validate_email "invalid-email"
    assert_failure
    
    run validate_email "@example.com"
    assert_failure
    
    run validate_email "test@"
    assert_failure
}

@test "validate_url accepts valid URLs" {
    run validate_url "https://example.com"
    assert_success
    
    run validate_url "http://subdomain.example.org/path"
    assert_success
    
    run validate_url "ftp://files.example.com"
    assert_success
}

@test "validate_url rejects invalid URLs" {
    run validate_url "not-a-url"
    assert_failure
    
    run validate_url "://example.com"
    assert_failure
    
    run validate_url "https://"
    assert_failure
}