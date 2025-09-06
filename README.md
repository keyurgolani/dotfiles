# 🎯 Unified Dotfiles Framework

A comprehensive, cross-platform dotfiles management system with a **beautiful, unified interface**. No more script confusion - just run `./dotfiles.sh` and get a guided experience for all your development environment needs.

**Supports:** macOS, Ubuntu Linux, Windows WSL, and Amazon Linux 2

## ✨ Key Features

- **🎯 Single Entry Point**: Beautiful interface (`./dotfiles.sh`) - no more script confusion!
- **🧙 Guided Setup**: Interactive wizard for first-time users
- **🌍 Cross-Platform**: macOS, Ubuntu Linux, Windows WSL, Amazon Linux 2
- **🧩 Modular**: Install only what you need (shell, git, vim, tmux, etc.)
- **💾 Safe**: Automatic backups before any changes
- **⚡ Fast**: Parallel installation and optimized performance
- **🔒 Secure**: Personal information protection and input validation

## 🔒 Security & Privacy

- **Personal information** is never committed to the repository
- **Work-specific configs** are kept in gitignored files
- **Automatic backups** before any changes
- **Safe setup process** with guided configuration

See `SETUP.md` for detailed security guidelines.

## 🚀 Quick Start

### Prerequisites
- **macOS**: `xcode-select --install`
- **Ubuntu/Debian**: `sudo apt update && sudo apt install -y curl git`
- **Amazon Linux 2**: `sudo yum update && sudo yum install -y curl git`
- **Windows WSL**: Any Linux distribution with curl and git

### Installation

```bash
# Clone and run - that's it!
git clone https://github.com/keyurgolani/dotfiles.git dotfiles
cd dotfiles
./dotfiles.sh
```

The interactive interface guides you through:
- 🚀 **Getting Started**: Setup wizard or quick install
- 📦 **Module Management**: Choose shell, git, vim, tmux, etc.
- 🔧 **Maintenance**: Updates, backups, cleanup
- ⚙️ **Advanced**: Hooks, plugins, customization



## 🎯 Available Modules

| Module | Description | Platforms |
|--------|-------------|-----------|
| **shell** | Bash/Zsh configurations, aliases, functions | All |
| **git** | Git configuration, aliases, ignore patterns | All |
| **vim** | Vim configuration, plugins, key mappings | All |
| **tmux** | Tmux configuration, key bindings | All |
| **homebrew** | Homebrew package manager (macOS only) | macOS |
| **developer-tools** | Essential development tools | All |
| **iterm** | iTerm2 terminal configuration (macOS only) | macOS |
| **sublime** | Sublime Text editor configuration | All |
| **vscode** | Visual Studio Code settings and extensions | All |

Run `./dotfiles.sh` → "Browse Available" for complete list with descriptions.

### Advanced Usage

```bash
# Direct script access (for power users)
./scripts/install.sh --modules shell,git,vim,tmux
./scripts/maintenance.sh update
./scripts/install.sh --dry-run --verbose

# Module-specific utilities
./scripts/module_cli.sh shell setup-work-aliases
./scripts/hooks_cli.sh list
./scripts/plugins_cli.sh install my-plugin

# Environment-specific setup
./scripts/install.sh --override config/overrides/work.yaml
```

## 📁 Project Structure

```
unified-dotfiles/
├── 🎯 dotfiles.sh           # Main entry point - start here!
├── 🚀 deploy.sh             # Cool alias
├── scripts/                 # CLI utilities (install, maintenance, etc.)
├── modules/                 # Tool configurations (shell, git, vim, etc.)
├── core/                    # Framework internals (config, logger, utils)
├── platforms/               # OS-specific support (macos, ubuntu)
├── plugins/                 # Extensible plugin system
├── tests/                   # BATS testing framework
├── docs/                    # Comprehensive documentation
├── config/                  # YAML configuration files
├── templates/               # Configuration templates
└── schemas/                 # JSON validation schemas
```

## 📚 Documentation

- **Getting Started**: This README and `SETUP.md`
- **Contributing**: See `CONTRIBUTING.md`
- **Testing**: Comprehensive BATS testing framework in `tests/`
- **Built-in Help**: `./dotfiles.sh` or `./scripts/install.sh --help`

### Advanced Topics (`docs/`)
- **[Configuration](docs/configuration.md)** - YAML configuration system
- **[Modules](docs/modules.md)** - Available modules and development
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Hook System](docs/hook-system.md)** - Custom automation hooks
- **[Plugin API](docs/plugin-api.md)** - Plugin development
- **[Performance](docs/performance-optimization.md)** - Speed optimizations

## 🛠️ Common Commands

```bash
# Interactive interface (recommended)
./dotfiles.sh

# Direct script access
./scripts/install.sh --modules shell,git,vim
./scripts/maintenance.sh update
./scripts/install.sh backup

# Testing and validation
./tests/run_tests.sh
./tests/run_tests.sh unit
./tests/run_tests.sh integration
```

## ⚙️ Configuration

The framework uses YAML files for configuration:
- `config/user.yaml` - Your personal settings (from `config/user.yaml.template`)
- `config/base.yaml` - Framework defaults and base configuration
- `config/modules.yaml` - Module selection and configuration
- `config/overrides/` - Environment-specific configs (work, personal, etc.)
- `templates/` - Configuration file templates with variable substitution

See `SETUP.md` for detailed configuration instructions.

## 🔧 Extending the Framework

- **Custom Modules**: Add your own tool configurations in `modules/`
- **Hooks**: Create automation scripts with `./scripts/hooks_cli.sh`
- **Plugins**: Extend functionality with the plugin system
- **Environment Configs**: Create work/personal overrides in `config/overrides/`
- **Migrations**: Framework version migrations in `migrations/`

See `CONTRIBUTING.md` for development guidelines.

## 🆘 Getting Help & Troubleshooting

### Quick Help
- **Interactive Help**: `./dotfiles.sh` → "Help & Documentation"
- **Built-in Help**: `./scripts/install.sh --help`
- **Preview Changes**: `./scripts/install.sh --dry-run --verbose`

### Common Issues
- **Installation fails**: Run `./scripts/install.sh --verbose` for detailed output
- **Shell startup slow**: Enable `performance.shell_startup_optimization: true` in config
- **Permission errors**: Normal for system files; framework handles gracefully
- **Missing tools**: Framework auto-installs dependencies when possible

### Support Channels
- **Issues**: Report bugs on GitHub
- **Contributing**: See `CONTRIBUTING.md`
- **Documentation**: Check `docs/` for advanced topics

## 🤝 Contributing

Contributions are welcome! See `CONTRIBUTING.md` for guidelines on:
- Adding new modules and features
- Reporting bugs and requesting features  
- Improving documentation

## 📄 License

MIT License - see `LICENSE` file for details.

---

**Ready to get started?** Run `./dotfiles.sh` and experience the magic! ✨
