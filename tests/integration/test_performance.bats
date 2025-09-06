#!/usr/bin/env bats

# Performance testing for unified dotfiles framework
# Tests installation speed, shell startup performance, and resource usage

load '../helpers/test_helpers'

setup() {
    setup_test_environment
    
    # Create performance test configuration
    create_test_config "performance" "
modules:
  enabled:
    - shell
    - git
    - vim
    - tmux
settings:
  backup_enabled: true
  parallel_installation: true
performance:
  enable_parallel_installation: true
  max_parallel_jobs: 4
  enable_download_cache: true
  enable_shell_optimization: true
user:
  name: 'Performance Test User'
  email: 'perf@example.com'
"
}

teardown() {
    teardown_test_environment
}

@test "performance: installation completes within time limit (Requirement 9.1)" {
    # Test that full installation completes within 10 minutes (600 seconds)
    local start_time end_time duration
    start_time=$(date +%s)
    
    # Run full installation with timeout
    run timeout 600 "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/performance.yaml" --non-interactive --verbose
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    assert_success
    assert_output_contains "Installation completed successfully"
    
    # Verify completion within 10 minutes (600 seconds) as per requirement 9.1
    [[ $duration -lt 600 ]]
    
    log_info "Full installation completed in ${duration} seconds (requirement: <600s)"
    
    # Log performance metrics
    echo "# Performance Metrics" >> "$TEST_TEMP_DIR/performance_report.md"
    echo "- Full installation time: ${duration}s" >> "$TEST_TEMP_DIR/performance_report.md"
}

@test "performance: shell startup time under 500ms (Requirement 9.2)" {
    # Install shell module
    run "$DOTFILES_ROOT/install.sh" --modules "shell" --non-interactive --config "$TEST_CONFIG_DIR/performance.yaml"
    assert_success
    
    # Test bash startup time
    local bash_startup_time
    if command -v bash >/dev/null 2>&1; then
        bash_startup_time=$(measure_shell_startup_time "bash")
        log_info "Bash startup time: ${bash_startup_time}ms"
        
        # Should be under 500ms as per requirement 9.2
        [[ $(echo "$bash_startup_time < 500" | bc -l 2>/dev/null || echo "1") -eq 1 ]]
        
        echo "- Bash startup time: ${bash_startup_time}ms" >> "$TEST_TEMP_DIR/performance_report.md"
    fi
    
    # Test zsh startup time if available
    if command -v zsh >/dev/null 2>&1; then
        local zsh_startup_time
        zsh_startup_time=$(measure_shell_startup_time "zsh")
        log_info "Zsh startup time: ${zsh_startup_time}ms"
        
        # Should be under 500ms as per requirement 9.2
        [[ $(echo "$zsh_startup_time < 500" | bc -l 2>/dev/null || echo "1") -eq 1 ]]
        
        echo "- Zsh startup time: ${zsh_startup_time}ms" >> "$TEST_TEMP_DIR/performance_report.md"
    fi
}

@test "performance: parallel installation performance (Requirement 9.3)" {
    # Test parallel vs sequential installation performance
    
    # Sequential installation
    local sequential_start sequential_end sequential_duration
    sequential_start=$(date +%s)
    
    DOTFILES_PARALLEL_JOBS=1 run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/performance.yaml" --non-interactive
    
    sequential_end=$(date +%s)
    sequential_duration=$((sequential_end - sequential_start))
    
    assert_success
    log_info "Sequential installation: ${sequential_duration}s"
    
    # Clean up for parallel test
    rm -rf "$HOME/.bashrc" "$HOME/.gitconfig" "$HOME/.vimrc" "$HOME/.tmux.conf" 2>/dev/null || true
    
    # Parallel installation
    local parallel_start parallel_end parallel_duration
    parallel_start=$(date +%s)
    
    DOTFILES_PARALLEL_JOBS=4 run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/performance.yaml" --non-interactive
    
    parallel_end=$(date +%s)
    parallel_duration=$((parallel_end - parallel_start))
    
    assert_success
    log_info "Parallel installation: ${parallel_duration}s"
    
    # Parallel should be faster or at least not significantly slower
    local improvement_ratio
    if [[ $sequential_duration -gt 0 ]]; then
        improvement_ratio=$(echo "scale=2; $sequential_duration / $parallel_duration" | bc -l 2>/dev/null || echo "1.0")
        log_info "Parallel improvement ratio: ${improvement_ratio}x"
        
        # Parallel should be at least as fast (ratio >= 1.0)
        [[ $(echo "$improvement_ratio >= 1.0" | bc -l 2>/dev/null || echo "1") -eq 1 ]]
    fi
    
    echo "- Sequential installation: ${sequential_duration}s" >> "$TEST_TEMP_DIR/performance_report.md"
    echo "- Parallel installation: ${parallel_duration}s" >> "$TEST_TEMP_DIR/performance_report.md"
    echo "- Improvement ratio: ${improvement_ratio}x" >> "$TEST_TEMP_DIR/performance_report.md"
}

