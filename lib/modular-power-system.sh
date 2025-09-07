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
COMPOSITE_PRESETS_FILE="$HOME/.config/composite-presets.conf"

# Preset directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_PRESETS_DIR="$SCRIPT_DIR/../presets/system-presets"
GPU_PRESETS_DIR="$SCRIPT_DIR/../presets/gpu-presets"
COMPOSITE_PRESETS_DIR="$SCRIPT_DIR/../presets/composite-presets"

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
    
    # Initialize composite presets
    init_composite_presets
    
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
DEFAULT_COMPOSITE_PRESET=balanced-hybrid

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

# Initialize composite presets (combinations of system + GPU)
init_composite_presets() {
    if [ ! -f "$COMPOSITE_PRESETS_FILE" ]; then
        cat > "$COMPOSITE_PRESETS_FILE" << COMPOSITE_PRESETS_EOF
# Composite Power Presets Configuration
# Format: PRESET_NAME_SYSTEM_PRESET=value, PRESET_NAME_GPU_PRESET=value
# These are convenient combinations of system and GPU presets

# Ultra Eco - Maximum battery life
ULTRA_ECO_COMPOSITE_SYSTEM_PRESET=ultra-eco
ULTRA_ECO_COMPOSITE_GPU_PRESET=eco
ULTRA_ECO_COMPOSITE_DESCRIPTION="Maximum battery life with integrated GPU"
ULTRA_ECO_COMPOSITE_BATTERY_TARGET="10-12+ hours"

# Eco Gaming - Light gaming with good battery
ECO_GAMING_COMPOSITE_SYSTEM_PRESET=eco
ECO_GAMING_COMPOSITE_GPU_PRESET=hybrid
ECO_GAMING_COMPOSITE_DESCRIPTION="Light gaming with good battery life"
ECO_GAMING_COMPOSITE_BATTERY_TARGET="4-6 hours"

# Balanced - Default balanced mode
BALANCED_COMPOSITE_SYSTEM_PRESET=balanced
BALANCED_COMPOSITE_GPU_PRESET=hybrid
BALANCED_COMPOSITE_DESCRIPTION="Balanced performance and efficiency"
BALANCED_COMPOSITE_BATTERY_TARGET="4-6 hours"

# Balanced dGPU - Balanced with discrete GPU
BALANCED_DGPU_COMPOSITE_SYSTEM_PRESET=balanced
BALANCED_DGPU_COMPOSITE_GPU_PRESET=discrete
BALANCED_DGPU_COMPOSITE_DESCRIPTION="Balanced mode with discrete GPU"
BALANCED_DGPU_COMPOSITE_BATTERY_TARGET="2-4 hours"

# Performance - High performance
PERFORMANCE_COMPOSITE_SYSTEM_PRESET=performance
PERFORMANCE_COMPOSITE_GPU_PRESET=hybrid
PERFORMANCE_COMPOSITE_DESCRIPTION="High performance for demanding tasks"
PERFORMANCE_COMPOSITE_BATTERY_TARGET="2-4 hours"

# Performance dGPU - High performance with discrete GPU
PERFORMANCE_DGPU_COMPOSITE_SYSTEM_PRESET=performance
PERFORMANCE_DGPU_COMPOSITE_GPU_PRESET=discrete
PERFORMANCE_DGPU_COMPOSITE_DESCRIPTION="High performance with discrete GPU"
PERFORMANCE_DGPU_COMPOSITE_BATTERY_TARGET="1-3 hours"

# Gaming Max - Maximum gaming performance
GAMING_MAX_COMPOSITE_SYSTEM_PRESET=gaming
GAMING_MAX_COMPOSITE_GPU_PRESET=gaming
GAMING_MAX_COMPOSITE_DESCRIPTION="Maximum performance for gaming"
GAMING_MAX_COMPOSITE_BATTERY_TARGET="1-2 hours"

# Work Mode - Optimized for productivity
WORK_MODE_COMPOSITE_SYSTEM_PRESET=work
WORK_MODE_COMPOSITE_GPU_PRESET=integrated
WORK_MODE_COMPOSITE_DESCRIPTION="Optimized for office work and productivity"
WORK_MODE_COMPOSITE_BATTERY_TARGET="6-8 hours"

# Developer Mode - For development workloads
DEVELOPER_MODE_COMPOSITE_SYSTEM_PRESET=developer
DEVELOPER_MODE_COMPOSITE_GPU_PRESET=hybrid
DEVELOPER_MODE_COMPOSITE_DESCRIPTION="Optimized for development workloads"
DEVELOPER_MODE_COMPOSITE_BATTERY_TARGET="3-5 hours"
COMPOSITE_PRESETS_EOF
    fi
    
    source "$COMPOSITE_PRESETS_FILE"
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
    echo "$preset" > /tmp/power-manager-current-system-preset 2>/dev/null || true
    
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
    echo "$preset" > /tmp/power-manager-current-gpu-preset 2>/dev/null || true
    
    if [ $errors -eq 0 ]; then
        success "GPU preset '$preset' applied successfully"
    else
        error "GPU preset '$preset' applied with $errors errors"
    fi
    
    return $errors
}

# Apply composite preset (system + GPU)
apply_composite_preset() {
    local preset="$1"
    local preset_upper=$(echo "$preset" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    echo "Applying composite preset: $preset"
    
    # Validate preset exists
    if ! grep -q "^${preset_upper}_COMPOSITE_DESCRIPTION=" "$COMPOSITE_PRESETS_FILE" 2>/dev/null; then
        error "Composite preset '$preset' not found"
        list_composite_presets
        return 1
    fi
    
    # Get preset configuration
    local preset_info=$(get_composite_preset_info "$preset")
    local SYSTEM_PRESET=$(echo "$preset_info" | grep "^${preset_upper}_COMPOSITE_SYSTEM_PRESET=" | cut -d'=' -f2)
    local GPU_PRESET=$(echo "$preset_info" | grep "^${preset_upper}_COMPOSITE_GPU_PRESET=" | cut -d'=' -f2)
    local DESCRIPTION=$(echo "$preset_info" | grep "^${preset_upper}_COMPOSITE_DESCRIPTION=" | cut -d'=' -f2-)
    
    echo -e "${PURPLE}🎯 Applying Composite Preset: $preset${NC}"
    echo "   Description: $DESCRIPTION"
    echo "   System Preset: ${YELLOW}$SYSTEM_PRESET${NC}"
    echo "   GPU Preset: ${YELLOW}$GPU_PRESET${NC}"
    echo ""
    
    local errors=0
    
    # Apply system preset
    if [ -n "$SYSTEM_PRESET" ] && [ "$SYSTEM_PRESET" != "none" ]; then
        apply_system_preset "$SYSTEM_PRESET" || ((errors++))
    fi
    
    # Apply GPU preset
    if [ -n "$GPU_PRESET" ] && [ "$GPU_PRESET" != "none" ]; then
        apply_gpu_preset "$GPU_PRESET" || ((errors++))
    fi
    
    # Store current composite preset
    echo "$preset" > /tmp/power-manager-current-composite-preset 2>/dev/null || true
    
    if [ $errors -eq 0 ]; then
        success "Composite preset '$preset' applied successfully"
    else
        error "Composite preset '$preset' applied with $errors errors"
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

# Get composite preset information
get_composite_preset_info() {
    local preset="$1"
    local preset_upper=$(echo "$preset" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    grep "^${preset_upper}_" "$COMPOSITE_PRESETS_FILE" 2>/dev/null || echo ""
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

# List composite presets
list_composite_presets() {
    echo "Available Composite Presets:"
    echo "==========================="
    
    grep "_DESCRIPTION=" "$COMPOSITE_PRESETS_FILE" 2>/dev/null | while read line; do
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
    local current_composite="unknown"
    
    if [ -f "/tmp/power-manager-current-system-preset" ]; then
        current_system=$(cat /tmp/power-manager-current-system-preset)
    fi
    
    if [ -f "/tmp/power-manager-current-gpu-preset" ]; then
        current_gpu=$(cat /tmp/power-manager-current-gpu-preset)
    fi
    
    if [ -f "/tmp/power-manager-current-composite-preset" ]; then
        current_composite=$(cat /tmp/power-manager-current-composite-preset)
    fi
    
    echo "  System Preset: $current_system"
    echo "  GPU Preset: $current_gpu"
    echo "  Composite Preset: $current_composite"
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
    echo "  SupergfxCtl: $(has_supergfxctl && echo "✅ Available" || echo "❌ Not available")"
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
        
        # Composite preset commands
        "composite-preset")
            if [ -n "${args[0]}" ]; then
                apply_composite_preset "${args[0]}"
            else
                error "Please specify composite preset name"
                list_composite_presets
            fi
            ;;
        
        # Quick composite preset commands
        "ultra-eco")
            apply_composite_preset "ultra-eco"
            ;;
        "eco-gaming")
            apply_composite_preset "eco-gaming"
            ;;
        "balanced")
            apply_composite_preset "balanced"
            ;;
        "balanced-dgpu")
            apply_composite_preset "balanced-dgpu"
            ;;
        "performance")
            apply_composite_preset "performance"
            ;;
        "performance-dgpu")
            apply_composite_preset "performance-dgpu"
            ;;
        "gaming-max")
            apply_composite_preset "gaming-max"
            ;;
        "work-mode")
            apply_composite_preset "work-mode"
            ;;
        "developer-mode")
            apply_composite_preset "developer-mode"
            ;;
        
        # Listing commands
        "list-system-presets")
            list_system_presets
            ;;
        "list-gpu-presets")
            list_gpu_presets
            ;;
        "list-composite-presets")
            list_composite_presets
            ;;
        "list-all-presets")
            list_system_presets
            echo ""
            list_gpu_presets
            echo ""
            list_composite_presets
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
    echo ""
    echo "Composite Preset Commands:"
    echo "  composite-preset <name> Apply composite preset (system + GPU)"
    echo "  list-composite-presets  List available composite presets"
    echo "  list-all-presets        List all available presets"
    echo ""
    echo "Quick Composite Preset Commands:"
    echo "  ultra-eco              Apply ultra eco composite preset"
    echo "  eco-gaming             Apply eco gaming composite preset"
    echo "  balanced               Apply balanced composite preset"
    echo "  balanced-dgpu          Apply balanced dGPU composite preset"
    echo "  performance             Apply performance composite preset"
    echo "  performance-dgpu       Apply performance dGPU composite preset"
    echo "  gaming-max             Apply gaming max composite preset"
    echo "  work-mode              Apply work mode composite preset"
    echo "  developer-mode         Apply developer mode composite preset"
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
    echo "  $0 composite-preset gaming-max # Apply gaming max composite preset"
    echo "  $0 balanced                   # Quick apply balanced composite preset"
    echo ""
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

# Export modular functions
export -f init_modular_system
export -f apply_system_preset
export -f apply_gpu_preset
export -f apply_composite_preset
export -f get_system_preset_info
export -f get_gpu_preset_info
export -f get_composite_preset_info
export -f list_system_presets
export -f list_gpu_presets
export -f list_composite_presets
export -f modular_status_report
export -f process_modular_command
export -f show_modular_help
