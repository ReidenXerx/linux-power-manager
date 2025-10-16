#!/bin/bash

# Modular Power Management System
# Version: 1.0.0
# Separates system presets (TLP, hardware) from GPU presets for maximum flexibility

# ============================================================================
# MODULAR CONFIGURATION
# ============================================================================

MODULAR_CONFIG_FILE="$HOME/.config/modular-power.conf"
SYSTEM_PRESETS_FILE="$HOME/.config/system-presets.conf"
GPU_PRESETS_FILE="$HOME/.config/gpu-presets.conf"

# Preset directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_PRESETS_DIR="$SCRIPT_DIR/../presets/system-presets"
GPU_PRESETS_DIR="$SCRIPT_DIR/../presets/gpu-presets"

# ============================================================================
# MODULAR INITIALIZATION
# ============================================================================

init_modular_system() {
    if command -v log_info >/dev/null 2>&1; then
        log_info "Initializing modular power management system..." "MODULAR"
    else
        echo "Initializing modular power management system..."
    fi
    
    # Create config directory
    mkdir -p "$HOME/.config"
    
    # Initialize modular configuration
    init_modular_configuration
    
    # Initialize system presets
    init_system_presets
    
    # Initialize GPU presets
    init_gpu_presets
    
    if command -v log_success >/dev/null 2>&1; then
        log_success "Modular power management system initialized" "MODULAR"
    else
        echo "Modular power management system initialized"
    fi
}

# Initialize modular configuration
init_modular_configuration() {
    if [ ! -f "$MODULAR_CONFIG_FILE" ]; then
        cat > "$MODULAR_CONFIG_FILE" << MODULAR_CONF_EOF
# Modular Power Management Configuration
# Version: 1.0.0

# System Management
SYSTEM_POWER_MANAGEMENT=true
GPU_POWER_MANAGEMENT=true
AUTONOMOUS_SYSTEM_GPU=true

# Default Presets
DEFAULT_SYSTEM_PRESET=balanced
DEFAULT_GPU_PRESET=hybrid

# Auto-Application
AUTO_APPLY_ON_STARTUP=true
AUTO_APPLY_ON_WAKE=true
AUTO_APPLY_ON_AC_CHANGE=true

# Logging
MODULAR_LOGGING_ENABLED=true
LOG_LEVEL=6

# Validation
VALIDATION_ENABLED=true
PRESET_VALIDATION=true
CONFIG_VALIDATION=true

# Monitoring
MONITORING_ENABLED=true
PRESET_MONITORING=true
PERFORMANCE_MONITORING=true
MODULAR_CONF_EOF
    fi
    
    source "$MODULAR_CONFIG_FILE"
}

# Initialize system presets (TLP, hardware, power profiles)
init_system_presets() {
    if [ ! -f "$SYSTEM_PRESETS_FILE" ]; then
        cat > "$SYSTEM_PRESETS_FILE" << SYSTEM_PRESETS_EOF
# System Power Presets Configuration
# Format: PRESET_NAME_SETTING=value
# These presets control TLP, power profiles, WiFi, disk, and other hardware

# Ultra Eco - Maximum power savings
ULTRA_ECO_TLP_MODE=bat
ULTRA_ECO_POWER_PROFILE=power-saver
ULTRA_ECO_WIFI_MODE=aggressive
ULTRA_ECO_DISK_MODE=aggressive
ULTRA_ECO_DESCRIPTION="Maximum power savings for all hardware components"
ULTRA_ECO_BATTERY_TARGET="8-12+ hours"
ULTRA_ECO_PERFORMANCE_LEVEL="1/10"

# Eco - Good power savings
ECO_TLP_MODE=bat
ECO_POWER_PROFILE=power-saver
ECO_WIFI_MODE=balanced
ECO_DISK_MODE=balanced
ECO_DESCRIPTION="Good power savings with reasonable performance"
ECO_BATTERY_TARGET="6-8 hours"
ECO_PERFORMANCE_LEVEL="3/10"

# Balanced - Default balanced mode
BALANCED_TLP_MODE=auto
BALANCED_POWER_PROFILE=balanced
BALANCED_WIFI_MODE=balanced
BALANCED_DISK_MODE=balanced
BALANCED_DESCRIPTION="Balanced power and performance"
BALANCED_BATTERY_TARGET="4-6 hours"
BALANCED_PERFORMANCE_LEVEL="5/10"

# Performance - High performance
PERFORMANCE_TLP_MODE=ac
PERFORMANCE_POWER_PROFILE=performance
PERFORMANCE_WIFI_MODE=performance
PERFORMANCE_DISK_MODE=performance
PERFORMANCE_DESCRIPTION="High performance for demanding tasks"
PERFORMANCE_BATTERY_TARGET="2-4 hours"
PERFORMANCE_PERFORMANCE_LEVEL="8/10"

# Gaming - Optimized for gaming
GAMING_TLP_MODE=ac
GAMING_POWER_PROFILE=performance
GAMING_WIFI_MODE=performance
GAMING_DISK_MODE=performance
GAMING_DESCRIPTION="Optimized for gaming and intensive workloads"
GAMING_BATTERY_TARGET="1-3 hours"
GAMING_PERFORMANCE_LEVEL="9/10"

# Intel Arc Optimized - Intel Arc Graphics optimized
INTEL_ARC_OPTIMIZED_TLP_MODE=ac
INTEL_ARC_OPTIMIZED_POWER_PROFILE=performance
INTEL_ARC_OPTIMIZED_WIFI_MODE=performance
INTEL_ARC_OPTIMIZED_DISK_MODE=performance
INTEL_ARC_OPTIMIZED_DESCRIPTION="Intel Arc Graphics optimized for maximum performance"
INTEL_ARC_OPTIMIZED_BATTERY_TARGET="3-5 hours"
INTEL_ARC_OPTIMIZED_PERFORMANCE_LEVEL="9/10"

# Intel Hybrid Performance - Intel hybrid architecture optimized
INTEL_HYBRID_PERFORMANCE_TLP_MODE=ac
INTEL_HYBRID_PERFORMANCE_POWER_PROFILE=performance
INTEL_HYBRID_PERFORMANCE_WIFI_MODE=performance
INTEL_HYBRID_PERFORMANCE_DISK_MODE=performance
INTEL_HYBRID_PERFORMANCE_DESCRIPTION="Intel hybrid architecture optimized for P-Core/E-Core balance"
INTEL_HYBRID_PERFORMANCE_BATTERY_TARGET="4-6 hours"
INTEL_HYBRID_PERFORMANCE_PERFORMANCE_LEVEL="8/10"

# Intel Arc Creative - Intel Arc Graphics creative workloads

# Intel Eco - Intel optimized eco mode
INTEL_ECO_TLP_MODE=bat
INTEL_ECO_POWER_PROFILE=power-saver
INTEL_ECO_WIFI_MODE=aggressive
INTEL_ECO_DISK_MODE=aggressive
INTEL_ECO_DESCRIPTION="Intel optimized eco mode with good performance and power savings"
INTEL_ECO_BATTERY_TARGET="6-8 hours"
INTEL_ECO_PERFORMANCE_LEVEL="4/10"
INTEL_ARC_CREATIVE_TLP_MODE=ac
INTEL_ARC_CREATIVE_POWER_PROFILE=performance
INTEL_ARC_CREATIVE_WIFI_MODE=performance
INTEL_ARC_CREATIVE_DISK_MODE=performance
INTEL_ARC_CREATIVE_DESCRIPTION="Intel Arc Graphics optimized for content creation and creative workloads"
INTEL_ARC_CREATIVE_BATTERY_TARGET="2-4 hours"
INTEL_ARC_CREATIVE_PERFORMANCE_LEVEL="9/10"

# Work - Optimized for productivity
WORK_TLP_MODE=balanced
WORK_POWER_PROFILE=balanced
WORK_WIFI_MODE=balanced
WORK_DISK_MODE=balanced
WORK_DESCRIPTION="Optimized for office work and productivity"
WORK_BATTERY_TARGET="5-7 hours"
WORK_PERFORMANCE_LEVEL="4/10"

# Developer - Optimized for development
DEVELOPER_TLP_MODE=ac
DEVELOPER_POWER_PROFILE=performance
DEVELOPER_WIFI_MODE=performance
DEVELOPER_DISK_MODE=performance
DEVELOPER_DESCRIPTION="Optimized for development with compilation and testing"
DEVELOPER_BATTERY_TARGET="2-4 hours"
DEVELOPER_PERFORMANCE_LEVEL="7/10"
SYSTEM_PRESETS_EOF
    fi
    
    source "$SYSTEM_PRESETS_FILE"
}

# Initialize GPU presets (GPU switching only)
init_gpu_presets() {
    if [ ! -f "$GPU_PRESETS_FILE" ]; then
        cat > "$GPU_PRESETS_FILE" << GPU_PRESETS_EOF
# GPU Power Presets Configuration
# Format: PRESET_NAME_SETTING=value
# These presets control only GPU switching and GPU-specific settings

# Integrated - Intel GPU only
INTEGRATED_GPU_MODE=integrated
INTEGRATED_GPU_DESCRIPTION="Use integrated Intel GPU only"
INTEGRATED_GPU_POWER_USAGE="Low"
INTEGRATED_GPU_PERFORMANCE="Low"
INTEGRATED_GPU_BATTERY_IMPACT="Minimal"

# Hybrid - Dynamic switching
HYBRID_GPU_MODE=hybrid
HYBRID_GPU_DESCRIPTION="Dynamic switching between integrated and discrete GPU"
HYBRID_GPU_POWER_USAGE="Medium"
HYBRID_GPU_PERFORMANCE="Medium"
HYBRID_GPU_BATTERY_IMPACT="Moderate"

# Discrete - NVIDIA GPU only
DISCRETE_GPU_MODE=nvidia
DISCRETE_GPU_DESCRIPTION="Use discrete NVIDIA GPU only"
DISCRETE_GPU_POWER_USAGE="High"
DISCRETE_GPU_PERFORMANCE="High"
DISCRETE_GPU_BATTERY_IMPACT="Significant"

# Gaming - Optimized for gaming
GAMING_GPU_MODE=nvidia
GAMING_GPU_DESCRIPTION="Discrete GPU optimized for gaming"
GAMING_GPU_POWER_USAGE="High"
GAMING_GPU_PERFORMANCE="Maximum"
GAMING_GPU_BATTERY_IMPACT="Maximum"

# Eco - Power saving GPU
ECO_GPU_MODE=integrated
ECO_GPU_DESCRIPTION="Integrated GPU for maximum battery life"
ECO_GPU_POWER_USAGE="Minimal"
ECO_GPU_PERFORMANCE="Basic"
ECO_GPU_BATTERY_IMPACT="Minimal"
GPU_PRESETS_EOF
    fi
    
    source "$GPU_PRESETS_FILE"
}


# ============================================================================
# MODULAR PRESET MANAGEMENT
# ============================================================================

# Apply system preset (TLP, power profile, WiFi, disk, etc.)
apply_system_preset() {
    local preset="$1"
    local preset_upper=$(echo "$preset" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    # Validate preset name
    if command -v validate_preset_name >/dev/null 2>&1; then
        validate_preset_name "$preset" "system" || return 1
    fi
    
    if command -v log_info >/dev/null 2>&1; then
        log_info "Applying system preset: $preset" "SYSTEM"
    else
        echo "Applying system preset: $preset"
    fi
    
    # Validate preset exists
    if ! grep -q "^${preset_upper}_DESCRIPTION=" "$SYSTEM_PRESETS_FILE" 2>/dev/null; then
        error "System preset '$preset' not found"
        list_system_presets
        return 1
    fi
    
    # Get preset configuration
    local preset_info=$(get_system_preset_info "$preset")
    local TLP_MODE=$(echo "$preset_info" | grep "^TLP_MODE=" | cut -d'=' -f2)
    local POWER_PROFILE=$(echo "$preset_info" | grep "^POWER_PROFILE=" | cut -d'=' -f2)
    local WIFI_MODE=$(echo "$preset_info" | grep "^WIFI_MODE=" | cut -d'=' -f2)
    local DISK_MODE=$(echo "$preset_info" | grep "^DISK_MODE=" | cut -d'=' -f2)
    local DESCRIPTION=$(echo "$preset_info" | grep "^DESCRIPTION=" | cut -d'=' -f2-)
    
    echo -e "${CYAN}🔧 Applying System Preset: $preset${NC}"
    echo "   Description: $DESCRIPTION"
    echo "   TLP Mode: ${YELLOW}$TLP_MODE${NC}"
    echo "   Power Profile: ${YELLOW}$POWER_PROFILE${NC}"
    echo "   WiFi Mode: ${YELLOW}$WIFI_MODE${NC}"
    echo "   Disk Mode: ${YELLOW}$DISK_MODE${NC}"
    echo ""
    
    local errors=0
    
    # Apply TLP configuration
    if [ -n "$TLP_MODE" ] && [ "$TLP_MODE" != "none" ]; then
        apply_tlp_configuration "$TLP_MODE" || ((errors++))
    fi
    
    # Apply power profile
    if [ -n "$POWER_PROFILE" ] && [ "$POWER_PROFILE" != "none" ]; then
        apply_power_profile "$POWER_PROFILE" || ((errors++))
    fi
    
    # Apply WiFi optimizations
    if [ -n "$WIFI_MODE" ] && [ "$WIFI_MODE" != "none" ]; then
        apply_wifi_optimizations "$WIFI_MODE" || ((errors++))
    fi
    
    # Apply disk optimizations
    if [ -n "$DISK_MODE" ] && [ "$DISK_MODE" != "none" ]; then
        apply_disk_optimizations "$DISK_MODE" || ((errors++))
    fi
    
    # Store current system preset
    mkdir -p "$HOME/.cache/power-manager" 2>/dev/null || true
    echo "$preset" > "$HOME/.cache/power-manager/current-system-preset" 2>/dev/null || true
    
    if [ $errors -eq 0 ]; then
        success "System preset '$preset' applied successfully"
    else
        error "System preset '$preset' applied with $errors errors"
    fi
    
    return $errors
}

# Apply GPU preset (GPU switching only)
apply_gpu_preset() {
    local preset="$1"
    local preset_upper=$(echo "$preset" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    echo "Applying GPU preset: $preset"
    
    # Validate preset exists
    if ! grep -q "^${preset_upper}_GPU_MODE=" "$GPU_PRESETS_FILE" 2>/dev/null; then
        error "GPU preset '$preset' not found"
        list_gpu_presets
        return 1
    fi
    
    # Get preset configuration
    local preset_info=$(get_gpu_preset_info "$preset")
    local GPU_MODE=$(echo "$preset_info" | grep "^${preset_upper}_GPU_MODE=" | cut -d'=' -f2)
    local DESCRIPTION=$(echo "$preset_info" | grep "^${preset_upper}_DESCRIPTION=" | cut -d'=' -f2-)
    
    echo -e "${MAGENTA}🎮 Applying GPU Preset: $preset${NC}"
    echo "   Description: $DESCRIPTION"
    echo "   GPU Mode: ${YELLOW}$GPU_MODE${NC}"
    echo ""
    
    local errors=0
    
    # Apply GPU mode
    if [ -n "$GPU_MODE" ] && [ "$GPU_MODE" != "none" ]; then
        apply_gpu_mode "$GPU_MODE"
        local gpu_result=$?
        if [ $gpu_result -eq 1 ]; then
            ((errors++))  # Only count actual errors (return code 1)
        fi
        # Return code 2 means reboot required, which is not an error
    fi
    
    # Store current GPU preset
    mkdir -p "$HOME/.cache/power-manager" 2>/dev/null || true
    echo "$preset" > "$HOME/.cache/power-manager/current-gpu-preset" 2>/dev/null || true
    
    if [ $errors -eq 0 ]; then
        success "GPU preset '$preset' applied successfully"
    else
        error "GPU preset '$preset' applied with $errors errors"
    fi
    
    return $errors
}


# ============================================================================
# PRESET INFORMATION FUNCTIONS
# ============================================================================

# Get system preset information
get_system_preset_info() {
    local preset="$1"
    local preset_upper=$(echo "$preset" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    grep "^${preset_upper}_" "$SYSTEM_PRESETS_FILE" 2>/dev/null || echo ""
}

# Get GPU preset information
get_gpu_preset_info() {
    local preset="$1"
    local preset_upper=$(echo "$preset" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    grep "^${preset_upper}_" "$GPU_PRESETS_FILE" 2>/dev/null || echo ""
}


# ============================================================================
# PRESET LISTING FUNCTIONS
# ============================================================================

# List system presets
list_system_presets() {
    echo "Available System Presets:"
    echo "========================"
    
    grep "_DESCRIPTION=" "$SYSTEM_PRESETS_FILE" 2>/dev/null | while read line; do
        local preset=$(echo "$line" | sed 's/_DESCRIPTION=.*//' | tr '[:upper:]' '[:lower:]' | tr '_' '-')
        local description=$(echo "$line" | cut -d'=' -f2- | tr -d '"')
        echo "  $preset - $description"
    done
}

# List GPU presets
list_gpu_presets() {
    echo "Available GPU Presets:"
    echo "====================="
    
    grep "_DESCRIPTION=" "$GPU_PRESETS_FILE" 2>/dev/null | while read line; do
        local preset=$(echo "$line" | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]')
        local description=$(echo "$line" | cut -d'=' -f2- | tr -d '"')
        echo "  $preset - $description"
    done
}


# ============================================================================
# MODULAR STATUS REPORTING
# ============================================================================

# Enhanced modular status report
modular_status_report() {
    echo "Modular Power Management System - Status Report"
    echo "=============================================="
    echo ""
    
    # Current Presets
    echo "Current Presets:"
    echo "---------------"
    
    local current_system="unknown"
    local current_gpu="unknown"
    
    if [ -f "$HOME/.cache/power-manager/current-system-preset" ]; then
        current_system=$(cat "$HOME/.cache/power-manager/current-system-preset")
    fi
    
    if [ -f "$HOME/.cache/power-manager/current-gpu-preset" ]; then
        current_gpu=$(cat "$HOME/.cache/power-manager/current-gpu-preset")
    fi
    
    echo "  System Preset: $current_system"
    echo "  GPU Preset: $current_gpu"
    echo ""
    
    # System Information
    echo "System Information:"
    echo "------------------"
    echo "  Hostname: $(hostname)"
    echo "  OS: $(uname -s) $(uname -r)"
    echo "  Desktop: $(detect_desktop_environment 2>/dev/null || detect_desktop)"
    echo "  User: $USER"
    echo "  Session: $XDG_SESSION_TYPE"
    echo ""
    
    # Hardware Status
    echo "Hardware Status:"
    echo "---------------"
    echo "  Battery: $(get_battery_info)"
    echo "  CPU Temperature: $(get_cpu_temperature)"
    echo "  System Load: $(get_system_load)"
    echo "  GPU Mode: $(get_gpu_mode)"
    echo ""
    
    # Available Tools
    echo "Available Tools:"
    echo "---------------"
    echo "  powerprofilesctl: $(has_powerprofilesctl && echo "✅ Available" || echo "❌ Not available")"
    echo "  TLP: $(has_tlp && echo "✅ Available" || echo "❌ Not available")"
    echo "  EnvyControl: $(has_envycontrol && echo "✅ Available" || echo "❌ Not available")"
    echo "  Disk Manager: $(has_disk_manager && echo "✅ Available" || echo "❌ Not available")"
    echo ""
}

# ============================================================================
# MODULAR COMMAND PROCESSING
# ============================================================================

# Process modular commands
process_modular_command() {
    local command="$1"
    shift
    local args=("$@")
    
    echo "Processing modular command: $command with args: ${args[*]}"
    
    case "$command" in
        # System preset commands
        "system-preset")
            if [ -n "${args[0]}" ]; then
                apply_system_preset "${args[0]}"
            else
                error "Please specify system preset name"
                list_system_presets
            fi
            ;;
        
        # GPU preset commands
        "gpu-preset")
            if [ -n "${args[0]}" ]; then
                apply_gpu_preset "${args[0]}"
            else
                error "Please specify GPU preset name"
                list_gpu_presets
            fi
            ;;
        
        
        # Listing commands
        "list-system-presets")
            list_system_presets
            ;;
        "list-gpu-presets")
            list_gpu_presets
            ;;
        "list-all-presets")
            list_system_presets
            echo ""
            list_gpu_presets
            ;;
        
        # Status commands
        "status"|"status-modular")
            modular_status_report
            ;;
        
        # Health check commands
        "health-check")
            if command -v comprehensive_health_check >/dev/null 2>&1; then
                comprehensive_health_check
            else
                echo "Health check not available"
            fi
            ;;
        
        # Metrics commands
        "metrics")
            if command -v collect_system_metrics >/dev/null 2>&1; then
                echo "System Metrics:"
                collect_system_metrics
                echo ""
                echo "Power Metrics:"
                collect_power_metrics
                echo ""
                echo "GPU Metrics:"
                collect_gpu_metrics
            else
                echo "Metrics collection not available"
            fi
            ;;
        
        # WiFi status (read-only - WiFi power management handled by TLP)
        "wifi-status")
            show_basic_wifi_status
            ;;
        
        # Disk Management Commands
        "disk-status")
            show_disk_status
            ;;
        "disk-suspend")
            suspend_disk "${args[0]}"
            ;;
        "disk-wake")
            wake_disk "${args[0]}"
            ;;
        "disk-monitor")
            monitor_disks
            ;;
        "disk-config")
            configure_disk_management
            ;;
        "disk-disable")
            disable_disk_management
            ;;
        "disk-enable")
            enable_disk_management
            ;;
        
        # General Monitoring Commands
        "monitor")
            general_monitoring
            ;;
        
        # Help
        "help"|"--help"|"-h")
            show_modular_help
            ;;
        
        # Version
        "version"|"--version"|"-v")
            echo "Modular Power Management System v1.0.0"
            ;;
        
        *)
            error "Unknown modular command: $command"
            show_modular_help
            return 1
            ;;
    esac
}

# Show modular help
show_modular_help() {
    echo "Modular Power Management System v1.0.0"
    echo "======================================"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "System Preset Commands:"
    echo "  system-preset <name>    Apply system preset (TLP, power profile, WiFi, disk)"
    echo "  list-system-presets     List available system presets"
    echo ""
    echo "GPU Preset Commands:"
    echo "  gpu-preset <name>       Apply GPU preset (GPU switching only)"
    echo "  list-gpu-presets        List available GPU presets"
    echo "  list-all-presets        List all available presets"
    echo ""
    echo "WiFi Status Commands:"
    echo "  wifi-status             Show basic WiFi status (power managed by TLP)"
    echo ""
    echo "Disk Management Commands:"
    echo "  disk-status             Show disk management status"
    echo "  disk-suspend <disk>     Suspend specific disk"
    echo "  disk-wake <disk>        Wake up specific disk"
    echo "  disk-monitor            Monitor and suspend inactive disks"
    echo "  disk-config             Configure disk management"
    echo "  disk-disable            Disable disk management module"
    echo "  disk-enable             Enable disk management module"
    echo ""
    echo "Status Commands:"
    echo "  status                 Show modular system status"
    echo "  status-modular         Show detailed modular system status"
    echo "  health-check           Run comprehensive health check"
    echo "  metrics                Show system metrics"
    echo ""
    echo "Other Commands:"
    echo "  help                   Show this help"
    echo "  version                Show version information"
    echo ""
    echo "Examples:"
    echo "  $0 system-preset ultra-eco    # Apply ultra eco system preset"
    echo "  $0 gpu-preset hybrid          # Apply hybrid GPU preset"
    echo "  $0 list-all-presets           # List all available presets"
    echo ""
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

# Export modular functions
export -f init_modular_system
export -f apply_system_preset
export -f apply_gpu_preset
export -f get_system_preset_info
export -f get_gpu_preset_info
export -f list_system_presets
export -f list_gpu_presets
export -f modular_status_report
# ============================================================================
# BASIC WIFI STATUS FUNCTIONS
# ============================================================================

# Show basic WiFi status (WiFi power management handled by TLP)
show_basic_wifi_status() {
    echo "Basic WiFi Status (Power Management via TLP):"
    echo "============================================="
    
    # Check for WiFi adapter
    local wifi_info=$(lspci | grep -i "network\|wifi\|wireless" | head -1)
    if [ -n "$wifi_info" ]; then
        echo "📶 WiFi Adapter: $wifi_info"
        
        # Get WiFi interface
        local interface=$(ip link show | grep -E "wl|wlan" | cut -d: -f2 | tr -d ' ' | head -1)
        if [ -n "$interface" ]; then
            echo "🔌 Interface: $interface"
            
            # Check connection status
            local connection_status=$(nmcli -t -f DEVICE,STATE dev | grep "$interface" | cut -d: -f2)
            echo "🔗 Status: ${connection_status:-unknown}"
            
            # Check current power save status (read-only)
            if command -v iw >/dev/null 2>&1; then
                local power_save=$(iw dev "$interface" get power_save 2>/dev/null || echo "unknown")
                echo "⚡ Current Power Save: $power_save"
            fi
        fi
    else
        echo "❌ No WiFi adapter detected"
    fi
    
    echo ""
    echo "ℹ️  Note: WiFi power management is handled by TLP presets."
    echo "   Check TLP configuration files for WiFi power settings."
}

# ============================================================================
# DISK MANAGEMENT FUNCTIONS
# ============================================================================

# Show disk management status
show_disk_status() {
    echo "Disk Management Status:"
    echo "======================="
    
    # List all disks
    echo "Available Disks:"
    lsblk -d -o NAME,SIZE,TYPE,STATE | grep -E "(disk|nvme)" | while read line; do
        echo "  $line"
    done
    
    echo ""
    echo "Disk Power States:"
    for disk in /sys/block/*/device/power_state; do
        if [ -f "$disk" ] 2>/dev/null; then
            local disk_name=$(basename "$(dirname "$(dirname "$disk")")")
            local power_state=$(cat "$disk" 2>/dev/null || echo "unknown")
            echo "  $disk_name: $power_state"
        fi
    done
}

# Suspend specific disk
suspend_disk() {
    local disk="$1"
    
    if [ -z "$disk" ]; then
        echo "ERROR: Please specify disk name (e.g., nvme1n1)"
        return 1
    fi
    
    if [ ! -b "/dev/$disk" ]; then
        echo "ERROR: Disk /dev/$disk not found"
        return 1
    fi
    
    echo "Suspending disk: $disk"
    
    # Check if disk is system disk
    if mount | grep -q "/dev/$disk"; then
        echo "WARNING: Disk $disk appears to be mounted. Suspending may cause issues."
        read -p "Continue? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Cancelled"
            return 1
        fi
    fi
    
    # Suspend disk
    echo "1" | sudo tee "/sys/block/$disk/device/power_state" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Disk $disk suspended"
    else
        echo "ERROR: Failed to suspend disk $disk"
        return 1
    fi
}

# Wake up specific disk
wake_disk() {
    local disk="$1"
    
    if [ -z "$disk" ]; then
        echo "ERROR: Please specify disk name (e.g., nvme1n1)"
        return 1
    fi
    
    if [ ! -b "/dev/$disk" ]; then
        echo "ERROR: Disk /dev/$disk not found"
        return 1
    fi
    
    echo "Waking up disk: $disk"
    
    # Wake up disk
    echo "0" | sudo tee "/sys/block/$disk/device/power_state" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Disk $disk woken up"
    else
        echo "ERROR: Failed to wake up disk $disk"
        return 1
    fi
}

# Monitor and suspend inactive disks
monitor_disks() {
    echo "Disk Monitoring:"
    echo "================"
    
    # Find non-system disks
    local system_disks=$(mount | grep -E "^/dev/" | sed 's|/dev/||' | cut -d' ' -f1 | sed 's/[0-9]*$//' | sort -u)
    
    for disk in /sys/block/*/device/power_state; do
        if [ -f "$disk" ] 2>/dev/null; then
            local disk_name=$(basename "$(dirname "$(dirname "$disk")")")
            
            # Skip system disks
            if echo "$system_disks" | grep -q "^$disk_name"; then
                continue
            fi
            
            # Check if disk is active
            local power_state=$(cat "$disk" 2>/dev/null || echo "unknown")
            echo "Disk $disk_name: $power_state"
            
            # Check disk activity
            local stat_file="/sys/block/$disk_name/stat"
            if [ -f "$stat_file" ]; then
                local reads=$(awk '{print $1}' "$stat_file")
                local writes=$(awk '{print $5}' "$stat_file")
                echo "  Reads: $reads, Writes: $writes"
            fi
        fi
    done
}

# Configure disk management
configure_disk_management() {
    echo "Disk Management Configuration:"
    echo "=============================="
    echo ""
    echo "This would open an interactive configuration menu."
    echo "For now, disk management is handled by the standalone disk-manager.sh script."
    echo ""
    echo "Available commands:"
    echo "  disk-status          - Show disk status"
    echo "  disk-suspend <disk>  - Suspend specific disk"
    echo "  disk-wake <disk>     - Wake up specific disk"
    echo "  disk-monitor          - Monitor disk activity"
    echo ""
    echo "For advanced configuration, use: ./scripts/disk-manager.sh config"
}

# General monitoring function
general_monitoring() {
    if command -v log_info >/dev/null 2>&1; then
        log_info "Running general system monitoring..." "MONITOR"
    else
        echo "Running general system monitoring..."
    fi
    
    echo "Modular Power Management System - Monitoring Report"
    echo "=================================================="
    echo ""
    
    # System status
    echo "📊 System Status:"
    modular_status_report
    echo ""
    
    # WiFi status
    echo "📶 WiFi Status:"
    show_basic_wifi_status
    echo ""
    
    # Disk status
    echo "💾 Disk Status:"
    show_disk_status
    echo ""
    
    # Health check if available
    if command -v comprehensive_health_check >/dev/null 2>&1; then
        echo "🔍 Health Check:"
        comprehensive_health_check
        echo ""
    fi
    
    # Metrics if available
    if command -v collect_system_metrics >/dev/null 2>&1; then
        echo "📈 System Metrics:"
        collect_system_metrics
        echo ""
    fi
    
    if command -v success >/dev/null 2>&1; then
        success "General monitoring completed" "MONITOR"
    else
        echo "SUCCESS: General monitoring completed"
    fi
}

# ============================================================================
# MODULE DISABLE/ENABLE FUNCTIONS
# ============================================================================


# Disable disk management module
disable_disk_management() {
    if command -v log_info >/dev/null 2>&1; then
        log_info "Disabling disk management module..." "DISK"
    else
        echo "Disabling disk management module..."
    fi
    
    # Stop and disable disk services
    sudo systemctl stop disk-monitor.service 2>/dev/null || true
    sudo systemctl stop disk-monitor.timer 2>/dev/null || true
    sudo systemctl disable disk-monitor.timer 2>/dev/null || true
    
    # Create disable flag
    mkdir -p "$HOME/.config"
    touch "$HOME/.config/disk-management-disabled"
    
    if command -v success >/dev/null 2>&1; then
        success "Disk management module disabled" "DISK"
    else
        echo "✅ Disk management module disabled"
    fi
    echo "   Services stopped and disabled"
    echo "   No automatic disk suspension will occur"
    echo "   To re-enable: power-control disk-enable"
}

# Enable disk management module
enable_disk_management() {
    if command -v log_info >/dev/null 2>&1; then
        log_info "Enabling disk management module..." "DISK"
    else
        echo "Enabling disk management module..."
    fi
    
    # Remove disable flag
    rm -f "$HOME/.config/disk-management-disabled"
    
    # Enable and start disk services
    sudo systemctl enable disk-monitor.timer 2>/dev/null || true
    sudo systemctl start disk-monitor.timer 2>/dev/null || true
    
    if command -v success >/dev/null 2>&1; then
        success "Disk management module enabled" "DISK"
    else
        echo "✅ Disk management module enabled"
    fi
    echo "   Services enabled and started"
    echo "   Automatic disk suspension will resume"
}

export -f process_modular_command
export -f show_modular_help
export -f show_basic_wifi_status
export -f show_disk_status
export -f suspend_disk
export -f wake_disk
export -f monitor_disks
export -f configure_disk_management
export -f general_monitoring
export -f disable_disk_management
export -f enable_disk_management