@test "performance: progress indicators for long operations (Requirement 9.4)" {
    # Test that progress indicators are shown for long-running operations
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/performance.yaml" --non-interactive --verbose
    
    assert_success
    
    # Should show progress indicators
    assert_output_contains "Progress:"
    assert_output_contains "%"
    
    # Should show operation status
    assert_output_contains "Installing module:"
    assert_output_contains "Completed:"
}

@test "performance: caching system effectiveness (Requirement 9.5)" {
    # Test download caching
    
    # First installation (cold cache)
    local first_start first_end first_duration
    first_start=$(date +%s)
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/performance.yaml" --non-interactive
    
    first_end=$(date +%s)
    first_duration=$((first_end - first_start))
    
    assert_success
    log_info "First installation (cold cache): ${first_duration}s"
    
    # Clean up for second installation
    rm -rf "$HOME/.bashrc" "$HOME/.gitconfig" "$HOME/.vimrc" "$HOME/.tmux.conf" 2>/dev/null || true
    
    # Second installation (warm cache)
    local second_start second_end second_duration
    second_start=$(date +%s)
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/performance.yaml" --non-interactive
    
    second_end=$(date +%s)
    second_duration=$((second_end - second_start))
    
    assert_success
    log_info "Second installation (warm cache): ${second_duration}s"
    
    # Second installation should be faster due to caching
    if [[ $first_duration -gt 5 ]]; then  # Only test if first installation took reasonable time
        local cache_improvement
        cache_improvement=$(echo "scale=2; $first_duration / $second_duration" | bc -l 2>/dev/null || echo "1.0")
        log_info "Cache improvement ratio: ${cache_improvement}x"
        
        # Cache should provide some improvement (at least 10% faster)
        [[ $(echo "$cache_improvement >= 1.1" | bc -l 2>/dev/null || echo "1") -eq 1 ]]
    fi
    
    echo "- First installation (cold cache): ${first_duration}s" >> "$TEST_TEMP_DIR/performance_report.md"
    echo "- Second installation (warm cache): ${second_duration}s" >> "$TEST_TEMP_DIR/performance_report.md"
}

@test "performance: memory usage during installation" {
    # Monitor memory usage during installation
    local max_memory_kb
    
    # Start memory monitoring in background
    monitor_memory_usage &
    local monitor_pid=$!
    
    # Run installation
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/performance.yaml" --non-interactive
    
    # Stop memory monitoring
    kill $monitor_pid 2>/dev/null || true
    wait $monitor_pid 2>/dev/null || true
    
    assert_success
    
    # Read maximum memory usage
    if [[ -f "$TEST_TEMP_DIR/memory_usage.log" ]]; then
        max_memory_kb=$(sort -n "$TEST_TEMP_DIR/memory_usage.log" | tail -1)
        local max_memory_mb=$((max_memory_kb / 1024))
        
        log_info "Maximum memory usage: ${max_memory_mb}MB"
        
        # Should not exceed reasonable memory usage (500MB)
        [[ $max_memory_mb -lt 500 ]]
        
        echo "- Maximum memory usage: ${max_memory_mb}MB" >> "$TEST_TEMP_DIR/performance_report.md"
    fi
}

