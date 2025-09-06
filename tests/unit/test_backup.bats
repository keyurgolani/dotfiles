#!/usr/bin/env bats

# Unit tests for backup and restore system

load '../helpers/test_helpers.bash'

setup() {
    setup_test_environment
    source_core_function "backup.sh"
}

teardown() {
    teardown_test_environment
}

@test "init_backup_system creates backup directory structure" {
    run init_backup_system
    assert_success
    
    assert_dir_exist "$DOTFILES_BACKUP_DIR"
    assert_dir_exist "$DOTFILES_BACKUP_DIR/active"
    assert_dir_exist "$DOTFILES_BACKUP_DIR/archive"
    assert_file_exist "$DOTFILES_BACKUP_DIR/backup_registry.json"
}

@test "generate_backup_id creates unique backup identifier" {
    run generate_backup_id
    assert_success
    assert_output_matches "backup_[0-9]{8}_[0-9]{6}_[a-zA-Z0-9]{6}"
}

@test "create_backup backs up existing dotfiles" {
    # Create some test dotfiles
    create_test_dotfiles ".bashrc" ".vimrc" ".gitconfig"
    
    run create_backup "test_backup"
    assert_success
    
    # Check backup was created
    assert_backup_created
}

@test "create_backup handles non-existent files gracefully" {
    # Try to backup files that don't exist
    run create_backup "empty_backup"
    assert_success
    
    # Should still create backup directory structure
    assert_backup_created
}

@test "create_backup creates manifest file" {
    create_test_dotfiles ".bashrc" ".vimrc"
    
    run create_backup "manifest_test"
    assert_success
    
    # Find the backup directory
    local backup_dir
    backup_dir=$(find "$DOTFILES_BACKUP_DIR" -name "backup_*" -type d | head -1)
    
    assert_file_exist "$backup_dir/$BACKUP_MANIFEST_FILE"
}

@test "create_backup stores metadata" {
    create_test_dotfiles ".bashrc"
    
    run create_backup "metadata_test"
    assert_success
    
    # Find the backup directory
    local backup_dir
    backup_dir=$(find "$DOTFILES_BACKUP_DIR" -name "backup_*" -type d | head -1)
    
    assert_file_exist "$backup_dir/$BACKUP_METADATA_FILE"
    
    # Check metadata contains expected information
    run cat "$backup_dir/$BACKUP_METADATA_FILE"
    assert_output_contains "timestamp"
    assert_output_contains "description"
}

@test "list_backups shows available backups" {
    # Create a few test backups
    create_test_dotfiles ".bashrc"
    create_backup "backup1"
    
    create_test_dotfiles ".vimrc"
    create_backup "backup2"
    
    run list_backups
    assert_success
    assert_output_contains "backup1"
    assert_output_contains "backup2"
}

@test "list_backups handles empty backup directory" {
    run list_backups
    assert_success
    assert_output_contains "No backups found"
}

@test "restore_backup restores files from backup" {
    # Create original files
    create_test_dotfiles ".bashrc" ".vimrc"
    echo "original content" > "$HOME/.bashrc"
    
    # Create backup
    local backup_id
    backup_id=$(create_backup "restore_test")
    
    # Modify original files
    echo "modified content" > "$HOME/.bashrc"
    
    # Restore from backup
    run restore_backup "$backup_id"
    assert_success
    
    # Check original content was restored
    run cat "$HOME/.bashrc"
    assert_output_contains "original content"
}

@test "restore_backup fails with invalid backup ID" {
    run restore_backup "invalid_backup_id"
    assert_failure
    assert_output_contains "Backup not found"
}

@test "get_backup_info returns backup metadata" {
    create_test_dotfiles ".bashrc"
    local backup_id
    backup_id=$(create_backup "info_test")
    
    run get_backup_info "$backup_id"
    assert_success
    assert_output_contains "info_test"
}

@test "delete_backup removes backup directory" {
    create_test_dotfiles ".bashrc"
    local backup_id
    backup_id=$(create_backup "delete_test")
    
    # Verify backup exists
    local backup_dir="$DOTFILES_BACKUP_DIR/active/$backup_id"
    assert_dir_exist "$backup_dir"
    
    run delete_backup "$backup_id"
    assert_success
    
    # Verify backup was deleted
    assert_dir_not_exist "$backup_dir"
}

@test "cleanup_old_backups removes backups older than retention period" {
    # Create old backup by manipulating timestamp
    create_test_dotfiles ".bashrc"
    local backup_id
    backup_id=$(create_backup "old_backup")
    
    # Make backup appear old by modifying its timestamp
    local backup_dir="$DOTFILES_BACKUP_DIR/active/$backup_id"
    touch -d "40 days ago" "$backup_dir"
    
    run cleanup_old_backups
    assert_success
    
    # Old backup should be moved to archive or deleted
    assert_dir_not_exist "$backup_dir"
}

@test "validate_backup_integrity checks backup completeness" {
    create_test_dotfiles ".bashrc" ".vimrc"
    local backup_id
    backup_id=$(create_backup "integrity_test")
    
    run validate_backup_integrity "$backup_id"
    assert_success
}

