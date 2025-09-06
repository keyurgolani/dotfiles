#!/bin/bash

# Unified Dotfiles Framework - Backup System
# Handles backup and restore functionality for dotfiles

# Backup system variables
BACKUP_BASE_DIR="${HOME}/.dotfiles/backups"
BACKUP_RETENTION_DAYS=30

# Initialize backup system
init_backup_system() {
    log_debug "Initializing backup system..."
    
    # Create backup directory
    if [[ ! -d "$BACKUP_BASE_DIR" ]]; then
        mkdir -p "$BACKUP_BASE_DIR"
    fi
    
    # Get retention setting from config
    BACKUP_RETENTION_DAYS=$(get_config_value "settings.backup_retention_days" "30")
    
    log_debug "Backup system initialized (retention: ${BACKUP_RETENTION_DAYS} days)"
    return 0
}

# Create backup of current dotfiles
create_backup() {
    local backup_name="${1:-auto-$(date +%Y%m%d_%H%M%S)}"
    local backup_dir="$BACKUP_BASE_DIR/$backup_name"
    
    log_info "Creating backup: $backup_name"
    
    # Create backup directory
    if [[ ! -d "$backup_dir" ]]; then
        mkdir -p "$backup_dir"
    fi
    
    # Create backup metadata
    cat > "$backup_dir/backup_info.txt" << EOF
Backup created: $(date)
Backup name: $backup_name
Platform: $DETECTED_OS
User: $USER
Home directory: $HOME
EOF
    
    # List of common dotfiles to backup
    local dotfiles=(
        ".bashrc"
        ".zshrc"
        ".bash_profile"
        ".zsh_profile"
        ".gitconfig"
        ".gitignore_global"
        ".vimrc"
        ".tmux.conf"
        ".ssh/config"
    )
    
    local backed_up_count=0
    
    # Backup existing dotfiles
    for dotfile in "${dotfiles[@]}"; do
        local source_file="$HOME/$dotfile"
        local target_file="$backup_dir/$dotfile"
        
        if [[ -f "$source_file" ]]; then
            # Create target directory if needed
            local target_dir
            target_dir="$(dirname "$target_file")"
            if [[ ! -d "$target_dir" ]]; then
                mkdir -p "$target_dir"
            fi
            
            # Copy file
            cp "$source_file" "$target_file"
            ((backed_up_count++))
            log_debug "Backed up: $dotfile"
        fi
    done
    
    # Backup .config directory if it exists
    if [[ -d "$HOME/.config" ]]; then
        cp -r "$HOME/.config" "$backup_dir/.config" 2>/dev/null || true
        log_debug "Backed up: .config directory"
    fi
    
    # Create backup summary
    echo "Files backed up: $backed_up_count" >> "$backup_dir/backup_info.txt"
    echo "Backup completed: $(date)" >> "$backup_dir/backup_info.txt"
    
    log_success "Backup created successfully: $backup_name ($backed_up_count files)"
    echo "$backup_name"
    return 0
}

# List available backups
list_backups() {
    if [[ ! -d "$BACKUP_BASE_DIR" ]]; then
        echo "No backups found (backup directory doesn't exist)"
        return 0
    fi
    
    local backup_count=0
    
    for backup_dir in "$BACKUP_BASE_DIR"/*; do
        if [[ -d "$backup_dir" ]]; then
            local backup_name
            backup_name="$(basename "$backup_dir")"
            
            local backup_info="$backup_dir/backup_info.txt"
            local backup_date="unknown"
            local file_count="unknown"
            
            if [[ -f "$backup_info" ]]; then
                backup_date=$(grep "Backup created:" "$backup_info" | cut -d: -f2- | sed 's/^ *//')
                file_count=$(grep "Files backed up:" "$backup_info" | cut -d: -f2 | sed 's/^ *//')
            fi
            
            echo "  📦 $backup_name"
            echo "     Date: $backup_date"
            echo "     Files: $file_count"
            echo ""
            
            ((backup_count++))
        fi
    done
    
    if [[ $backup_count -eq 0 ]]; then
        echo "No backups found"
        return 0
    fi
    
    echo "Total backups: $backup_count"
    return 0
}

