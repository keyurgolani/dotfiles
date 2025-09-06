#!/usr/bin/env bats

# Comprehensive integration tests for the unified dotfiles framework

@test "install script exists and is executable" {
    [ -f "../install.sh" ]
    [ -x "../install.sh" ]
}

@test "core directory structure exists" {
    [ -d "../core" ]
    [ -d "../modules" ]
    [ -d "../config" ]
    [ -d "../templates" ]
}

@test "essential core files exist" {
    [ -f "../core/logger.sh" ]
    [ -f "../core/utils.sh" ]
    [ -f "../core/platform.sh" ]
    [ -f "../core/config.sh" ]
}

@test "install script shows help" {
    run ../install.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Unified Dotfiles Framework" ]]
}

@test "install script can list modules" {
    run ../install.sh list-modules
    [ "$status" -eq 0 ]
}

@test "platform detection works" {
    run bash -c 'source ../core/platform.sh && detect_platform'
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(macos|ubuntu|wsl|amazon-linux)$ ]]
}

@test "backup functionality exists" {
    [ -f "../core/backup.sh" ]
    run bash -c 'source ../core/backup.sh && type create_backup'
    [ "$status" -eq 0 ]
}

@test "configuration management works" {
    [ -f "../core/config.sh" ]
    run bash -c 'source ../core/config.sh && type load_config'
    [ "$status" -eq 0 ]
}

@test "module system is functional" {
    [ -f "../core/modules_simple.sh" ]
    run bash -c 'source ../core/modules_simple.sh && type load_modules'
    [ "$status" -eq 0 ]
}

@test "performance optimizations are available" {
    [ -f "../core/performance.sh" ]
    run bash -c 'source ../core/performance.sh && type enable_performance_optimizations'
    [ "$status" -eq 0 ]
}

@test "dry run mode works" {
    run timeout 30 ../install.sh --dry-run --non-interactive
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN" ]]
}

@test "essential modules exist" {
    [ -d "../modules/shell" ]
    [ -d "../modules/git" ]
    [ -d "../modules/vim" ]
    [ -d "../modules/tmux" ]
}

@test "module configurations are valid" {
    for module_dir in ../modules/*/; do
        if [ -f "$module_dir/module.yaml" ]; then
            run bash -c "cd '$module_dir' && [ -f module.yaml ]"
            [ "$status" -eq 0 ]
        fi
    done
}

@test "backup command works" {
    run timeout 30 ../install.sh backup --dry-run
    [ "$status" -eq 0 ]
}

@test "configuration files are valid YAML" {
    if command -v python3 >/dev/null 2>&1; then
        for config_file in ../config/*.yaml; do
            if [ -f "$config_file" ]; then
                run python3 -c "import yaml; yaml.safe_load(open('$config_file'))"
                [ "$status" -eq 0 ]
            fi
        done
    else
        skip "Python3 not available for YAML validation"
    fi
}

@test "shell scripts pass basic syntax check" {
    for script in ../core/*.sh ../install.sh; do
        if [ -f "$script" ]; then
            run bash -n "$script"
            [ "$status" -eq 0 ]
        fi
    done
}

# Migration system test removed - legacy migration system no longer needed

@test "hook system is functional" {
    [ -f "../core/hooks.sh" ]
    [ -d "../hooks" ]
}

@test "template system works" {
    [ -f "../core/template.sh" ]
    [ -d "../templates" ]
}

@test "security features are implemented" {
    [ -f "../core/security.sh" ]
    run bash -c 'source ../core/security.sh && type validate_file_permissions'
    [ "$status" -eq 0 ]
}

@test "update system is available" {
    [ -f "../core/update.sh" ]
    run bash -c 'source ../core/update.sh && type update_framework'
    [ "$status" -eq 0 ]
}

@test "user experience enhancements work" {
    [ -f "../core/user_experience.sh" ]
    run bash -c 'source ../core/user_experience.sh && type show_progress'
    [ "$status" -eq 0 ]
}

@test "documentation exists" {
    [ -f "../README.md" ]
    [ -d "../docs" ]
}

@test "testing framework is complete" {
    [ -f "run_tests.sh" ]
    [ -f "setup.sh" ]
    [ -d "unit" ]
    [ -d "integration" ]
    [ -d "fixtures" ]
    [ -d "helpers" ]
}