#!/bin/bash

# Test runner script for unified dotfiles framework
# Provides convenient interface for running different types of tests

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
BATS_PARALLEL=${BATS_PARALLEL:-4}
VERBOSE=${VERBOSE:-false}
COVERAGE=${COVERAGE:-false}

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*"
    fi
}

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [TEST_TYPE]

Test runner for unified dotfiles framework

TEST_TYPE:
    unit            Run unit tests only
    integration     Run integration tests only
    all             Run all tests (default)
    platform        Run platform-specific tests
    coverage        Run tests with coverage report
    lint            Run shell script linting
    security        Run security checks

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -p, --parallel  Number of parallel test jobs (default: 4)
    -c, --coverage  Generate coverage report
    -f, --filter    Filter tests by pattern
    --setup         Set up test environment only
    --clean         Clean test artifacts
    --ci            Run in CI mode (non-interactive)

ENVIRONMENT VARIABLES:
    PLATFORM_OVERRIDE    Override platform detection (macos|ubuntu|wsl|amazon-linux)
    TEST_SHELL          Shell to use for tests (bash|zsh)
    BATS_PARALLEL       Number of parallel test jobs
    VERBOSE             Enable verbose output (true|false)

Examples:
    $0                          # Run all tests
    $0 unit                     # Run unit tests only
    $0 -v integration           # Run integration tests with verbose output
    $0 --filter "platform"      # Run tests matching "platform"
    $0 --coverage unit          # Run unit tests with coverage
    PLATFORM_OVERRIDE=macos $0  # Test with macOS platform override

EOF
}

# Check if bats is available
check_bats() {
    if ! command -v bats >/dev/null 2>&1; then
        log_error "Bats testing framework not found"
        log_info "Run '$0 --setup' to install test dependencies"
        return 1
    fi
    
    log_debug "Found bats: $(bats --version)"
}

# Set up test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    cd "$SCRIPT_DIR"
    
    if [[ -f "setup.sh" ]]; then
        chmod +x setup.sh
        ./setup.sh
    else
        log_error "setup.sh not found in tests directory"
        return 1
    fi
    
    log_info "Test environment setup complete"
}

# Clean test artifacts
clean_test_artifacts() {
    log_info "Cleaning test artifacts..."
    
    # Remove temporary test files
    find "$SCRIPT_DIR" -name "*.tmp" -delete 2>/dev/null || true
    find "$SCRIPT_DIR" -name "test-results*" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Clean coverage reports
    rm -rf "$SCRIPT_DIR/coverage" 2>/dev/null || true
    
    # Clean bats temporary files
    rm -rf /tmp/bats-* 2>/dev/null || true
    
    log_info "Test artifacts cleaned"
}

# Run unit tests
run_unit_tests() {
    log_info "Running unit tests..."
    
    local filter_pattern="${1:-}"
    local bats_args=()
    
    if [[ "$VERBOSE" == "true" ]]; then
        bats_args+=("--verbose-run")
    fi
    
    if [[ -n "$filter_pattern" ]]; then
        bats_args+=("--filter" "$filter_pattern")
    fi
    
    if [[ "$BATS_PARALLEL" -gt 1 ]]; then
        bats_args+=("--jobs" "$BATS_PARALLEL")
    fi
    
    cd "$SCRIPT_DIR"
    
    if [[ "$COVERAGE" == "true" ]] && command -v kcov >/dev/null 2>&1; then
        mkdir -p coverage
        kcov --include-path="$DOTFILES_ROOT/core" coverage bats "${bats_args[@]}" unit/
    else
        bats "${bats_args[@]}" unit/
    fi
}

# Run integration tests
run_integration_tests() {
    log_info "Running integration tests..."
    
    local filter_pattern="${1:-}"
    local bats_args=()
    
    if [[ "$VERBOSE" == "true" ]]; then
        bats_args+=("--verbose-run")
    fi
    
    if [[ -n "$filter_pattern" ]]; then
        bats_args+=("--filter" "$filter_pattern")
    fi
    
    if [[ "$BATS_PARALLEL" -gt 1 ]]; then
        bats_args+=("--jobs" "$BATS_PARALLEL")
    fi
    
    cd "$SCRIPT_DIR"
    bats "${bats_args[@]}" integration/
}

# Run platform-specific tests
run_platform_tests() {
    log_info "Running platform-specific tests..."
    
    local current_platform="${PLATFORM_OVERRIDE:-$(detect_current_platform)}"
    log_info "Testing for platform: $current_platform"
    
    cd "$SCRIPT_DIR"
    
    # Run platform detection tests
    PLATFORM_OVERRIDE="$current_platform" bats unit/test_platform.bats
    
    # Run platform-specific integration tests if they exist
    if [[ -f "integration/test_${current_platform}.bats" ]]; then
        PLATFORM_OVERRIDE="$current_platform" bats "integration/test_${current_platform}.bats"
    fi
}

# Detect current platform for testing
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

