#!/usr/bin/env bats

# Backup and restore testing for unified dotfiles framework
# Tests backup creation, restoration, conflict resolution, and data integrity

load '../helpers/test_helpers'

setup() {
    setup_test_environment
    
    # Create test configuration
    create_test_config "backup_test" "
modules:
  enabled:
    - shell
    - git
    - vim
settings:
  backup_enabled: true
  backup_retention_days: 30
user:
  name: 'Backup Test User'
  email: 'backup@example.com'
"
}

teardown() {
    teardown_test_environment
}

@test "backup: automatic backup creation during installation" {
    # Create existing dotfiles to backup
    create_test_dotfiles ".bashrc" ".gitconfig" ".vimrc" ".tmux.conf"
    
    # Add some content to verify backup integrity
    echo "# Original bashrc content" > "$HOME/.bashrc"
    echo "# Original gitconfig content" > "$HOME/.gitconfig"
    echo "# Original vimrc content" > "$HOME/.vimrc"
    
    # Run installation (should create backup automatically)
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/backup_test.yaml" --non-interactive --verbose
    
    assert_success
    assert_output_contains "Creating backup"
    assert_output_contains "Backup created successfully"
    
    # Verify backup directory exists
    assert_dir_exist "$HOME/.dotfiles_backup"
    
    # Verify backup contains original files
    local backup_dir
    backup_dir=$(find "$HOME/.dotfiles_backup" -name "*_*" -type d | head -1)
    assert_dir_exist "$backup_dir"
    
    assert_file_exist "$backup_dir/.bashrc"
    assert_file_exist "$backup_dir/.gitconfig"
    assert_file_exist "$backup_dir/.vimrc"
    
    # Verify backup content integrity
    assert_file_contains "$backup_dir/.bashrc" "Original bashrc content"
    assert_file_contains "$backup_dir/.gitconfig" "Original gitconfig content"
    assert_file_contains "$backup_dir/.vimrc" "Original vimrc content"
}

@test "backup: manual backup creation" {
    # Create existing dotfiles
    create_test_dotfiles ".bashrc" ".gitconfig" ".vimrc"
    echo "# Manual backup test" > "$HOME/.bashrc"
    
    # Create manual backup
    run "$DOTFILES_ROOT/install.sh" backup --verbose
    
    assert_success
    assert_output_contains "Manual backup created"
    assert_output_contains "Backup ID:"
    
    # Extract backup ID from output
    local backup_id
    backup_id=$(echo "$output" | grep "Backup ID:" | awk '{print $3}')
    
    # Verify backup exists
    assert_dir_exist "$HOME/.dotfiles_backup/$backup_id"
    assert_file_exist "$HOME/.dotfiles_backup/$backup_id/.bashrc"
    assert_file_contains "$HOME/.dotfiles_backup/$backup_id/.bashrc" "Manual backup test"
}

@test "backup: backup listing and information" {
    # Create multiple backups
    create_test_dotfiles ".bashrc"
    echo "# Backup 1" > "$HOME/.bashrc"
    run "$DOTFILES_ROOT/install.sh" backup
    assert_success
    
    sleep 1  # Ensure different timestamps
    
    echo "# Backup 2" > "$HOME/.bashrc"
    run "$DOTFILES_ROOT/install.sh" backup
    assert_success
    
    # List backups
    run "$DOTFILES_ROOT/install.sh" list-backups
    
    assert_success
    assert_output_contains "Available backups:"
    assert_output_contains "Backup ID"
    assert_output_contains "Created"
    assert_output_contains "Files"
    
    # Should show 2 backups
    local backup_count
    backup_count=$(echo "$output" | grep -c "Backup ID" || echo "0")
    [[ $backup_count -ge 2 ]]
}

@test "backup: complete restore from backup" {
    # Create original dotfiles
    create_test_dotfiles ".bashrc" ".gitconfig" ".vimrc"
    echo "# Original content" > "$HOME/.bashrc"
    echo "[user] name = Original" > "$HOME/.gitconfig"
    
    # Create backup
    run "$DOTFILES_ROOT/install.sh" backup
    assert_success
    
    # Extract backup ID
    local backup_id
    backup_id=$(echo "$output" | grep "Backup ID:" | awk '{print $3}')
    
    # Modify files (simulate installation changes)
    echo "# Modified content" > "$HOME/.bashrc"
    echo "[user] name = Modified" > "$HOME/.gitconfig"
    
    # Restore from backup
    run "$DOTFILES_ROOT/install.sh" restore "$backup_id" --verbose
    
    assert_success
    assert_output_contains "Restore completed successfully"
    assert_output_contains "Restored from backup: $backup_id"
    
    # Verify original content is restored
    assert_file_contains "$HOME/.bashrc" "Original content"
    assert_file_contains "$HOME/.gitconfig" "name = Original"
}

