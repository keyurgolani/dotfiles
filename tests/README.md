# Testing Framework for Unified Dotfiles

This directory contains a comprehensive testing framework for the unified dotfiles framework, built using the [Bats](https://github.com/bats-core/bats-core) testing framework for Bash.

## Quick Start

1. **Set up the testing environment:**
   ```bash
   cd tests
   ./setup.sh
   ```

2. **Run all tests:**
   ```bash
   ./run_tests.sh
   ```

3. **Run specific test types:**
   ```bash
   ./run_tests.sh unit           # Unit tests only
   ./run_tests.sh integration    # Integration tests only
   ./run_tests.sh platform       # Platform-specific tests
   ```

## Test Structure

```
tests/
├── setup.sh                 # Test environment setup script
├── run_tests.sh             # Test runner with various options
├── test_config.sh           # Test configuration and environment
├── helpers/
│   ├── test_helpers.bash    # Common test utilities and functions
│   └── bats-helpers/        # Bats helper libraries (auto-installed)
├── unit/                    # Unit tests for individual functions
│   ├── test_platform.bats   # Platform detection tests
│   ├── test_config.bats     # Configuration management tests
│   ├── test_backup.bats     # Backup and restore tests
│   ├── test_utils.bats      # Utility function tests
│   └── test_logger.bats     # Logging system tests
├── integration/             # Integration tests for complete workflows
│   └── test_installation.bats # End-to-end installation tests
└── fixtures/                # Test data and mock environments
    ├── configs/             # Sample configuration files
    ├── mock_environments/   # Platform simulation scripts
    └── sample_dotfiles/     # Test dotfiles for backup/restore
```

## Test Types

### Unit Tests

Test individual functions and components in isolation:

- **Platform Detection** (`test_platform.bats`): Tests OS detection, package manager identification, and platform-specific utilities
- **Configuration Management** (`test_config.bats`): Tests YAML parsing, configuration merging, and validation
- **Backup System** (`test_backup.bats`): Tests backup creation, restoration, and integrity checking
- **Utilities** (`test_utils.bats`): Tests helper functions, file operations, and string manipulation
- **Logging** (`test_logger.bats`): Tests logging levels, file output, and message formatting

### Integration Tests

Test complete workflows and system interactions:

- **Installation Workflows** (`test_installation.bats`): Tests end-to-end installation processes across different platforms and configurations

### Platform-Specific Tests

Tests that verify platform-specific functionality:

- Automatic platform detection and testing
- Platform-specific package manager integration
- OS-specific configuration handling

## Running Tests

### Basic Usage

```bash
# Run all tests
./run_tests.sh

# Run with verbose output
./run_tests.sh -v

# Run specific test type
./run_tests.sh unit
./run_tests.sh integration

# Run tests matching a pattern
./run_tests.sh --filter "platform"
```

### Advanced Options

```bash
# Run tests in parallel (faster execution)
./run_tests.sh --parallel 8

# Generate coverage report
./run_tests.sh --coverage

# Run in CI mode (non-interactive)
./run_tests.sh --ci

# Clean test artifacts
./run_tests.sh --clean
```

### Environment Variables

Control test behavior with environment variables:

```bash
# Override platform detection
PLATFORM_OVERRIDE=macos ./run_tests.sh

# Use specific shell for tests
TEST_SHELL=/bin/zsh ./run_tests.sh

# Enable verbose output
VERBOSE=true ./run_tests.sh

# Set parallel job count
BATS_PARALLEL=4 ./run_tests.sh
```

## Mock Environments

The testing framework includes mock environments for different platforms:

- **macOS** (`mock_environments/macos.sh`): Simulates macOS with Homebrew
- **Ubuntu** (`mock_environments/ubuntu.sh`): Simulates Ubuntu with apt
- **WSL** (`mock_environments/wsl.sh`): Simulates Windows Subsystem for Linux
- **Amazon Linux** (`mock_environments/amazon-linux.sh`): Simulates Amazon Linux 2 with yum/dnf

These mocks allow testing platform-specific functionality without requiring actual platform environments.

## Test Fixtures

### Configuration Files

- `test_modules.yaml`: Sample module configuration
- `test_user.yaml`: Sample user configuration
- `test_overrides.yaml`: Sample override configurations

### Sample Dotfiles

- `.bashrc`, `.zshrc`: Shell configuration samples
- `.vimrc`, `.tmux.conf`: Application configuration samples
- `.gitconfig`: Git configuration sample

## Writing Tests

### Basic Test Structure

```bash
#!/usr/bin/env bats

load '../helpers/test_helpers'

setup() {
    setup_test_environment
    source_core_function "module_to_test.sh"
}

teardown() {
    teardown_test_environment
}

@test "test description" {
    run function_to_test "arguments"
    assert_success
    assert_output "expected output"
}
```

### Helper Functions

The test framework provides many helper functions:

```bash
# Environment setup
setup_test_environment()
teardown_test_environment()

# Platform mocking
mock_platform "macos"
mock_command "brew" "echo 'mocked brew'"

# File operations
create_test_dotfiles ".bashrc" ".vimrc"
create_test_config "modules" "$config_content"
assert_file_contains "$file" "expected content"

# Test utilities
skip_if_missing "dependency"
skip_on_platform "macos"
wait_for_condition "test -f file" 10 1
```

### Assertions

Use bats-assert library for comprehensive assertions:

```bash
assert_success              # Command succeeded
assert_failure              # Command failed
assert_output "text"        # Output matches exactly
assert_output_contains "text" # Output contains text
assert_file_exist "file"    # File exists
assert_dir_exist "dir"      # Directory exists
```

## Continuous Integration

The framework includes GitHub Actions workflows for automated testing:

- **Multi-platform testing**: Tests on Ubuntu, macOS, and different versions
- **Multi-shell testing**: Tests with both Bash and Zsh
- **Docker testing**: Tests in containerized environments
- **WSL testing**: Tests Windows Subsystem for Linux compatibility
- **Security scanning**: Checks for security issues in shell scripts
- **Linting**: Validates shell script quality with ShellCheck

## Coverage Reporting

Generate test coverage reports using kcov:

```bash
# Install kcov (Ubuntu/Debian)
sudo apt-get install kcov

# Run tests with coverage
./run_tests.sh --coverage

# View coverage report
open tests/coverage/index.html
```

## Troubleshooting

### Common Issues

1. **Bats not found**: Run `./setup.sh` to install bats and dependencies
2. **Permission denied**: Ensure test scripts are executable with `chmod +x`
3. **Mock commands not working**: Check that `$TEST_TEMP_DIR/mock_bin` is in PATH
4. **Platform detection issues**: Use `PLATFORM_OVERRIDE` environment variable

### Debug Mode

Enable debug output for troubleshooting:

```bash
VERBOSE=true ./run_tests.sh
DOTFILES_LOG_LEVEL=DEBUG ./run_tests.sh
```

### Test Isolation

Each test runs in an isolated environment:

- Temporary directories are created for each test
- Environment variables are scoped to individual tests
- Mock commands are cleaned up after each test
- File system changes are contained within test directories

## Contributing

When adding new functionality to the dotfiles framework:

1. **Write tests first**: Follow TDD principles
2. **Test all platforms**: Ensure cross-platform compatibility
3. **Mock external dependencies**: Use mock commands for package managers, etc.
4. **Test error conditions**: Include negative test cases
5. **Update CI**: Add new test files to the CI workflow

### Test Naming Conventions

- Test files: `test_<module>.bats`
- Test functions: `@test "descriptive test name"`
- Helper functions: `<action>_<object>` (e.g., `create_test_config`)
- Mock files: `mock_<environment>.sh`

## Performance

The testing framework is optimized for speed:

- **Parallel execution**: Tests run in parallel by default
- **Efficient mocking**: Lightweight mock implementations
- **Minimal setup**: Fast test environment initialization
- **Selective testing**: Run only relevant tests with filters

Typical test execution times:
- Unit tests: ~30 seconds
- Integration tests: ~2 minutes
- Full test suite: ~3 minutes (with parallelization)

## Dependencies

The testing framework automatically installs its dependencies:

- **Bats Core**: Main testing framework
- **bats-support**: Additional assertion helpers
- **bats-assert**: Assertion library
- **bats-file**: File system assertions

Optional dependencies for enhanced functionality:
- **ShellCheck**: Shell script linting
- **kcov**: Code coverage reporting
- **jq**: JSON processing (for some tests)
- **yq**: YAML processing (for configuration tests)