# Run linting checks
run_lint_checks() {
    log_info "Running shell script linting..."
    
    if ! command -v shellcheck >/dev/null 2>&1; then
        log_warn "ShellCheck not found, skipping lint checks"
        return 0
    fi
    
    cd "$DOTFILES_ROOT"
    
    # Find all shell scripts
    local shell_scripts
    mapfile -t shell_scripts < <(find . -name "*.sh" -not -path "./tests/helpers/bats-*" -not -path "./.git/*")
    
    if [[ ${#shell_scripts[@]} -eq 0 ]]; then
        log_warn "No shell scripts found to lint"
        return 0
    fi
    
    log_info "Linting ${#shell_scripts[@]} shell scripts..."
    
    local failed=0
    for script in "${shell_scripts[@]}"; do
        log_debug "Linting: $script"
        if ! shellcheck "$script"; then
            log_error "Linting failed for: $script"
            failed=$((failed + 1))
        fi
    done
    
    if [[ $failed -gt 0 ]]; then
        log_error "$failed shell scripts failed linting"
        return 1
    fi
    
    log_info "All shell scripts passed linting"
}

# Run security checks
run_security_checks() {
    log_info "Running security checks..."
    
    cd "$DOTFILES_ROOT"
    
    local issues=0
    
    # Check for insecure HTTP downloads
    if grep -r "curl.*http://" . --include="*.sh" --exclude-dir=".git" >/dev/null 2>&1; then
        log_warn "Insecure HTTP downloads found:"
        grep -r "curl.*http://" . --include="*.sh" --exclude-dir=".git" || true
        issues=$((issues + 1))
    fi
    
    if grep -r "wget.*http://" . --include="*.sh" --exclude-dir=".git" >/dev/null 2>&1; then
        log_warn "Insecure HTTP downloads found:"
        grep -r "wget.*http://" . --include="*.sh" --exclude-dir=".git" || true
        issues=$((issues + 1))
    fi
    
    # Check for potentially dangerous eval usage
    if grep -r "eval.*\$" . --include="*.sh" --exclude-dir=".git" --exclude-dir="tests" >/dev/null 2>&1; then
        log_warn "Potentially dangerous eval usage found:"
        grep -r "eval.*\$" . --include="*.sh" --exclude-dir=".git" --exclude-dir="tests" || true
        issues=$((issues + 1))
    fi
    
    # Check for hardcoded secrets (basic check)
    if grep -r "password\|secret\|token" --include="*.sh" --include="*.yaml" . --exclude-dir=".git" | grep -v "test" | grep -v "example" >/dev/null 2>&1; then
        log_error "Potential hardcoded secrets found:"
        grep -r "password\|secret\|token" --include="*.sh" --include="*.yaml" . --exclude-dir=".git" | grep -v "test" | grep -v "example" || true
        issues=$((issues + 1))
    fi
    
    if [[ $issues -gt 0 ]]; then
        log_error "$issues security issues found"
        return 1
    fi
    
    log_info "No security issues found"
}

# Generate coverage report
generate_coverage_report() {
    log_info "Generating coverage report..."
    
    if ! command -v kcov >/dev/null 2>&1; then
        log_warn "kcov not found, cannot generate coverage report"
        log_info "Install kcov to enable coverage reporting"
        return 0
    fi
    
    cd "$SCRIPT_DIR"
    mkdir -p coverage
    
    # Run tests with coverage
    COVERAGE=true run_unit_tests
    
    if [[ -d "coverage" ]]; then
        log_info "Coverage report generated in: $SCRIPT_DIR/coverage"
        
        # Show coverage summary if available
        if [[ -f "coverage/index.html" ]]; then
            log_info "Open coverage/index.html in a browser to view detailed report"
        fi
    fi
}

# Main function
main() {
    local test_type="all"
    local filter_pattern=""
    local setup_only=false
    local clean_only=false
    local ci_mode=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -p|--parallel)
                BATS_PARALLEL="$2"
                shift 2
                ;;
            -c|--coverage)
                COVERAGE=true
                shift
                ;;
            -f|--filter)
                filter_pattern="$2"
                shift 2
                ;;
            --setup)
                setup_only=true
                shift
                ;;
            --clean)
                clean_only=true
                shift
                ;;
            --ci)
                ci_mode=true
                VERBOSE=false
                shift
                ;;
            unit|integration|all|platform|coverage|lint|security)
                test_type="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Handle setup and clean operations
    if [[ "$setup_only" == "true" ]]; then
        setup_test_environment
        exit 0
    fi
    
    if [[ "$clean_only" == "true" ]]; then
        clean_test_artifacts
        exit 0
    fi
    
    # Set CI mode defaults
    if [[ "$ci_mode" == "true" ]]; then
        export CI=true
        export DOTFILES_LOG_LEVEL="ERROR"
    fi
    
    # Check test environment
    if [[ "$test_type" != "lint" && "$test_type" != "security" ]]; then
        check_bats || exit 1
    fi
    
    # Run tests based on type
    case "$test_type" in
        unit)
            run_unit_tests "$filter_pattern"
            ;;
        integration)
            run_integration_tests "$filter_pattern"
            ;;
        platform)
            run_platform_tests
            ;;
        coverage)
            generate_coverage_report
            ;;
        lint)
            run_lint_checks
            ;;
        security)
            run_security_checks
            ;;
        all)
            run_unit_tests "$filter_pattern"
            run_integration_tests "$filter_pattern"
            run_platform_tests
            run_lint_checks
            run_security_checks
            ;;
        *)
            log_error "Unknown test type: $test_type"
            usage
            exit 1
            ;;
    esac
    
    log_info "Test run completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi