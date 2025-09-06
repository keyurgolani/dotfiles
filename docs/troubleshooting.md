# Troubleshooting Guide

This guide helps resolve common issues encountered during installation and usage.

## Quick Fixes

### Installation Issues
- **Installation fails**: Run `./scripts/install.sh --verbose` for detailed output
- **Permission errors**: Normal for system files; framework handles gracefully  
- **Missing tools**: Framework auto-installs dependencies when possible
- **Network issues**: Check connectivity with `curl -s https://github.com`

### Configuration Issues
- **Shell startup slow**: Enable `performance.shell_startup_optimization: true`
- **Git warnings**: Framework auto-creates missing gitignore files
- **Module conflicts**: Use `./scripts/install.sh --dry-run` to preview changes

### Platform-Specific
- **macOS**: Install Xcode Command Line Tools: `xcode-select --install`
- **Ubuntu/WSL**: Update packages: `sudo apt update && sudo apt install git curl`
- **Amazon Linux**: Install tools: `sudo yum install git curl`

## Debug Commands

### Testing and Validation
```bash
# Test installation without changes
./scripts/install.sh --dry-run --verbose

# Test specific modules
./scripts/install.sh --modules shell,git --dry-run

# Check configuration
./scripts/install.sh --help
```

### Performance Testing
```bash
# Test shell startup time
time zsh -i -c exit

# Check module status
./scripts/module_cli.sh list
```

### Backup and Recovery
```bash
# Create backup before changes
./scripts/install.sh backup

# List available backups
./scripts/maintenance.sh list-backups

# Restore from backup
./scripts/maintenance.sh restore [backup-id]
```

## Getting Help

### Support Channels
- **Built-in Help**: `./dotfiles.sh` or `./scripts/install.sh --help`
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Check `docs/` directory for advanced topics

### Reporting Issues
When reporting issues, include:
1. Platform and shell version
2. Full error output
3. Steps to reproduce
4. Output from `./scripts/install.sh --dry-run --verbose`