# Template System Documentation

The Unified Dotfiles Framework includes a powerful template engine that supports Handlebars-style syntax for dynamic configuration generation. This system allows you to create flexible configuration files that adapt to different environments and user preferences.

## Features

- **Variable Substitution**: Replace placeholders with environment variables or context values
- **Default Values**: Provide fallback values when variables are not set
- **Conditional Logic**: Include or exclude content based on variable values
- **Loop Processing**: Generate repeated content from arrays
- **Template Validation**: Syntax checking for template files
- **Cross-Platform Compatibility**: Works with bash 3.2+ (including macOS default bash)

## Template Syntax

### Variable Substitution

#### Simple Variables
```handlebars
Hello {{USER_NAME}}!
```

#### Variables with Default Values
```handlebars
Editor: {{EDITOR|vim}}
Shell: {{SHELL|bash}}
```

### Conditional Logic

#### Simple If Blocks
```handlebars
{{#if DEBUG}}
Debug mode is enabled
{{/if}}
```

#### If-Else Blocks
```handlebars
{{#if WORK_ENV}}
# Work environment settings
proxy: {{WORK_PROXY}}
{{else}}
# Personal environment settings
proxy: none
{{/if}}
```

### Loop Processing

#### Simple Loops
```handlebars
Plugins:
{{#each PLUGINS}}
- {{this}}
{{/each}}
```

#### Loops with Properties
```handlebars
SSH Hosts:
{{#each SSH_HOSTS}}
Host {{name}}
    HostName {{hostname}}
    User {{user}}
    Port {{port|22}}
{{/each}}
```

## Usage

### Basic Template Processing

```bash
# Source the template system
source core/template_minimal.sh

# Set environment variables
export USER_NAME="John Doe"
export EDITOR="code"

# Process a template string
result="$(process_template_string "Hello {{USER_NAME}}, your editor is {{EDITOR|vim}}")"
echo "$result"
# Output: Hello John Doe, your editor is code
```

### File Template Processing

```bash
# Process a template file
process_template "templates/gitconfig.template" "output/gitconfig" "context.env"
```

### Template Validation

```bash
# Validate template syntax
if validate_template "templates/myconfig.template"; then
    echo "Template is valid"
else
    echo "Template has syntax errors"
fi
```

## Context Files

Context files provide variables for template processing. They support key-value format:

```bash
# context.env
USER_NAME=John Doe
USER_EMAIL=john@example.com
WORK_ENV=true
EDITOR=code

# Array data for loops
PLUGINS_COUNT=3
PLUGINS_0=git
PLUGINS_1=docker
PLUGINS_2=vim

# Complex array data
SSH_HOSTS_COUNT=2
SSH_HOSTS_0=production
SSH_HOSTS_0_name=production
SSH_HOSTS_0_hostname=prod.example.com
SSH_HOSTS_0_user=deploy
SSH_HOSTS_0_port=22

SSH_HOSTS_1=staging
SSH_HOSTS_1_name=staging
SSH_HOSTS_1_hostname=staging.example.com
SSH_HOSTS_1_user=deploy
SSH_HOSTS_1_port=2222
```

## Environment-Specific Templates

The template system supports environment-specific configuration through conditional blocks and variable substitution:

### Platform-Specific Configuration

```handlebars
# Shell configuration
{{#if MACOS}}
# macOS specific settings
export PATH="/opt/homebrew/bin:$PATH"
alias ls="ls -G"
{{/if}}

{{#if LINUX}}
# Linux specific settings
alias ls="ls --color=auto"
{{/if}}
```

### Work vs Personal Environment

```handlebars
# Git configuration
[user]
    name = {{GIT_USER_NAME}}
    {{#if WORK_ENV}}
    email = {{WORK_EMAIL}}
    {{else}}
    email = {{PERSONAL_EMAIL}}
    {{/if}}

{{#if WORK_ENV}}
[url "git@github-work:"]
    insteadOf = git@github.com:
{{/if}}
```

## Advanced Features

### Truthy Value Evaluation

The template system evaluates variables as truthy or falsy:

- **Truthy**: `"true"`, `"yes"`, `"1"`, `"on"`, `"enabled"`, any non-empty string
- **Falsy**: `"false"`, `"no"`, `"0"`, `"off"`, `"disabled"`, empty string

