#!/bin/bash

# Enterprise Monitoring System
# Version: 1.0.0
# Comprehensive monitoring and health checks

# ============================================================================
# MONITORING CONFIGURATION
# ============================================================================

MONITORING_CONFIG_FILE="$HOME/.config/power-manager-monitoring.conf"
METRICS_DIR="/var/lib/power-manager/metrics"
METRICS_FILE="$METRICS_DIR/power-metrics.json"
HEALTH_CHECK_INTERVAL=300  # 5 minutes
METRICS_INTERVAL=60        # 1 minute

# ============================================================================
# MONITORING INITIALIZATION
# ============================================================================

init_metrics() {
    # Create metrics directory
    sudo mkdir -p "$METRICS_DIR" 2>/dev/null || true
    sudo chown $USER:$USER "$METRICS_DIR" 2>/dev/null || true
    
    # Initialize monitoring configuration
    init_monitoring_config
    
    # Load configuration
    source "$MONITORING_CONFIG_FILE" 2>/dev/null || true
    
    # Initialize metrics file
    init_metrics_file
}

init_monitoring_config() {
    if [ ! -f "$MONITORING_CONFIG_FILE" ]; then
        cat > "$MONITORING_CONFIG_FILE" << MON_CONF_EOF
# Enterprise Monitoring Configuration
MONITORING_ENABLED=true
METRICS_COLLECTION=true
HEALTH_CHECKS_ENABLED=true
ALERTING_ENABLED=false
METRICS_INTERVAL=60
HEALTH_CHECK_INTERVAL=300
METRICS_RETENTION_DAYS=30

# Alert Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
TEMPERATURE_THRESHOLD=80
BATTERY_LOW_THRESHOLD=20
BATTERY_CRITICAL_THRESHOLD=10

# Monitoring Components
MONITOR_CPU=true
MONITOR_MEMORY=true
MONITOR_DISK=true
MONITOR_TEMPERATURE=true
MONITOR_BATTERY=true
MONITOR_GPU=true
MONITOR_SERVICES=true
MONITOR_PRESETS=true
MON_CONF_EOF
    fi
}

init_metrics_file() {
    if [ ! -f "$METRICS_FILE" ]; then
        cat > "$METRICS_FILE" << METRICS_EOF
{
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "version": "1.0.0",
    "metrics": {
        "system": {},
        "power": {},
        "gpu": {},
        "services": {},
        "presets": {}
    },
    "health": {
        "overall": "unknown",
        "components": {}
    }
}
METRICS_EOF
    fi
}

# ============================================================================
# METRICS COLLECTION FUNCTIONS
# ============================================================================

# Collect system metrics
collect_system_metrics() {
    local metrics=()
    
    # CPU metrics
    if [ "$MONITOR_CPU" = "true" ]; then
        local cpu_usage=$(get_cpu_usage)
        local cpu_temp=$(get_cpu_temperature)
        local cpu_freq=$(get_cpu_frequency)
        
        metrics+=("\"cpu_usage\": $cpu_usage")
        metrics+=("\"cpu_temperature\": \"$cpu_temp\"")
        metrics+=("\"cpu_frequency\": \"$cpu_freq\"")
    fi
    
    # Memory metrics
    if [ "$MONITOR_MEMORY" = "true" ]; then
        local mem_usage=$(get_memory_usage)
        local mem_available=$(get_memory_available)
        
        metrics+=("\"memory_usage\": $mem_usage")
        metrics+=("\"memory_available\": $mem_available")
    fi
    
    # Disk metrics
    if [ "$MONITOR_DISK" = "true" ]; then
        local disk_usage=$(get_disk_usage)
        local disk_io=$(get_disk_io)
        
        metrics+=("\"disk_usage\": $disk_usage")
        metrics+=("\"disk_io\": $disk_io")
    fi
    
    # Temperature metrics
    if [ "$MONITOR_TEMPERATURE" = "true" ]; then
        local temp=$(get_system_temperature)
        metrics+=("\"temperature\": \"$temp\"")
    fi
    
    echo "{$(IFS=,; echo "${metrics[*]}")}"
}

# Collect power metrics
collect_power_metrics() {
    local metrics=()
    
    # Battery metrics
    if [ "$MONITOR_BATTERY" = "true" ]; then
        local battery_level=$(get_battery_level)
        local battery_status=$(get_battery_status)
        local ac_connected=$(get_ac_status)
        
        metrics+=("\"battery_level\": $battery_level")
        metrics+=("\"battery_status\": \"$battery_status\"")
        metrics+=("\"ac_connected\": $ac_connected")
    fi
    
    # Power profile metrics
    local power_profile=$(get_current_power_profile)
    metrics+=("\"power_profile\": \"$power_profile\"")
    
    # TLP metrics
    local tlp_status=$(get_tlp_status)
    metrics+=("\"tlp_status\": \"$tlp_status\"")
    
    echo "{$(IFS=,; echo "${metrics[*]}")}"
}