@test "validate_backup_integrity fails with corrupted backup" {
    create_test_dotfiles ".bashrc"
    local backup_id
    backup_id=$(create_backup "corrupt_test")
    
    # Corrupt the backup by removing a file
    local backup_dir="$DOTFILES_BACKUP_DIR/active/$backup_id"
    rm -f "$backup_dir/.bashrc"
    
    run validate_backup_integrity "$backup_id"
    assert_failure
}

@test "create_incremental_backup only backs up changed files" {
    # Create initial files
    create_test_dotfiles ".bashrc" ".vimrc"
    echo "initial content" > "$HOME/.bashrc"
    echo "vim config" > "$HOME/.vimrc"
    
    # Create first backup
    local backup1_id
    backup1_id=$(create_backup "incremental_base")
    
    # Modify only one file
    echo "modified content" > "$HOME/.bashrc"
    
    # Create incremental backup
    run create_incremental_backup "$backup1_id" "incremental_update"
    assert_success
    
    # Should only backup the changed file
    local backup2_dir
    backup2_dir=$(find "$DOTFILES_BACKUP_DIR" -name "backup_*" -newer "$DOTFILES_BACKUP_DIR/active/$backup1_id" -type d | head -1)
    
    assert_file_exist "$backup2_dir/.bashrc"
    # .vimrc should not be in incremental backup since it didn't change
}

@test "restore_selective_backup restores only specified files" {
    create_test_dotfiles ".bashrc" ".vimrc" ".gitconfig"
    echo "bash content" > "$HOME/.bashrc"
    echo "vim content" > "$HOME/.vimrc"
    echo "git content" > "$HOME/.gitconfig"
    
    local backup_id
    backup_id=$(create_backup "selective_test")
    
    # Modify all files
    echo "modified bash" > "$HOME/.bashrc"
    echo "modified vim" > "$HOME/.vimrc"
    echo "modified git" > "$HOME/.gitconfig"
    
    # Restore only .bashrc and .vimrc
    run restore_selective_backup "$backup_id" ".bashrc .vimrc"
    assert_success
    
    # Check that only selected files were restored
    run cat "$HOME/.bashrc"
    assert_output_contains "bash content"
    
    run cat "$HOME/.vimrc"
    assert_output_contains "vim content"
    
    # .gitconfig should still have modified content
    run cat "$HOME/.gitconfig"
    assert_output_contains "modified git"
}

@test "get_backup_size calculates backup directory size" {
    create_test_dotfiles ".bashrc" ".vimrc"
    local backup_id
    backup_id=$(create_backup "size_test")
    
    run get_backup_size "$backup_id"
    assert_success
    assert_output_matches "[0-9]+.*"
}

@test "compress_backup creates compressed archive" {
    create_test_dotfiles ".bashrc" ".vimrc"
    local backup_id
    backup_id=$(create_backup "compress_test")
    
    run compress_backup "$backup_id"
    assert_success
    
    # Check compressed file was created
    local backup_dir="$DOTFILES_BACKUP_DIR/active/$backup_id"
    assert_file_exist "${backup_dir}.tar.gz"
}

@test "extract_backup extracts compressed backup" {
    create_test_dotfiles ".bashrc"
    local backup_id
    backup_id=$(create_backup "extract_test")
    
    # Compress the backup
    compress_backup "$backup_id"
    
    # Remove original backup directory
    local backup_dir="$DOTFILES_BACKUP_DIR/active/$backup_id"
    rm -rf "$backup_dir"
    
    # Extract backup
    run extract_backup "$backup_id"
    assert_success
    
    # Check backup directory was recreated
    assert_dir_exist "$backup_dir"
    assert_file_exist "$backup_dir/.bashrc"
}

@test "backup_registry tracks all backups" {
    create_test_dotfiles ".bashrc"
    local backup_id
    backup_id=$(create_backup "registry_test")
    
    # Check backup was added to registry
    local registry_file="$DOTFILES_BACKUP_DIR/backup_registry.json"
    run cat "$registry_file"
    assert_output_contains "$backup_id"
    assert_output_contains "registry_test"
}

@test "verify_backup_checksum validates backup integrity" {
    create_test_dotfiles ".bashrc"
    echo "test content for checksum" > "$HOME/.bashrc"
    
    local backup_id
    backup_id=$(create_backup "checksum_test")
    
    run verify_backup_checksum "$backup_id"
    assert_success
}

@test "create_backup_with_exclusions skips specified files" {
    create_test_dotfiles ".bashrc" ".vimrc" ".DS_Store" ".tmp"
    
    # Create backup with exclusions
    run create_backup_with_exclusions "exclusion_test" ".DS_Store .tmp"
    assert_success
    
    # Check that excluded files are not in backup
    local backup_dir
    backup_dir=$(find "$DOTFILES_BACKUP_DIR" -name "backup_*" -type d | head -1)
    
    assert_file_exist "$backup_dir/.bashrc"
    assert_file_exist "$backup_dir/.vimrc"
    assert_file_not_exist "$backup_dir/.DS_Store"
    assert_file_not_exist "$backup_dir/.tmp"
}