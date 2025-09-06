# Error Handling System

The Unified Dotfiles Framework includes a comprehensive error handling system that provides structured error management, retry mechanisms, graceful recovery, and detailed error reporting.

## Overview

The error handling system consists of several components:

- **Error Handler Core** (`core/error_handler.sh`): Main error handling logic
- **Error Codes**: Standardized exit codes for different error types
- **Retry Mechanisms**: Enhanced retry with exponential backoff and jitter
- **Error Recovery**: Automatic and interactive error recovery
- **Cleanup System**: Automatic cleanup of temporary resources
- **Error Reporting**: Detailed error reports for debugging

## Features

### Structured Error Handling

- **Error Context Tracking**: Track the current operation, file, and context
- **Error Stack**: Maintain a stack of operations for better error tracing
- **Standardized Exit Codes**: Use consistent exit codes across the framework
- **Stack Trace Logging**: Detailed stack traces for debugging

### Retry Mechanisms

- **Exponential Backoff**: Intelligent retry delays that increase over time
- **Jitter**: Random variation in retry delays to prevent thundering herd
- **Selective Retry**: Only retry errors that make sense to retry
- **Configurable Limits**: Customizable retry attempts and delays

### Error Recovery

- **Automatic Recovery**: Attempt to recover from common errors automatically
- **Interactive Recovery**: Prompt users for recovery actions when appropriate
- **Network Recovery**: Special handling for network-related errors
- **Permission Recovery**: Handle permission errors with sudo prompts

### Cleanup System

- **Automatic Cleanup**: Clean up temporary files and directories on error
- **Registered Cleanup**: Register custom cleanup functions
- **Exit Cleanup**: Perform cleanup on normal exit as well
- **Resource Tracking**: Track temporary resources for cleanup

## Usage

### Basic Setup

```bash
#!/bin/bash

# Source the error handling system
source "core/logger.sh"
source "core/error_handler.sh"
source "core/utils.sh"

# Initialize error handling
init_error_handling

# Your script code here...
```

### Setting Error Context

```bash
# Set context for better error reporting
set_error_context "module_installation" "install_git_module" "/path/to/gitconfig"

# Push operations onto the error stack
push_error_stack "downloading_git_config"

# Your operation here...

# Pop when operation completes
pop_error_stack
```

### Using Enhanced Retry

```bash
# Retry with enhanced backoff
retry_with_enhanced_backoff 5 2 60 2 true command_to_retry arg1 arg2

# Parameters:
# - max_attempts: Maximum number of retry attempts (default: 3)
# - initial_delay: Initial delay in seconds (default: 1)
# - max_delay: Maximum delay in seconds (default: 60)
# - backoff_multiplier: Delay multiplier (default: 2)
# - jitter: Add random jitter to delays (default: true)
```

### Safe Command Execution

```bash
# Execute commands with error handling
safe_execute "git clone https://github.com/user/repo.git" "cloning repository" 3 2

# Parameters:
# - command: Command to execute
# - description: Human-readable description
# - max_attempts: Maximum retry attempts (default: 1)
# - retry_delay: Initial retry delay (default: 2)
```

### Safe File Operations

```bash
# Safe file copy with backup
safe_file_operation "copy" "/source/file" "/target/file" true

# Safe file move
safe_file_operation "move" "/source/file" "/target/file"

# Safe file removal
safe_file_operation "remove" "/path/to/file"
```

### Cleanup Registration

```bash
# Register cleanup function
cleanup_my_temp_files() {
    rm -rf /tmp/my_temp_dir
}
register_cleanup cleanup_my_temp_files

# Register temporary files/directories
temp_file=$(mktemp)
register_temp_file "$temp_file"

temp_dir=$(mktemp -d)
register_temp_dir "$temp_dir"
```

### Enhanced Download with Error Handling

```bash
# Download with checksum verification
download_file "https://example.com/file.tar.gz" "/tmp/file.tar.gz" 3 \
    "sha256_checksum_here" "sha256"

# Parameters:
# - url: URL to download
# - output: Output file path
# - max_attempts: Maximum retry attempts (default: 3)
# - expected_checksum: Expected checksum (optional)
# - checksum_algorithm: Checksum algorithm (default: sha256)
```

## Error Codes

The system uses standardized error codes:

| Code | Constant | Description |
|------|----------|-------------|
| 0 | ERROR_SUCCESS | Success |
| 1 | ERROR_GENERAL | General error |
| 2 | ERROR_MISUSE | Command misuse |
| 3 | ERROR_PERMISSION | Permission denied |
| 4 | ERROR_NOT_FOUND | File/resource not found |
| 5 | ERROR_NETWORK | Network error |
| 6 | ERROR_TIMEOUT | Operation timeout |
| 7 | ERROR_INVALID_CONFIG | Invalid configuration |
| 8 | ERROR_DEPENDENCY | Missing dependency |
| 9 | ERROR_PLATFORM | Unsupported platform |
| 10 | ERROR_USER_ABORT | User aborted operation |
| 11 | ERROR_DISK_SPACE | Insufficient disk space |
| 12 | ERROR_CHECKSUM | Checksum verification failed |
| 13 | ERROR_BACKUP | Backup operation failed |
| 14 | ERROR_CLEANUP | Cleanup operation failed |
| 99 | ERROR_CRITICAL | Critical system error |

## Configuration

The error handling system can be configured using environment variables:

```bash
# Enable/disable error handling
export ERROR_HANDLING_ENABLED="true"

# Enable/disable error recovery
export ERROR_RECOVERY_ENABLED="true"

# Enable/disable automatic cleanup
export ERROR_CLEANUP_ENABLED="true"

# Enable/disable stack trace logging
export ERROR_LOG_STACK_TRACE="true"

# Enable/disable interactive recovery
export ERROR_INTERACTIVE_RECOVERY="true"
```

## Error Recovery

The system includes automatic recovery for common error types:

### Network Errors
- Check network connectivity
- Verify DNS resolution
- Prompt for retry

### Permission Errors
- Suggest using sudo
- Check file permissions
- Offer alternative paths

### Disk Space Errors
- Check available space
- Suggest cleanup
- Prompt to continue after cleanup

### Dependency Errors
- Identify missing dependencies
- Offer to install dependencies
- Provide installation instructions

## Error Reporting

Generate detailed error reports for debugging:

```bash
# Create error report
report_file=$(create_error_report "/tmp/error_report.txt")
echo "Error report created: $report_file"
```

Error reports include:
- Error context and stack trace
- System information
- Environment variables
- Recent log entries

## Best Practices

### 1. Always Set Context
```bash
set_error_context "module_name" "operation_name" "file_path"
```

### 2. Use Error Stack
```bash
push_error_stack "high_level_operation"
# ... nested operations ...
pop_error_stack
```

### 3. Register Cleanup
```bash
register_cleanup my_cleanup_function
register_temp_file "$temp_file"
register_temp_dir "$temp_dir"
```

### 4. Use Safe Operations
```bash
# Instead of: cp "$source" "$target"
safe_file_operation "copy" "$source" "$target"

# Instead of: curl -o "$file" "$url"
download_file "$url" "$file" 3
```

### 5. Handle Specific Errors
```bash
if ! some_operation; then
    case $? in
        $ERROR_NETWORK)
            log_error "Network error occurred"
            ;;
        $ERROR_PERMISSION)
            log_error "Permission denied"
            ;;
        *)
            log_error "Unknown error occurred"
            ;;
    esac
fi
```

## Testing

Test the error handling system:

```bash
# Run all error handling tests
./test_error_handling.sh

# Run specific test categories
./test_error_handling.sh retry
./test_error_handling.sh network
./test_error_handling.sh cleanup
```

## Integration with Other Components

The error handling system integrates with:

- **Logger**: All errors are logged with appropriate levels
- **Utils**: Enhanced utility functions use error handling
- **Modules**: Module installation uses error handling
- **Platform**: Platform detection includes error handling
- **Config**: Configuration parsing includes error handling

## Troubleshooting

### Common Issues

1. **Error handling not working**
   - Ensure `init_error_handling` is called
   - Check that `ERROR_HANDLING_ENABLED="true"`

2. **Cleanup not running**
   - Verify cleanup functions are registered
   - Check that `ERROR_CLEANUP_ENABLED="true"`

3. **Retry not working**
   - Ensure error codes are retryable
   - Check retry configuration parameters

4. **Interactive recovery not prompting**
   - Verify `ERROR_INTERACTIVE_RECOVERY="true"`
   - Ensure script is running in interactive mode

### Debug Mode

Enable debug logging to see error handling details:

```bash
export LOG_LEVEL="DEBUG"
export ERROR_LOG_STACK_TRACE="true"
```

This will provide detailed information about error handling operations, stack traces, and recovery attempts.