### Template Caching

Templates are cached for performance:

```bash
# Get cache directory
cache_dir="$(get_template_cache_dir)"

# Clear template cache
clear_template_cache
```

## Integration with Module System

Templates integrate seamlessly with the module system:

```bash
# In a module's install.sh
source "$DOTFILES_ROOT/core/template_minimal.sh"

# Process module template
process_template \
    "$MODULE_DIR/config/gitconfig.template" \
    "$HOME/.gitconfig" \
    "$MODULE_DIR/context/user.env"
```

## Error Handling

The template system includes comprehensive error handling:

- **Syntax Validation**: Checks for unmatched braces and blocks
- **File Validation**: Ensures template and context files exist
- **Graceful Degradation**: Leaves placeholders for missing variables

## Examples

### Git Configuration Template

```handlebars
# Git Configuration Template
[user]
    name = {{GIT_USER_NAME}}
    email = {{GIT_USER_EMAIL}}
    {{#if GIT_SIGNING_KEY}}
    signingkey = {{GIT_SIGNING_KEY}}
    {{/if}}

[core]
    editor = {{GIT_EDITOR|vim}}
    {{#if WORK_ENV}}
    autocrlf = true
    {{else}}
    autocrlf = input
    {{/if}}

{{#if WORK_ENV}}
[url "git@github-work:"]
    insteadOf = git@github.com:
{{/if}}
```

### SSH Configuration Template

```handlebars
# SSH Configuration Template
Host *
    ServerAliveInterval {{SSH_KEEPALIVE|60}}
    {{#if SSH_COMPRESSION}}
    Compression yes
    {{/if}}

{{#each SSH_HOSTS}}
Host {{name}}
    HostName {{hostname}}
    User {{user}}
    Port {{port|22}}
    {{#if key}}
    IdentityFile {{key}}
    {{/if}}
{{/each}}
```

### Shell Configuration Template

```handlebars
# Shell Configuration Template
export DOTFILES_ENV="{{DOTFILES_ENV|personal}}"

{{#if WORK_ENV}}
# Work environment
export COMPANY="{{COMPANY_NAME}}"
alias vpn="sudo openconnect {{VPN_SERVER}}"
{{/if}}

# History configuration
HISTSIZE={{HISTSIZE|10000}}
SAVEHIST={{SAVEHIST|10000}}

# Load plugins
{{#each SHELL_PLUGINS}}
source ~/.config/shell/plugins/{{this}}.sh
{{/each}}
```

## Best Practices

1. **Use Descriptive Variable Names**: Choose clear, consistent variable names
2. **Provide Default Values**: Always provide sensible defaults for optional variables
3. **Validate Templates**: Use `validate_template` before processing
4. **Document Context**: Clearly document required variables and their purposes
5. **Test Across Environments**: Test templates in different environments and configurations
6. **Keep Templates Simple**: Avoid overly complex logic in templates
7. **Use Environment-Specific Context**: Create separate context files for different environments

## Troubleshooting

### Common Issues

1. **Unmatched Braces**: Ensure all `{{` have matching `}}`
2. **Unmatched Blocks**: Ensure all `{{#if}}` have matching `{{/if}}`
3. **Missing Variables**: Check that required variables are set in environment or context
4. **Case Sensitivity**: Variable names are case-sensitive
5. **Special Characters**: Avoid special characters in variable names

### Debugging

Enable debug logging to troubleshoot template processing:

```bash
# Enable debug output
export LOG_LEVEL=4

# Process template with debug information
process_template "template.txt" "output.txt" "context.env"
```

## API Reference

### Functions

- `init_template_system()`: Initialize the template system
- `process_template_string(template, [context_file])`: Process a template string
- `process_template(template_file, output_file, [context_file])`: Process a template file
- `validate_template(template_file)`: Validate template syntax
- `get_template_cache_dir()`: Get the template cache directory
- `clear_template_cache()`: Clear the template cache
- `is_truthy(value)`: Check if a value is truthy
- `get_env_var(var_name, [default])`: Get environment variable with default

### Variables

- `TEMPLATE_CACHE_DIR`: Directory for template cache files

This template system provides a powerful foundation for creating dynamic, environment-aware configuration files in the Unified Dotfiles Framework.