# Restore from backup
restore_backup() {
    local backup_name="$1"
    local backup_dir="$BACKUP_BASE_DIR/$backup_name"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup not found: $backup_name"
        return 1
    fi
    
    log_info "Restoring from backup: $backup_name"
    
    # Create a backup of current state before restoring
    local pre_restore_backup
    pre_restore_backup="pre-restore-$(date +%Y%m%d_%H%M%S)"
    create_backup "$pre_restore_backup"
    
    local restored_count=0
    
    # Restore files from backup
    for backup_file in "$backup_dir"/*; do
        if [[ -f "$backup_file" ]]; then
            local filename
            filename="$(basename "$backup_file")"
            
            # Skip metadata files
            if [[ "$filename" == "backup_info.txt" ]]; then
                continue
            fi
            
            local target_file="$HOME/$filename"
            
            # Create target directory if needed
            local target_dir
            target_dir="$(dirname "$target_file")"
            if [[ ! -d "$target_dir" ]]; then
                mkdir -p "$target_dir"
            fi
            
            # Restore file
            cp "$backup_file" "$target_file"
            ((restored_count++))
            log_debug "Restored: $filename"
        fi
    done
    
    # Restore .config directory if it exists in backup
    if [[ -d "$backup_dir/.config" ]]; then
        cp -r "$backup_dir/.config" "$HOME/.config"
        log_debug "Restored: .config directory"
    fi
    
    log_success "Restore completed: $restored_count files restored"
    log_info "Pre-restore backup created: $pre_restore_backup"
    
    return 0
}

# Clean up old backups
cleanup_old_backups() {
    local dry_run="${1:-false}"
    
    if [[ ! -d "$BACKUP_BASE_DIR" ]]; then
        log_info "No backup directory found"
        return 0
    fi
    
    local cutoff_date
    cutoff_date=$(date -d "$BACKUP_RETENTION_DAYS days ago" +%s 2>/dev/null || date -v-"${BACKUP_RETENTION_DAYS}d" +%s 2>/dev/null)
    
    if [[ -z "$cutoff_date" ]]; then
        log_warn "Unable to calculate cutoff date for backup cleanup"
        return 1
    fi
    
    local cleaned_count=0
    
    for backup_dir in "$BACKUP_BASE_DIR"/*; do
        if [[ -d "$backup_dir" ]]; then
            local backup_mtime
            backup_mtime=$(get_file_mtime "$backup_dir")
            
            if [[ -n "$backup_mtime" && "$backup_mtime" -lt "$cutoff_date" ]]; then
                local backup_name
                backup_name="$(basename "$backup_dir")"
                
                if [[ "$dry_run" == "true" ]]; then
                    log_info "Would remove old backup: $backup_name"
                else
                    rm -rf "$backup_dir"
                    log_info "Removed old backup: $backup_name"
                fi
                
                ((cleaned_count++))
            fi
        fi
    done
    
    if [[ $cleaned_count -eq 0 ]]; then
        log_info "No old backups to clean up"
    else
        if [[ "$dry_run" == "true" ]]; then
            log_info "Would clean up $cleaned_count old backups"
        else
            log_success "Cleaned up $cleaned_count old backups"
        fi
    fi
    
    return 0
}

# Get backup information
get_backup_info() {
    local backup_name="$1"
    local backup_dir="$BACKUP_BASE_DIR/$backup_name"
    
    if [[ ! -d "$backup_dir" ]]; then
        echo "Backup not found: $backup_name"
        return 1
    fi
    
    local backup_info="$backup_dir/backup_info.txt"
    
    if [[ -f "$backup_info" ]]; then
        cat "$backup_info"
    else
        echo "Backup information not available for: $backup_name"
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_name="$1"
    local backup_dir="$BACKUP_BASE_DIR/$backup_name"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup not found: $backup_name"
        return 1
    fi
    
    log_info "Verifying backup: $backup_name"
    
    local file_count=0
    local error_count=0
    
    # Check each file in backup
    for backup_file in "$backup_dir"/*; do
        if [[ -f "$backup_file" ]]; then
            ((file_count++))
            
            # Basic file integrity check
            if [[ ! -r "$backup_file" ]]; then
                log_warn "Cannot read backup file: $(basename "$backup_file")"
                ((error_count++))
            fi
        fi
    done
    
    if [[ $error_count -eq 0 ]]; then
        log_success "Backup verification passed: $file_count files OK"
        return 0
    else
        log_error "Backup verification failed: $error_count errors found"
        return 1
    fi
}