# Collect GPU metrics
collect_gpu_metrics() {
    local metrics=()
    
    if [ "$MONITOR_GPU" = "true" ]; then
        local gpu_mode=$(get_gpu_mode)
        local gpu_usage=$(get_gpu_usage)
        local gpu_temp=$(get_gpu_temperature)
        
        metrics+=("\"gpu_mode\": \"$gpu_mode\"")
        metrics+=("\"gpu_usage\": $gpu_usage")
        metrics+=("\"gpu_temperature\": \"$gpu_temp\"")
    fi
    
    echo "{$(IFS=,; echo "${metrics[*]}")}"
}

# Collect service metrics
collect_service_metrics() {
    local metrics=()
    
    if [ "$MONITOR_SERVICES" = "true" ]; then
        local services=("power-control-startup.service" "power-control-wake.service" "power-control-monitor.service" "disk-monitor.service")
        
        for service in "${services[@]}"; do
            local status=$(get_service_status "$service")
            metrics+=("\"$service\": \"$status\"")
        done
    fi
    
    echo "{$(IFS=,; echo "${metrics[*]}")}"
}

# Collect preset metrics
collect_preset_metrics() {
    local metrics=()
    
    if [ "$MONITOR_PRESETS" = "true" ]; then
        local current_system=$(get_current_system_preset)
        local current_gpu=$(get_current_gpu_preset)
        local current_composite=$(get_current_composite_preset)
        
        metrics+=("\"current_system_preset\": \"$current_system\"")
        metrics+=("\"current_gpu_preset\": \"$current_gpu\"")
        metrics+=("\"current_composite_preset\": \"$current_composite\"")
    fi
    
    echo "{$(IFS=,; echo "${metrics[*]}")}"
}

# ============================================================================
# HEALTH CHECK FUNCTIONS
# ============================================================================

# Comprehensive health check
comprehensive_health_check() {
    local overall_health="healthy"
    local components=()
    
    # Check system health
    local system_health=$(check_system_health)
    components+=("\"system\": $system_health")
    
    # Check power health
    local power_health=$(check_power_health)
    components+=("\"power\": $power_health")
    
    # Check GPU health
    local gpu_health=$(check_gpu_health)
    components+=("\"gpu\": $gpu_health")
    
    # Check services health
    local services_health=$(check_services_health)
    components+=("\"services\": $services_health")
    
    # Determine overall health
    if echo "$system_health $power_health $gpu_health $services_health" | grep -q "unhealthy"; then
        overall_health="unhealthy"
    elif echo "$system_health $power_health $gpu_health $services_health" | grep -q "degraded"; then
        overall_health="degraded"
    fi
    
    echo "{\"overall\": \"$overall_health\", \"components\": {$(IFS=,; echo "${components[*]}")}}"
}

# Check system health
check_system_health() {
    local health="healthy"
    local issues=()
    
    # Check CPU temperature
    local cpu_temp=$(get_cpu_temperature | sed 's/[^0-9.]//g')
    if [ -n "$cpu_temp" ] && [ "$cpu_temp" -gt "$TEMPERATURE_THRESHOLD" ]; then
        health="degraded"
        issues+=("\"cpu_temperature_high\": $cpu_temp")
    fi
    
    # Check CPU usage
    local cpu_usage=$(get_cpu_usage)
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        health="degraded"
        issues+=("\"cpu_usage_high\": $cpu_usage")
    fi
    
    # Check memory usage
    local mem_usage=$(get_memory_usage)
    if [ "$mem_usage" -gt "$MEMORY_THRESHOLD" ]; then
        health="degraded"
        issues+=("\"memory_usage_high\": $mem_usage")
    fi
    
    # Check disk usage
    local disk_usage=$(get_disk_usage)
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        health="unhealthy"
        issues+=("\"disk_usage_high\": $disk_usage")
    fi
    
    echo "{\"status\": \"$health\", \"issues\": [$(IFS=,; echo "${issues[*]}")]}"
}

# Check power health
check_power_health() {
    local health="healthy"
    local issues=()
    
    # Check battery level
    local battery_level=$(get_battery_level)
    if [ "$battery_level" -lt "$BATTERY_CRITICAL_THRESHOLD" ]; then
        health="unhealthy"
        issues+=("\"battery_critical\": $battery_level")
    elif [ "$battery_level" -lt "$BATTERY_LOW_THRESHOLD" ]; then
        health="degraded"
        issues+=("\"battery_low\": $battery_level")
    fi
    
    # Check TLP status
    local tlp_status=$(get_tlp_status)
    if [ "$tlp_status" != "active" ]; then
        health="degraded"
        issues+=("\"tlp_inactive\": \"$tlp_status\"")
    fi
    
    echo "{\"status\": \"$health\", \"issues\": [$(IFS=,; echo "${issues[*]}")]}"
}

# Check GPU health
check_gpu_health() {
    local health="healthy"
    local issues=()
    
    # Check GPU temperature
    local gpu_temp=$(get_gpu_temperature | sed 's/[^0-9.]//g')
    if [ -n "$gpu_temp" ] && [ "$gpu_temp" -gt "$TEMPERATURE_THRESHOLD" ]; then
        health="degraded"
        issues+=("\"gpu_temperature_high\": $gpu_temp")
    fi
    
    # Check GPU switching tools
    if ! command -v supergfxctl >/dev/null 2>&1 && ! command -v envycontrol >/dev/null 2>&1; then
        health="degraded"
        issues+=("\"gpu_tools_unavailable\": true")
    fi
    
    echo "{\"status\": \"$health\", \"issues\": [$(IFS=,; echo "${issues[*]}")]}"
}

# Check services health
check_services_health() {
    local health="healthy"
    local issues=()
    
    local services=("power-control-startup.service" "power-control-wake.service" "power-control-monitor.service")
    
    for service in "${services[@]}"; do
        local status=$(get_service_status "$service")
        if [ "$status" != "active" ]; then
            health="degraded"
            issues+=("\"$service\": \"$status\"")
        fi
    done
    
    echo "{\"status\": \"$health\", \"issues\": [$(IFS=,; echo "${issues[*]}")]}"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get CPU usage percentage
get_cpu_usage() {
    local usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    echo "${usage:-0}"
}

# Get CPU temperature
get_cpu_temperature() {
    if command -v sensors >/dev/null 2>&1; then
        sensors 2>/dev/null | grep "Package id 0" | awk '{print $4}' | sed 's/+//' || echo "N/A"
    else
        echo "N/A"
    fi
}

# Get CPU frequency
get_cpu_frequency() {
    if [ -f /proc/cpuinfo ]; then
        grep "cpu MHz" /proc/cpuinfo | head -1 | awk '{print $4}' || echo "N/A"
    else
        echo "N/A"
    fi
}

# Get memory usage percentage
get_memory_usage() {
    local usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    echo "${usage:-0}"
}

# Get memory available
get_memory_available() {
    free -h | grep Mem | awk '{print $7}'
}

# Get disk usage percentage
get_disk_usage() {
    local usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "${usage:-0}"
}

# Get disk I/O
get_disk_io() {
    if [ -f /proc/diskstats ]; then
        iostat -x 1 1 | tail -n +4 | head -1 | awk '{print $10}' || echo "0"
    else
        echo "0"
    fi
}

# Get system temperature
get_system_temperature() {
    get_cpu_temperature
}

# Get battery level
get_battery_level() {
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        cat /sys/class/power_supply/BAT0/capacity
    else
        echo "100"
    fi
}

# Get battery status
get_battery_status() {
    if [ -f /sys/class/power_supply/BAT0/status ]; then
        cat /sys/class/power_supply/BAT0/status
    else
        echo "Unknown"
    fi
}

# Get AC status
get_ac_status() {
    if [ -f /sys/class/power_supply/ADP1/online ]; then
        local status=$(cat /sys/class/power_supply/ADP1/online)
        [ "$status" = "1" ] && echo "true" || echo "false"
    else
        echo "false"
    fi
}

# Get current power profile
get_current_power_profile() {
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl get 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Get TLP status
get_tlp_status() {
    if command -v tlp >/dev/null 2>&1; then
        systemctl is-active tlp 2>/dev/null || echo "inactive"
    else
        echo "unavailable"
    fi
}

# Get GPU mode
get_gpu_mode() {
    if command -v supergfxctl >/dev/null 2>&1; then
        supergfxctl -g 2>/dev/null || echo "unknown"
    elif command -v envycontrol >/dev/null 2>&1; then
        envycontrol --query 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Get GPU usage
get_gpu_usage() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Get GPU temperature
get_gpu_temperature() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo "N/A"
    else
        echo "N/A"
    fi
}

# Get service status
get_service_status() {
    local service="$1"
    systemctl is-active "$service" 2>/dev/null || echo "inactive"
}

# Get current system preset
get_current_system_preset() {
    if [ -f "/tmp/power-manager-current-system-preset" ]; then
        cat /tmp/power-manager-current-system-preset
    else
        echo "unknown"
    fi
}

# Get current GPU preset
get_current_gpu_preset() {
    if [ -f "/tmp/power-manager-current-gpu-preset" ]; then
        cat /tmp/power-manager-current-gpu-preset
    else
        echo "unknown"
    fi
}

# Get current composite preset
get_current_composite_preset() {
    if [ -f "/tmp/power-manager-current-composite-preset" ]; then
        cat /tmp/power-manager-current-composite-preset
    else
        echo "unknown"
    fi
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

export -f init_metrics
export -f collect_system_metrics
export -f collect_power_metrics
export -f collect_gpu_metrics
export -f collect_service_metrics
export -f collect_preset_metrics
export -f comprehensive_health_check
export -f check_system_health
export -f check_power_health
export -f check_gpu_health
export -f check_services_health
