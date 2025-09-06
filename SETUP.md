# 🔒 Setup & Security Guide

This guide covers personal configuration and security best practices for the Unified Dotfiles Framework.

## 🚀 First-Time Setup

### 1. Quick Setup (Recommended)

The easiest way is to use the interactive interface:

```bash
./dotfiles.sh
```

Choose "Configuration Wizard" for guided first-time setup that handles everything automatically.

### 2. Manual Configuration (Advanced)

If you prefer manual setup:

```bash
# Copy the template
cp config/user.yaml.template config/user.yaml

# Edit with your information
$EDITOR config/user.yaml
```

Replace placeholder values:

- `[YOUR_FULL_NAME]` - Your full name for git commits
- `[YOUR_EMAIL]` - Your email address for git commits
- `[YOUR_GITHUB]` - Your GitHub username (optional)

The configuration supports environment variable substitution:
```yaml
user:
  name: "${USER_NAME:-[YOUR_FULL_NAME]}"
  email: "${USER_EMAIL:-[YOUR_EMAIL]}"
  github_username: "${GITHUB_USERNAME:-[YOUR_GITHUB]}"
```

## 🔒 Security & Privacy

### Personal Information Protection

- **Work-specific aliases** are kept in separate, gitignored files (`~/.aliases_work`)
- **Personal information** never gets committed to the repository
- **SSH configurations** use secure config files instead of hardcoded aliases
- **API keys and tokens** are handled through environment variables

### Safe Setup Process

```bash
# Set up work-specific aliases safely (automatically gitignored)
./scripts/module_cli.sh shell setup-work-aliases

# Edit your work aliases with personal information
$EDITOR ~/.aliases_work

# Use hooks for automation
./scripts/hooks_cli.sh create backup-before-install
./scripts/hooks_cli.sh list
```

### What's Protected

- Server hostnames and IP addresses
- Usernames and account names
- SSH keys and certificates
- API keys and tokens
- Company-specific information

## ⚙️ Environment-Specific Configurations

### Creating Environment Configs

For different environments (work, personal, etc.), create override files:

```bash
# Work environment
mkdir -p config/overrides
cat > config/overrides/work.yaml << EOF
user:
  email: "work@company.com"
modules:
  enabled:
    - corporate-vpn
    - company-tools
EOF

# Personal environment
cat > config/overrides/personal.yaml << EOF
user:
  email: "personal@gmail.com"
modules:
  enabled:
    - media-tools
    - gaming-setup
EOF
```

### Applying Environment Configs

```bash
# Interactive interface (recommended)
./dotfiles.sh  # Choose your environment during setup

# Direct script access
./scripts/install.sh --override config/overrides/work.yaml
./scripts/install.sh --override config/overrides/personal.yaml
```

## 🛡️ Protected Files & Patterns

The following files are automatically ignored by git to prevent personal information leaks:

- `config/*.backup*` - All backup files
- `config/user.yaml*` - User configuration files
- `config/*-personal.*` - Personal configuration files
- `config/*-private.*` - Private configuration files
- `~/.aliases_work` - Work-specific aliases
- Any file matching `**/my-*`, `**/personal-*`, `**/private-*`

## 🤝 Contributing Safely

When contributing to this repository:

1. **Never include real personal information** in commits
2. **Use placeholder values** like `[YOUR_NAME]`, `[YOUR_EMAIL]`
3. **Test with template files** before submitting
4. **Verify `.gitignore` patterns** are working correctly

See `CONTRIBUTING.md` for complete contribution guidelines.

## 🆘 Getting Help

- **Interactive Help**: `./dotfiles.sh` → "Help & Documentation"
- **Built-in Help**: `./scripts/install.sh --help`
- **Preview Changes**: `./scripts/install.sh --dry-run --verbose`
- **Documentation**: Check the `docs/` directory
- **Issues**: Report problems on GitHub
