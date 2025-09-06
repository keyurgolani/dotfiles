#!/bin/bash

# Test setup script for unified dotfiles framework
# Installs bats testing framework and sets up test environment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
BATS_VERSION="v1.10.0"
BATS_INSTALL_DIR="$HOME/.local/bin"
TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$TEST_ROOT")"

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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install bats testing framework
install_bats() {
    log_info "Installing bats testing framework..."
    
    if command_exists bats; then
        log_info "Bats already installed: $(bats --version)"
        return 0
    fi
    
    # Create local bin directory if it doesn't exist
    mkdir -p "$BATS_INSTALL_DIR"
    
    # Download and install bats
    local temp_dir
    temp_dir=$(mktemp -d)
    
    log_info "Downloading bats $BATS_VERSION..."
    if command_exists curl; then
        curl -sSL "https://github.com/bats-core/bats-core/archive/${BATS_VERSION}.tar.gz" | tar -xz -C "$temp_dir"
    elif command_exists wget; then
        wget -qO- "https://github.com/bats-core/bats-core/archive/${BATS_VERSION}.tar.gz" | tar -xz -C "$temp_dir"
    else
        log_error "Neither curl nor wget found. Cannot download bats."
        return 1
    fi
    
    # Install bats
    cd "$temp_dir/bats-core-${BATS_VERSION#v}"
    ./install.sh "$HOME/.local"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$BATS_INSTALL_DIR:"* ]]; then
        export PATH="$BATS_INSTALL_DIR:$PATH"
        log_info "Added $BATS_INSTALL_DIR to PATH for this session"
        log_warn "Add 'export PATH=\"$BATS_INSTALL_DIR:\$PATH\"' to your shell profile for permanent access"
    fi
    
    log_info "Bats installed successfully: $(bats --version)"
}

# Install bats helper libraries
install_bats_helpers() {
    log_info "Installing bats helper libraries..."
    
    local helpers_dir="$TEST_ROOT/helpers/bats-helpers"
    mkdir -p "$helpers_dir"
    
    # Install bats-support
    if [[ ! -d "$helpers_dir/bats-support" ]]; then
        log_info "Installing bats-support..."
        git clone https://github.com/bats-core/bats-support.git "$helpers_dir/bats-support" 2>/dev/null || {
            log_warn "Git clone failed, downloading archive..."
            local temp_dir
            temp_dir=$(mktemp -d)
            curl -sSL "https://github.com/bats-core/bats-support/archive/master.tar.gz" | tar -xz -C "$temp_dir"
            mv "$temp_dir/bats-support-master" "$helpers_dir/bats-support"
            rm -rf "$temp_dir"
        }
    fi
    
    # Install bats-assert
    if [[ ! -d "$helpers_dir/bats-assert" ]]; then
        log_info "Installing bats-assert..."
        git clone https://github.com/bats-core/bats-assert.git "$helpers_dir/bats-assert" 2>/dev/null || {
            log_warn "Git clone failed, downloading archive..."
            local temp_dir
            temp_dir=$(mktemp -d)
            curl -sSL "https://github.com/bats-core/bats-assert/archive/master.tar.gz" | tar -xz -C "$temp_dir"
            mv "$temp_dir/bats-assert-master" "$helpers_dir/bats-assert"
            rm -rf "$temp_dir"
        }
    fi
    
    # Install bats-file
    if [[ ! -d "$helpers_dir/bats-file" ]]; then
        log_info "Installing bats-file..."
        git clone https://github.com/bats-core/bats-file.git "$helpers_dir/bats-file" 2>/dev/null || {
            log_warn "Git clone failed, downloading archive..."
            local temp_dir
            temp_dir=$(mktemp -d)
            curl -sSL "https://github.com/bats-core/bats-file/archive/master.tar.gz" | tar -xz -C "$temp_dir"
            mv "$temp_dir/bats-file-master" "$helpers_dir/bats-file"
            rm -rf "$temp_dir"
        }
    fi
    
    log_info "Bats helper libraries installed successfully"
}

# Setup test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Create test directories
    mkdir -p "$TEST_ROOT"/{unit,integration,fixtures,helpers}
    mkdir -p "$TEST_ROOT/fixtures"/{configs,mock_environments,sample_dotfiles}
    
    # Create test configuration
    cat > "$TEST_ROOT/test_config.sh" << 'EOF'
