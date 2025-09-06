# Contributing to Unified Dotfiles Framework

Thank you for your interest in contributing! This guide will help you get started with contributing to the Unified Dotfiles Framework.

## 🚀 Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git
   cd dotfiles
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes** and test them
5. **Submit a pull request**

## 🎯 Ways to Contribute

### 🐛 Bug Reports
- Use the GitHub issue tracker
- Include steps to reproduce
- Provide system information (OS, shell, etc.)
- Include relevant log output

### ✨ Feature Requests
- Check existing issues first
- Describe the use case clearly
- Explain why it would be valuable

### 📝 Documentation
- Fix typos and improve clarity
- Add examples and use cases
- Update outdated information

### 🔧 Code Contributions
- **Modules**: Add support for new tools/configurations
- **Platforms**: Add support for new operating systems
- **Plugins**: Create reusable extensions
- **Core**: Improve framework functionality

## 📋 Development Guidelines

### Code Style
- Use **bash** for shell scripts
- Follow existing code formatting
- Add comments for complex logic
- Use meaningful variable names

### Module Development
```bash
# Create a new module
mkdir -p modules/your-tool
cd modules/your-tool

# Required files:
# - module.yaml (configuration)
# - install.sh (installation script)
# - README.md (documentation)

# Use module CLI for management
./scripts/module_cli.sh list
./scripts/module_cli.sh validate your-tool
./scripts/module_cli.sh test your-tool
```

### Testing
- Test on multiple platforms when possible
- Use the BATS test framework: `./tests/run_tests.sh`
- Add tests for new functionality in `tests/unit/` or `tests/integration/`
- Ensure backward compatibility
- Use test fixtures in `tests/fixtures/` for mock data

### Documentation
- Update README.md for major changes
- Add inline documentation
- Include usage examples
- Update help text in scripts

## 🔍 Pull Request Process

### Before Submitting
1. **Test your changes** thoroughly
2. **Update documentation** as needed
3. **Follow the coding standards**
4. **Write clear commit messages**

### PR Requirements
- **Clear description** of what the PR does
- **Link to related issues** if applicable
- **Test results** on different platforms
- **Screenshots** for UI changes (if applicable)

### Review Process
1. Automated tests will run
2. Maintainers will review the code
3. Address any feedback
4. PR will be merged once approved

## 🏗️ Project Structure

```
unified-dotfiles/
├── dotfiles.sh           # Main entry point
├── deploy.sh             # Alias to dotfiles.sh
├── scripts/              # CLI utilities (install, maintenance, module_cli, etc.)
├── core/                 # Framework logic (config, logger, utils, platform)
├── modules/              # Tool configurations (shell, git, vim, tmux, etc.)
├── platforms/            # OS-specific code (macos, ubuntu)
├── plugins/              # Plugin system with example
├── tests/                # BATS test suite (unit, integration, fixtures)
├── docs/                 # Comprehensive documentation
├── config/               # YAML configuration files
├── templates/            # Configuration templates
├── schemas/              # JSON validation schemas
└── migrations/           # Migration scripts
```

## 🎨 Module Development

### Creating a New Module

1. **Create module directory**:
   ```bash
   mkdir -p modules/your-tool
   ```

2. **Create module.yaml**:
   ```yaml
   name: "your-tool"
   description: "Brief description of what this configures"
   platforms: ["macos", "ubuntu", "wsl"]
   dependencies: ["shell"]  # Other modules this depends on
   ```

3. **Create install.sh**:
   ```bash
   #!/bin/bash
   # Installation script for your-tool module
   
   set -euo pipefail
   
   # Your installation logic here
   echo "Installing your-tool configuration..."
   ```

4. **Create README.md**:
   ```markdown
   # Your Tool Module
   
   Brief description and usage instructions.
   ```

### Module Guidelines
- **Cross-platform**: Support multiple operating systems
- **Idempotent**: Safe to run multiple times
- **Configurable**: Allow user customization
- **Documented**: Clear README with examples

## 🔌 Plugin Development

Plugins extend the framework with additional functionality.

### Plugin Structure
```
plugins/your-plugin/
├── plugin.yaml          # Plugin metadata
├── install.sh           # Installation script
├── uninstall.sh         # Cleanup script
└── README.md            # Documentation
```

See `plugins/example-plugin/` for a complete example.

### Plugin Management
```bash
# List available plugins
./scripts/plugins_cli.sh list

# Install a plugin
./scripts/plugins_cli.sh install plugin-name

# Create a new plugin
./scripts/plugins_cli.sh create my-plugin
```

## 🧪 Testing

### Running Tests
```bash
# Run all tests
./tests/run_tests.sh

# Run specific test types
./tests/run_tests.sh unit
./tests/run_tests.sh integration

# Run tests with verbose output
VERBOSE=true ./tests/run_tests.sh

# Run tests in parallel
BATS_PARALLEL=4 ./tests/run_tests.sh
```

### Writing Tests
- Use the BATS (Bash Automated Testing System) framework
- Place unit tests in `tests/unit/` directory
- Place integration tests in `tests/integration/` directory
- Use test fixtures in `tests/fixtures/` for mock data
- Use test helpers in `tests/helpers/` for common functions
- Test both success and failure cases
- Mock external dependencies when possible

## 📚 Documentation Standards

### README Files
- Start with a brief description
- Include installation/usage instructions
- Provide examples
- List requirements and dependencies

### Code Comments
- Explain **why**, not just **what**
- Document complex algorithms
- Include usage examples for functions
- Keep comments up to date

### Help Text
- Be concise but complete
- Include examples
- Use consistent formatting
- Test with `--help` flags

## 🚀 Release Process

### Versioning
We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Release Checklist
1. Update VERSION file
2. Update CHANGELOG.md
3. Test on all supported platforms
4. Create release notes
5. Tag the release

## 🤝 Community Guidelines

### Be Respectful
- Use inclusive language
- Be patient with newcomers
- Provide constructive feedback
- Help others learn

### Communication
- **Issues**: Bug reports and feature requests
- **Discussions**: Questions and general discussion
- **Pull Requests**: Code contributions

## 🆘 Getting Help

### Documentation
- **README.md**: Main documentation
- **docs/**: Detailed guides
- **Built-in help**: `./dotfiles.sh` or `./scripts/install.sh --help`

### Support Channels
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community support
- **Code Review**: Pull request feedback

## 📝 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to the Unified Dotfiles Framework!** 🎉

Your contributions help make development environment setup easier for everyone.