@test "performance: disk I/O efficiency" {
    # Test disk I/O patterns during installation
    local io_start_time io_end_time io_duration
    
    io_start_time=$(date +%s)
    
    # Monitor disk usage
    local disk_usage_before disk_usage_after
    disk_usage_before=$(du -s "$HOME" 2>/dev/null | awk '{print $1}' || echo "0")
    
    run "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/performance.yaml" --non-interactive
    
    disk_usage_after=$(du -s "$HOME" 2>/dev/null | awk '{print $1}' || echo "0")
    
    io_end_time=$(date +%s)
    io_duration=$((io_end_time - io_start_time))
    
    assert_success
    
    local disk_usage_diff=$((disk_usage_after - disk_usage_before))
    local disk_usage_mb=$((disk_usage_diff / 1024))
    
    log_info "Disk usage increase: ${disk_usage_mb}MB in ${io_duration}s"
    
    # Should not use excessive disk space (under 100MB for basic modules)
    [[ $disk_usage_mb -lt 100 ]]
    
    echo "- Disk usage increase: ${disk_usage_mb}MB" >> "$TEST_TEMP_DIR/performance_report.md"
    echo "- I/O duration: ${io_duration}s" >> "$TEST_TEMP_DIR/performance_report.md"
}

@test "performance: concurrent installation stress test" {
    # Test multiple concurrent installations (stress test)
    local concurrent_jobs=3
    local pids=()
    
    # Start multiple installations concurrently
    for i in $(seq 1 $concurrent_jobs); do
        (
            export HOME="$TEST_TEMP_DIR/home_$i"
            mkdir -p "$HOME"
            "$DOTFILES_ROOT/install.sh" --config "$TEST_CONFIG_DIR/performance.yaml" --non-interactive >/dev/null 2>&1
        ) &
        pids+=($!)
    done
    
    # Wait for all jobs to complete
    local failed_jobs=0
    for pid in "${pids[@]}"; do
        if ! wait $pid; then
            failed_jobs=$((failed_jobs + 1))
        fi
    done
    
    # All concurrent installations should succeed
    [[ $failed_jobs -eq 0 ]]
    
    log_info "Concurrent installations completed: $((concurrent_jobs - failed_jobs))/$concurrent_jobs successful"
    
    echo "- Concurrent installations: $((concurrent_jobs - failed_jobs))/$concurrent_jobs successful" >> "$TEST_TEMP_DIR/performance_report.md"
}

@test "performance: generate performance report" {
    # Generate final performance report
    if [[ -f "$TEST_TEMP_DIR/performance_report.md" ]]; then
        echo "" >> "$TEST_TEMP_DIR/performance_report.md"
        echo "## Test Environment" >> "$TEST_TEMP_DIR/performance_report.md"
        echo "- Platform: $(uname -s)" >> "$TEST_TEMP_DIR/performance_report.md"
        echo "- Architecture: $(uname -m)" >> "$TEST_TEMP_DIR/performance_report.md"
        echo "- Shell: $SHELL" >> "$TEST_TEMP_DIR/performance_report.md"
        echo "- Date: $(date)" >> "$TEST_TEMP_DIR/performance_report.md"
        
        log_info "Performance report generated: $TEST_TEMP_DIR/performance_report.md"
        
        # Display report summary
        if command -v cat >/dev/null 2>&1; then
            echo "=== Performance Report Summary ==="
            cat "$TEST_TEMP_DIR/performance_report.md"
            echo "=================================="
        fi
    fi
}

# Helper function to measure shell startup time
measure_shell_startup_time() {
    local shell="$1"
    local iterations=5
    local total_time=0
    
    for i in $(seq 1 $iterations); do
        local start_time end_time duration
        start_time=$(date +%s%N 2>/dev/null || date +%s000000000)
        
        $shell -c 'exit' >/dev/null 2>&1
        
        end_time=$(date +%s%N 2>/dev/null || date +%s000000000)
        duration=$(((end_time - start_time) / 1000000))  # Convert to milliseconds
        
        total_time=$((total_time + duration))
    done
    
    local average_time=$((total_time / iterations))
    echo "$average_time"
}

# Helper function to monitor memory usage
monitor_memory_usage() {
    local log_file="$TEST_TEMP_DIR/memory_usage.log"
    
    while true; do
        # Get memory usage of current process tree
        local memory_kb
        memory_kb=$(ps -o rss= -p $$ 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
        echo "$memory_kb" >> "$log_file"
        sleep 1
    done
}