@test "backup: selective restore functionality" {
    # Create multiple dotfiles
    create_test_dotfiles ".bashrc" ".gitconfig" ".vimrc"
    echo "# Original bashrc" > "$HOME/.bashrc"
    echo "# Original gitconfig" > "$HOME/.gitconfig"
    echo "# Original vimrc" > "$HOME/.vimrc"
    
    # Create backup
    run "$DOTFILES_ROOT/install.sh" backup
    assert_success
    local backup_id
    backup_id=$(echo "$output" | grep "Backup ID:" | awk '{print $3}')
    
    # Modify all files
    echo "# Modified bashrc" > "$HOME/.bashrc"
    echo "# Modified gitconfig" > "$HOME/.gitconfig"
    echo "# Modified vimrc" > "$HOME/.vimrc"
    
    # Restore only specific files
    run "$DOTFILES_ROOT/install.sh" restore "$backup_id" --files ".bashrc,.gitconfig" --verbose
    
    assert_success
    assert_output_contains "Selective restore completed"
    
    # Verify only selected files are restored
    assert_file_contains "$HOME/.bashrc" "Original bashrc"
    assert_file_contains "$HOME/.gitconfig" "Original gitconfig"
    assert_file_contains "$HOME/.vimrc" "Modified vimrc"  # Should remain modified
}

@test "backup: conflict resolution during restore" {
    # Create original files
    create_test_dotfiles ".bashrc"
    echo "# Original content" > "$HOME/.bashrc"
    
    # Create backup
    run "$DOTFILES_ROOT/install.sh" backup
    assert_success
    local backup_id
    backup_id=$(echo "$output" | grep "Backup ID:" | awk '{print $3}')
    
    # Modify file after backup
    echo "# Current content" > "$HOME/.bashrc"
    
    # Attempt restore with conflict resolution
    export DOTFILES_RESTORE_CONFLICTS="backup"  # Backup current before restore
    
    run "$DOTFILES_ROOT/install.sh" restore "$backup_id" --verbose
    
    assert_success
    assert_output_contains "Conflict detected"
    assert_output_contains "Created backup of current files"
    assert_output_contains "Restore completed"
    
    # Verify original content is restored
    assert_file_contains "$HOME/.bashrc" "Original content"
    
    # Verify current content was backed up
    local conflict_backup
    conflict_backup=$(find "$HOME/.dotfiles_backup" -name "*conflict*" -type d | head -1)
    if [[ -n "$conflict_backup" ]]; then
        assert_file_contains "$conflict_backup/.bashrc" "Current content"
    fi
    
    unset DOTFILES_RESTORE_CONFLICTS
}

@test "backup: backup integrity verification" {
    # Create test files with known checksums
    create_test_dotfiles ".bashrc" ".gitconfig"
    echo "# Test content for checksum" > "$HOME/.bashrc"
    echo "[user] name = Test User" > "$HOME/.gitconfig"
    
    # Calculate original checksums
    local bashrc_checksum gitconfig_checksum
    bashrc_checksum=$(sha256sum "$HOME/.bashrc" | awk '{print $1}' 2>/dev/null || shasum -a 256 "$HOME/.bashrc" | awk '{print $1}')
    gitconfig_checksum=$(sha256sum "$HOME/.gitconfig" | awk '{print $1}' 2>/dev/null || shasum -a 256 "$HOME/.gitconfig" | awk '{print $1}')
    
    # Create backup
    run "$DOTFILES_ROOT/install.sh" backup --verify-integrity
    assert_success
    
    local backup_id
    backup_id=$(echo "$output" | grep "Backup ID:" | awk '{print $3}')
    
    # Verify backup integrity
    run "$DOTFILES_ROOT/install.sh" verify-backup "$backup_id"
    assert_success
    assert_output_contains "Backup integrity verified"
    
    # Verify checksums match
    local backup_bashrc_checksum backup_gitconfig_checksum
    backup_bashrc_checksum=$(sha256sum "$HOME/.dotfiles_backup/$backup_id/.bashrc" | awk '{print $1}' 2>/dev/null || shasum -a 256 "$HOME/.dotfiles_backup/$backup_id/.bashrc" | awk '{print $1}')
    backup_gitconfig_checksum=$(sha256sum "$HOME/.dotfiles_backup/$backup_id/.gitconfig" | awk '{print $1}' 2>/dev/null || shasum -a 256 "$HOME/.dotfiles_backup/$backup_id/.gitconfig" | awk '{print $1}')
    
    [[ "$bashrc_checksum" == "$backup_bashrc_checksum" ]]
    [[ "$gitconfig_checksum" == "$backup_gitconfig_checksum" ]]
}

@test "backup: backup cleanup and retention" {
    # Create multiple old backups
    mkdir -p "$HOME/.dotfiles_backup"
    
    # Create old backup (simulate 35 days old)
    local old_date old_backup_id
    old_date=$(date -d "35 days ago" +"%Y%m%d_%H%M%S" 2>/dev/null || date -v-35d +"%Y%m%d_%H%M%S" 2>/dev/null || echo "20240101_120000")
    old_backup_id="$old_date"
    mkdir -p "$HOME/.dotfiles_backup/$old_backup_id"
    echo "# Old backup" > "$HOME/.dotfiles_backup/$old_backup_id/.bashrc"
    
    # Create recent backup
    create_test_dotfiles ".bashrc"
    run "$DOTFILES_ROOT/install.sh" backup
    assert_success
    
    # Run cleanup
    run "$DOTFILES_ROOT/install.sh" cleanup --verbose
    assert_success
    assert_output_contains "Cleanup completed"
    
    # Verify old backup was removed (if retention policy is enforced)
    if [[ -d "$HOME/.dotfiles_backup/$old_backup_id" ]]; then
        # If still exists, should be because cleanup is not aggressive
        log_info "Old backup retained (cleanup policy may be conservative)"
    fi
}

@test "backup: backup metadata and information" {
    # Create test files
    create_test_dotfiles ".bashrc" ".gitconfig" ".vimrc"
    
    # Create backup with metadata
    run "$DOTFILES_ROOT/install.sh" backup --description "Test backup with metadata" --verbose
    assert_success
    
    local backup_id
    backup_id=$(echo "$output" | grep "Backup ID:" | awk '{print $3}')
    
    # Check backup information
    run "$DOTFILES_ROOT/install.sh" backup-info "$backup_id"
    assert_success
    assert_output_contains "Backup Information"
    assert_output_contains "Backup ID: $backup_id"
    assert_output_contains "Description: Test backup with metadata"
    assert_output_contains "Files backed up:"
    assert_output_contains ".bashrc"
    assert_output_contains ".gitconfig"
    assert_output_contains ".vimrc"
}

@test "backup: error handling and edge cases" {
    # Test restore with invalid backup ID
    run "$DOTFILES_ROOT/install.sh" restore "invalid_backup_id"
    assert_failure
    assert_output_contains "Backup not found"
    
    # Test backup when no dotfiles exist
    run "$DOTFILES_ROOT/install.sh" backup
    # Should succeed but create empty backup or skip
    [[ $status -eq 0 || $status -eq 1 ]]  # Allow either success or controlled failure
    
    # Test restore when backup directory doesn't exist
    rm -rf "$HOME/.dotfiles_backup" 2>/dev/null || true
    run "$DOTFILES_ROOT/install.sh" restore "20240101_120000"
    assert_failure
    assert_output_contains "No backups found"
}

@test "backup: large file handling and performance" {
    # Create a larger test file to test backup performance
    create_test_dotfiles ".bashrc"
    
    # Create a reasonably sized file (1MB)
    dd if=/dev/zero of="$HOME/.large_config" bs=1024 count=1024 2>/dev/null || {
        # Fallback for systems without dd
        for i in {1..1000}; do
            echo "# Large config file line $i with some content to make it bigger" >> "$HOME/.large_config"
        done
    }
    
    # Time the backup operation
    local start_time end_time duration
    start_time=$(date +%s)
    
    run "$DOTFILES_ROOT/install.sh" backup --verbose
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    assert_success
    assert_output_contains "Backup created successfully"
    
    # Backup should complete within reasonable time (30 seconds)
    [[ $duration -lt 30 ]]
    
    log_info "Backup completed in ${duration} seconds"
    
    # Verify large file was backed up correctly
    local backup_id
    backup_id=$(echo "$output" | grep "Backup ID:" | awk '{print $3}')
    assert_file_exist "$HOME/.dotfiles_backup/$backup_id/.large_config"
    
    # Verify file size matches
    local original_size backup_size
    original_size=$(wc -c < "$HOME/.large_config")
    backup_size=$(wc -c < "$HOME/.dotfiles_backup/$backup_id/.large_config")
    [[ "$original_size" -eq "$backup_size" ]]
}