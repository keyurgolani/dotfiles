#!/bin/bash

# Unified Dotfiles Framework - Performance Optimization
# Handles performance monitoring and optimization features

# Performance tracking variables
PERFORMANCE_START_TIME=""
PERFORMANCE_METRICS=()
PROGRESS_CURRENT=0
PROGRESS_TOTAL=0
PROGRESS_ENABLED=true

# Initialize performance tracking
init_performance_tracking() {
    PERFORMANCE_START_TIME=$(date +%s)
    log_debug "Performance tracking initialized"
}

# Initialize progress tracking
init_progress_tracking() {
    local total_steps="$1"
    local enabled="${2:-true}"
    
    PROGRESS_TOTAL="$total_steps"
    PROGRESS_CURRENT=0
    PROGRESS_ENABLED="$enabled"
    
    if [[ "$PROGRESS_ENABLED" == "true" ]]; then
        log_debug "Progress tracking initialized: 0/$total_steps"
    fi
}

# Update progress
update_progress() {
    local message="${1:-Processing...}"
    
    ((PROGRESS_CURRENT++))
    
    if [[ "$PROGRESS_ENABLED" == "true" ]]; then
        show_progress "$PROGRESS_CURRENT" "$PROGRESS_TOTAL" 50 "$message"
    fi
}

# Finish progress display (ensures clean line for next output)
finish_progress() {
    if [[ "$PROGRESS_ENABLED" == "true" ]]; then
        clear_progress_line
    fi
}

# Record performance metric
record_metric() {
    local metric_name="$1"
    local metric_value="$2"
    local timestamp="${3:-$(date +%s)}"
    
    PERFORMANCE_METRICS+=("$timestamp:$metric_name:$metric_value")
    log_debug "Recorded metric: $metric_name = $metric_value"
}

# Show performance summary
show_performance_summary() {
    if [[ -z "$PERFORMANCE_START_TIME" ]]; then
        return 0
    fi
    
    local end_time
    end_time=$(date +%s)
    local total_time=$((end_time - PERFORMANCE_START_TIME))
    
    echo ""
    log_info "⚡ PERFORMANCE SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo "Total execution time: ${total_time}s"
    
    if [[ ${#PERFORMANCE_METRICS[@]} -gt 0 ]]; then
        echo ""
        echo "Detailed metrics:"
        for metric in "${PERFORMANCE_METRICS[@]}"; do
            IFS=':' read -r timestamp name value <<< "$metric"
            echo "  $name: $value"
        done
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Batch module installation with performance optimization
install_modules_batch() {
    local modules=("$@")
    local max_parallel_jobs
    max_parallel_jobs=$(get_config_value "performance.max_parallel_jobs" "4")
    
    local enable_parallel
    enable_parallel=$(get_config_value "performance.enable_parallel_installation" "true")
    
    if [[ "$enable_parallel" == "true" && ${#modules[@]} -gt 1 ]]; then
        install_modules_parallel "${modules[@]}"
    else
        install_modules_sequential "${modules[@]}"
    fi
}

# Install modules in parallel
install_modules_parallel() {
    local modules=("$@")
    local max_jobs
    max_jobs=$(get_config_value "performance.max_parallel_jobs" "4")
    
    log_info "Installing ${#modules[@]} modules in parallel (max $max_jobs jobs)"
    
    local pids=()
    local job_count=0
    
    for module in "${modules[@]}"; do
        # Wait if we've reached max parallel jobs
        while [[ $job_count -ge $max_jobs ]]; do
            wait_for_job_completion "pids" "job_count"
        done
        
        # Start module installation in background
        (
            update_progress "Installing $module"
            install_module "$module" "$DRY_RUN"
        ) &
        
        pids+=($!)
        ((job_count++))
    done
    
    # Wait for all remaining jobs to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Clear progress line before final output
    if [[ "$(type -t clear_progress_line)" == "function" ]]; then
        clear_progress_line
    fi
    
    log_debug "Parallel installation completed"
}

# Install modules sequentially
install_modules_sequential() {
    local modules=("$@")
    
    log_info "Installing ${#modules[@]} modules sequentially"
    
    for module in "${modules[@]}"; do
        update_progress "Installing $module"
        
        if ! install_module "$module" "$DRY_RUN"; then
            log_error "Failed to install module: $module"
            return 1
        fi
    done
    
    # Clear progress line before final output
    if [[ "$(type -t clear_progress_line)" == "function" ]]; then
        clear_progress_line
    fi
    
    log_debug "Sequential installation completed"
}

# Wait for job completion
wait_for_job_completion() {
    local pids_var_name="$1"
    local job_count_var_name="$2"
    
    # Get current values using eval (compatible with older bash)
    local current_pids=()
    eval "current_pids=(\"\${${pids_var_name}[@]:-}\")"
    local current_job_count
    eval "current_job_count=\${${job_count_var_name}:-0}"
    
    local new_pids=()
    
    # Check if we have any PIDs to process
    if [[ ${#current_pids[@]} -eq 0 ]]; then
        return 0
    fi
    
    for pid in "${current_pids[@]}"; do
        if ! kill -0 "$pid" 2>/dev/null; then
            # Process completed, decrement counter
            ((current_job_count--))
        else
            # Process still running, keep it
            new_pids+=("$pid")
        fi
    done
    
    # Update the arrays using eval
    if [[ ${#new_pids[@]} -gt 0 ]]; then
        eval "${pids_var_name}=(\"\${new_pids[@]}\")"
    else
        eval "${pids_var_name}=()"
    fi
    eval "${job_count_var_name}=$current_job_count"
    
    # Sleep briefly to avoid busy waiting
    sleep 0.1
}

# Enhanced installation summary with performance metrics
show_installation_summary_enhanced() {
    local installed_modules=("$@")
    
    # Show basic summary first
    show_installation_summary "${installed_modules[@]}"
    
    # Add performance information if verbose mode is enabled
    if [[ "$VERBOSE" == "true" ]]; then
        show_performance_summary
    fi
}