#!/bin/bash

# Test configuration for unified dotfiles framework

# Test environment variables
export TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT="$(dirname "$TEST_ROOT")"
export TEST_FIXTURES_DIR="$TEST_ROOT/fixtures"
export TEST_TEMP_DIR="${TMPDIR:-/tmp}/dotfiles_test_$$"

# Test-specific overrides
export DOTFILES_BACKUP_DIR="$TEST_TEMP_DIR/backups"
export DOTFILES_CONFIG_DIR="$TEST_FIXTURES_DIR/configs"
export DOTFILES_LOG_LEVEL="DEBUG"

# Create test temp directory
mkdir -p "$TEST_TEMP_DIR"

# Cleanup function for tests
cleanup_test_env() {
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Trap cleanup on exit
trap cleanup_test_env EXIT
EOF
    
    log_info "Test environment setup complete"
}

# Create sample test fixtures
create_test_fixtures() {
    log_info "Creating test fixtures..."
    
    # Sample configuration files
    cat > "$TEST_ROOT/fixtures/configs/test_modules.yaml" << 'EOF'
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
user:
  name: "Test User"
  email: "test@example.com"
  github_username: "testuser"
EOF

    cat > "$TEST_ROOT/fixtures/configs/test_user.yaml" << 'EOF'
user:
  name: "Test User"
  email: "test@example.com"
  github_username: "testuser"
  shell: "/bin/bash"
preferences:
  editor: "vim"
  terminal: "iterm2"
EOF

    # Sample dotfiles for testing
    mkdir -p "$TEST_ROOT/fixtures/sample_dotfiles"
    echo "# Test bashrc" > "$TEST_ROOT/fixtures/sample_dotfiles/.bashrc"
    echo "# Test vimrc" > "$TEST_ROOT/fixtures/sample_dotfiles/.vimrc"
    echo "# Test gitconfig" > "$TEST_ROOT/fixtures/sample_dotfiles/.gitconfig"
    
    # Mock environment scripts
    cat > "$TEST_ROOT/fixtures/mock_environments/macos.sh" << 'EOF'
#!/bin/bash
# Mock macOS environment for testing

export OSTYPE="darwin"
export PLATFORM_OVERRIDE="macos"

# Mock commands
brew() {
    echo "brew $*"
    case "$1" in
        "--version") echo "Homebrew 4.0.0" ;;
        "list") echo "git\nvim\ntmux" ;;
        *) return 0 ;;
    esac
}

sw_vers() {
    case "$1" in
        "-productVersion") echo "13.0.0" ;;
        "-productName") echo "macOS" ;;
        *) echo "ProductName: macOS\nProductVersion: 13.0.0" ;;
    esac
}

export -f brew sw_vers
EOF

    cat > "$TEST_ROOT/fixtures/mock_environments/ubuntu.sh" << 'EOF'
#!/bin/bash
# Mock Ubuntu environment for testing

export OSTYPE="linux-gnu"
export PLATFORM_OVERRIDE="ubuntu"

# Mock commands
apt() {
    echo "apt $*"
    case "$1" in
        "list") echo "git/now 1:2.34.1-1ubuntu1.9 amd64 [installed]" ;;
        *) return 0 ;;
    esac
}

lsb_release() {
    case "$1" in
        "-si") echo "Ubuntu" ;;
        "-sr") echo "22.04" ;;
        "-a") echo "Distributor ID: Ubuntu\nDescription: Ubuntu 22.04.3 LTS\nRelease: 22.04\nCodename: jammy" ;;
        *) return 0 ;;
    esac
}

export -f apt lsb_release
EOF

    log_info "Test fixtures created successfully"
}

# Main setup function
main() {
    log_info "Setting up unified dotfiles testing framework..."
    
    install_bats
    install_bats_helpers
    setup_test_environment
    create_test_fixtures
    
    log_info "Testing framework setup complete!"
    log_info "Run tests with: cd $TEST_ROOT && bats unit/ integration/"
    log_info "Or run specific test files: bats unit/test_platform.bats"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi