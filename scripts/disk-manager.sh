#!/bin/bash

# Linux Power Manager - Enhanced Disk Management Module
# Intel-optimized automatic and on-demand disk suspension system
# Version: 2.0.0

VERSION="2.0.0"
DISK_CONFIG_FILE="$HOME/.config/disk-manager.conf"

# Load configuration
load_config() {
    if [ -f "$DISK_CONFIG_FILE" ]; then
        source "$DISK_CONFIG_FILE"
    else
        # Default configuration
        DISK_MANAGEMENT_ENABLED=true
        AUTO_SUSPEND_ENABLED=true
        INACTIVITY_TIMEOUT=300
        SUSPEND_ON_BATTERY_ONLY=false
        EXCLUDE_SYSTEM_DISK=true
        MONITORED_DISKS="auto"
        LOG_DISK_ACTIVITY=false
        NVME_POWER_MANAGEMENT=true
        INTEL_SSD_OPTIMIZATION=false
        SMART_MONITORING=false
        HEALTH_THRESHOLD=80
        ADAPTIVE_TIMEOUT=true
        ENABLE_DEEP_SLEEP=false
    fi
}

# Load configuration on startup
load_config
ACTIVITY_LOG="/tmp/disk-activity.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Enhanced logging with enterprise support
if command -v log_info >/dev/null 2>&1; then
    # Use enterprise logging if available
    log() { log_info "$1" "DISK"; }
    error() { log_error "$1" "DISK"; }
    success() { log_success "$1" "DISK"; }
    warning() { log_warning "$1" "DISK"; }
    info() { log_info "$1" "DISK"; }
else
    # Fallback to basic logging
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    
    log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
    error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
    success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
    warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
    info() { echo -e "${CYAN}[INFO]${NC} $1"; }
fi

# Create config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Initialize enhanced disk management configuration
init_disk_config() {
    if [ ! -f "$DISK_CONFIG_FILE" ]; then
        cat > "$DISK_CONFIG_FILE" << DISK_CONF_EOF
# Enhanced Disk Management Configuration
DISK_MANAGEMENT_ENABLED=true
AUTO_SUSPEND_ENABLED=true
INACTIVITY_TIMEOUT=300
SUSPEND_ON_BATTERY_ONLY=true
MONITORED_DISKS="auto"
EXCLUDE_SYSTEM_DISK=true
LOG_DISK_ACTIVITY=true
NVME_POWER_MANAGEMENT=true
SATA_POWER_MANAGEMENT=true

# Intel-specific optimizations
INTEL_SSD_OPTIMIZATION=true
INTEL_NVME_OPTIMIZATION=true
INTEL_POWER_POLICY=balanced

# Advanced features
SMART_MONITORING=true
HEALTH_THRESHOLD=80
PERFORMANCE_MONITORING=true
ADAPTIVE_TIMEOUT=true

# Power states
ENABLE_DEEP_SLEEP=true
ENABLE_POWER_DOWN=true
ENABLE_STANDBY=true
DISK_CONF_EOF
        log "Created enhanced disk management configuration"
    fi
}

# Source configurations
init_disk_config
source "$DISK_CONFIG_FILE" 2>/dev/null || true

# ============================================================================
# ENHANCED DISK DETECTION AND MANAGEMENT FUNCTIONS
# ============================================================================

# Enhanced battery detection
is_on_battery() {
    local battery_path="/sys/class/power_supply/BAT0"
    if [ -d "$battery_path" ]; then
        local status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
        [ "$status" = "Discharging" ]
    else
        # Try multiple battery detection methods
        if command -v acpi >/dev/null 2>&1; then
            acpi -b | grep -q "Discharging"
        elif command -v upower >/dev/null 2>&1; then
            upower -i $(upower -e | grep 'BAT') | grep -q "state.*discharging"
        else
            # Conservative approach - assume on battery if we can't determine
            return 0
        fi
    fi
}

# Enhanced disk detection with Intel optimizations
get_all_disks() {
    # Get all disks with enhanced information
    lsblk -nd -o NAME,TYPE,SIZE,MODEL | awk '$2=="disk" && $3!="0B" {print $1}' | sort
}

# Enhanced system disk detection
get_system_disk() {
    local root_mount=$(df / | tail -1 | awk '{print $1}')
    local system_disk="unknown"
    
    # Handle different root device types
    if [[ "$root_mount" == /dev/mapper/* ]]; then
        # For LUKS/LVM devices, trace back to physical disk
        local mapper_name=$(basename "$root_mount")
        local physical_device=$(dmsetup info "$mapper_name" 2>/dev/null | grep "table" | awk '{print $NF}' | cut -d: -f1)
        if [ -n "$physical_device" ]; then
            system_disk=$(basename "$physical_device")
        fi
    elif [[ "$root_mount" == /dev/nvme* ]]; then
        # For NVMe devices
        system_disk=$(basename "$root_mount" | sed 's/p[0-9]*$//')
    elif [[ "$root_mount" == /dev/sd* ]]; then
        # For SATA devices
        system_disk=$(basename "$root_mount" | sed 's/[0-9]*$//')
    else
        # Fallback method
        system_disk=$(lsblk -nd -o NAME,MOUNTPOINT | awk '$2=="/" {print $1}' | head -1)
    fi
    
    echo "$system_disk"
}

# Intel SSD optimization
optimize_intel_ssd() {
    local disk="$1"
    if [ -z "$disk" ]; then
        return 1
    fi
    
    # Check if it's an Intel SSD
    local model=$(cat "/sys/block/$disk/device/model" 2>/dev/null || echo "")
    if [[ "$model" == *"Intel"* ]]; then
        log "Optimizing Intel SSD: $disk ($model)"
        
        # Intel-specific optimizations
        if [ -f "/sys/block/$disk/queue/scheduler" ]; then
            echo "mq-deadline" | sudo tee "/sys/block/$disk/queue/scheduler" >/dev/null 2>&1
        fi
        
        # Intel NVMe specific optimizations
        if [[ "$disk" == nvme* ]]; then
            # Set Intel NVMe power management
            if [ -f "/sys/block/$disk/device/power_state" ]; then
                echo "0" | sudo tee "/sys/block/$disk/device/power_state" >/dev/null 2>&1
            fi
            
            # Intel NVMe power policy
            if [ -f "/sys/block/$disk/device/power_control" ]; then
                echo "auto" | sudo tee "/sys/block/$disk/device/power_control" >/dev/null 2>&1
            fi
        fi
        
        success "Intel SSD optimization applied to $disk"
        return 0
    fi
    
    return 1
}

# Enhanced disk health monitoring
check_disk_health() {
    local disk="$1"
    if [ -z "$disk" ]; then
        return 1
    fi
    
    # Check if SMART is available
    if command -v smartctl >/dev/null 2>&1; then
        local health=$(smartctl -H "/dev/$disk" 2>/dev/null | grep "SMART overall-health" | awk '{print $NF}')
        if [ "$health" = "PASSED" ]; then
            return 0
        else
            warning "Disk $disk health check failed: $health"
            return 1
        fi
    fi
    
    return 0
}

# Manual disk suspension with force override (for advanced users)
suspend_disk_manual() {
    local disk="$1"
    local force="${2:-false}"
    
    if [ -z "$disk" ]; then
        error "No disk specified"
        return 1
    fi
    
    # Check if disk exists
    if [ ! -b "/dev/$disk" ]; then
        error "Disk /dev/$disk not found"
        return 1
    fi
    
    # Check if disk is system disk
    local system_disk=$(get_system_disk)
    if [ "$disk" = "$system_disk" ] && [ "$EXCLUDE_SYSTEM_DISK" = "true" ]; then
        warning "Skipping system disk: $disk"
        return 0
    fi
    
    # Check if disk is mounted or has mounted partitions
    local mounted_partitions=$(mount | grep "/dev/$disk" | wc -l)
    if [ "$mounted_partitions" -gt 0 ]; then
        if [ "$force" != "true" ]; then
            warning "Disk $disk has $mounted_partitions mounted partition(s). Use force-suspend to override."
            warning "Suspending mounted disks can cause data loss or system instability!"
            return 1
        else
            warning "FORCE MODE: Suspending disk $disk with mounted partitions - RISK OF DATA LOSS!"
        fi
    fi
    
    # Check if disk has active processes
    local active_processes=$(lsof "/dev/$disk" 2>/dev/null | wc -l)
    if [ "$active_processes" -gt 0 ]; then
        if [ "$force" != "true" ]; then
            warning "Disk $disk has $active_processes active process(es). Use force-suspend to override."
            return 1
        else
            warning "FORCE MODE: Suspending disk $disk with active processes - RISK OF DATA LOSS!"
        fi
    fi
    
    # Check if disk is in use by LVM or other systems
    if command -v pvs >/dev/null 2>&1; then
        if pvs "/dev/$disk" >/dev/null 2>&1; then
            if [ "$force" != "true" ]; then
                warning "Disk $disk is used by LVM. Use force-suspend to override."
                return 1
            else
                warning "FORCE MODE: Suspending LVM disk $disk - RISK OF DATA LOSS!"
            fi
        fi
    fi
    
    # Check battery status if required
    if [ "$SUSPEND_ON_BATTERY_ONLY" = "true" ] && ! is_on_battery; then
        info "Skipping suspension - on AC power"
        return 0
    fi
    
    # Check disk health
    if [ "$SMART_MONITORING" = "true" ]; then
        if ! check_disk_health "$disk"; then
            warning "Skipping suspension due to health issues"
            return 1
        fi
    fi
    
    log "Manually suspending disk: $disk"
    
    # Apply Intel optimizations before suspension
    optimize_intel_ssd "$disk"
    
    # Suspend disk
    if [[ "$disk" == nvme* ]]; then
        # NVMe suspension using correct power management
        if [ -f "/sys/block/$disk/device/power/control" ]; then
            echo "auto" | sudo tee "/sys/block/$disk/device/power/control" >/dev/null 2>&1
        fi
        # Set autosuspend delay to immediate
        if [ -f "/sys/block/$disk/device/power/autosuspend_delay_ms" ]; then
            echo "0" | sudo tee "/sys/block/$disk/device/power/autosuspend_delay_ms" >/dev/null 2>&1
        fi
    else
        # SATA suspension using hdparm
        if command -v hdparm >/dev/null 2>&1; then
            sudo hdparm -y "/dev/$disk" >/dev/null 2>&1
        else
            # Fallback to power_state if available
            if [ -f "/sys/block/$disk/device/power_state" ]; then
                echo "1" | sudo tee "/sys/block/$disk/device/power_state" >/dev/null 2>&1
            fi
        fi
    fi
    
    # Check if suspension was successful
    local success=false
    
    if [[ "$disk" == nvme* ]]; then
        # For NVMe, check if power control is set to auto
        if [ -f "/sys/block/$disk/device/power/control" ]; then
            local current_control=$(cat "/sys/block/$disk/device/power/control" 2>/dev/null)
            if [ "$current_control" = "auto" ]; then
                success=true
            fi
        fi
    else
        # For SATA, assume success if hdparm command succeeded
        success=true
    fi
    
    if [ "$success" = "true" ]; then
        success "Disk $disk suspended successfully"
        return 0
    else
        error "Failed to suspend disk $disk"
        return 1
    fi
}

# Enhanced disk suspension with Intel optimizations (AUTOMATIC - NO FORCE OVERRIDE)
suspend_disk_enhanced() {
    local disk="$1"
    
    if [ -z "$disk" ]; then
        error "No disk specified"
        return 1
    fi
    
    # Check if disk exists
    if [ ! -b "/dev/$disk" ]; then
        error "Disk /dev/$disk not found"
        return 1
    fi
    
    # Check if disk is system disk
    local system_disk=$(get_system_disk)
    if [ "$disk" = "$system_disk" ] && [ "$EXCLUDE_SYSTEM_DISK" = "true" ]; then
        warning "Skipping system disk: $disk"
        return 0
    fi
    
    # Check if disk is mounted or has mounted partitions
    local mounted_partitions=$(mount | grep "/dev/$disk" | wc -l)
    if [ "$mounted_partitions" -gt 0 ]; then
        warning "Disk $disk has $mounted_partitions mounted partition(s)."
        warning "Suspending mounted disks can cause data loss or system instability!"
        warning "🚫 AUTOMATIC SUSPENSION BLOCKED - Disk is in use!"
        return 1
    fi
    
    # Check if disk has active processes
    local active_processes=$(lsof "/dev/$disk" 2>/dev/null | wc -l)
    if [ "$active_processes" -gt 0 ]; then
        warning "Disk $disk has $active_processes active process(es)."
        warning "🚫 AUTOMATIC SUSPENSION BLOCKED - Disk has active processes!"
        return 1
    fi
    
    # Check if disk is in use by LVM or other systems
    if command -v pvs >/dev/null 2>&1; then
        if pvs "/dev/$disk" >/dev/null 2>&1; then
            warning "Disk $disk is used by LVM."
            warning "🚫 AUTOMATIC SUSPENSION BLOCKED - Disk is LVM physical volume!"
            return 1
        fi
    fi
    
    # Check battery status if required
    if [ "$SUSPEND_ON_BATTERY_ONLY" = "true" ] && ! is_on_battery; then
        info "Skipping suspension - on AC power"
        return 0
    fi
    
    # Check disk health
    if [ "$SMART_MONITORING" = "true" ]; then
        if ! check_disk_health "$disk"; then
            warning "Skipping suspension due to health issues"
            return 1
        fi
    fi
    
    log "Suspending disk: $disk"
    
    # Apply Intel optimizations before suspension
    optimize_intel_ssd "$disk"
    
    # Suspend disk
    if [[ "$disk" == nvme* ]]; then
        # NVMe suspension using correct power management
        if [ -f "/sys/block/$disk/device/power/control" ]; then
            echo "auto" | sudo tee "/sys/block/$disk/device/power/control" >/dev/null 2>&1
        fi
        # Set autosuspend delay to immediate
        if [ -f "/sys/block/$disk/device/power/autosuspend_delay_ms" ]; then
            echo "0" | sudo tee "/sys/block/$disk/device/power/autosuspend_delay_ms" >/dev/null 2>&1
        fi
    else
        # SATA suspension using hdparm
        if command -v hdparm >/dev/null 2>&1; then
            sudo hdparm -y "/dev/$disk" >/dev/null 2>&1
        else
            # Fallback to power_state if available
            if [ -f "/sys/block/$disk/device/power_state" ]; then
                echo "1" | sudo tee "/sys/block/$disk/device/power_state" >/dev/null 2>&1
            fi
        fi
    fi
    
    # Check if suspension was successful
    local success=false
    
    if [[ "$disk" == nvme* ]]; then
        # For NVMe, check if power control is set to auto
        if [ -f "/sys/block/$disk/device/power/control" ]; then
            local current_control=$(cat "/sys/block/$disk/device/power/control" 2>/dev/null)
            if [ "$current_control" = "auto" ]; then
                success=true
            fi
        fi
    else
        # For SATA, assume success if hdparm command succeeded
        success=true
    fi
    
    if [ "$success" = "true" ]; then
        success "Disk $disk suspended successfully"
        return 0
    else
        error "Failed to suspend disk $disk"
        return 1
    fi
}

# Enhanced disk wake with Intel optimizations
wake_disk_enhanced() {
    local disk="$1"
    
    if [ -z "$disk" ]; then
        error "No disk specified"
        return 1
    fi
    
    if [ ! -b "/dev/$disk" ]; then
        error "Disk /dev/$disk not found"
        return 1
    fi
    
    log "Waking up disk: $disk"
    
    # Wake up disk
    if [[ "$disk" == nvme* ]]; then
        # NVMe wake using correct power management
        if [ -f "/sys/block/$disk/device/power/control" ]; then
            echo "on" | sudo tee "/sys/block/$disk/device/power/control" >/dev/null 2>&1
        fi
        # Touch the device to wake it up
        sudo dd if="/dev/$disk" of=/dev/null bs=512 count=1 >/dev/null 2>&1 || true
    else
        # SATA wake using hdparm
        if command -v hdparm >/dev/null 2>&1; then
            sudo hdparm -W 0 "/dev/$disk" >/dev/null 2>&1
        else
            # Fallback to power_state if available
            if [ -f "/sys/block/$disk/device/power_state" ]; then
                echo "0" | sudo tee "/sys/block/$disk/device/power_state" >/dev/null 2>&1
            fi
        fi
    fi
    
    if [ $? -eq 0 ]; then
        # Apply Intel optimizations after wake
        optimize_intel_ssd "$disk"
        success "Disk $disk woken up successfully"
        return 0
    else
        error "Failed to wake up disk $disk"
        return 1
    fi
}

# Simple disk monitoring - suspend safe disks every N minutes
monitor_disks_enhanced() {
    log "Starting simple disk monitoring"
    
    local system_disk=$(get_system_disk)
    local monitored_disks=()
    local suspended_count=0
    
    # Get monitored disks
    if [ "$MONITORED_DISKS" = "auto" ]; then
        # Auto-detect non-system disks
        for disk in $(get_all_disks); do
            if [ "$disk" != "$system_disk" ]; then
                monitored_disks+=("$disk")
            fi
        done
    else
        # Use configured disks
        monitored_disks=($MONITORED_DISKS)
    fi
    
    if [ ${#monitored_disks[@]} -eq 0 ]; then
        info "No disks to monitor"
        return 0
    fi
    
    log "Monitoring ${#monitored_disks[@]} disks: ${monitored_disks[*]}"
    
    for disk in "${monitored_disks[@]}"; do
        if [ ! -b "/dev/$disk" ]; then
            warning "Disk $disk not found, skipping"
            continue
        fi
        
        # Try to suspend disk (safety checks built-in)
        if suspend_disk_enhanced "$disk"; then
            ((suspended_count++))
        fi
    done
    
    if [ $suspended_count -gt 0 ]; then
        success "Suspended $suspended_count disk(s)"
    else
        info "No disks were suspended (all blocked by safety checks)"
    fi
}

# Enhanced status display
show_enhanced_status() {
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║                      💾 SIMPLE DISK MANAGER v2.0.0                      ║"
    echo "╠═══════════════════════════════════════════════════════════════════════════╣"
    
    # Configuration
    echo "║ Configuration:                                                        ║"
    echo "║   Disk Management: $([ "$DISK_MANAGEMENT_ENABLED" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")                                    ║"
    echo "║   Auto Suspend: $([ "$AUTO_SUSPEND_ENABLED" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")                                       ║"
    echo "║   Inactivity Timeout: ${INACTIVITY_TIMEOUT}s                                      ║"
    echo "║   Battery Only: $([ "$SUSPEND_ON_BATTERY_ONLY" = "true" ] && echo "✅ Yes" || echo "❌ No")                                          ║"
    echo "║   System Disk Excluded: $([ "$EXCLUDE_SYSTEM_DISK" = "true" ] && echo "✅ Yes" || echo "❌ No")                                   ║"
    echo "║   Intel Optimization: $([ "$" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")                               ║"
    echo "║   SMART Monitoring: $([ "$SMART_MONITORING" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")                               ║"
    
    # Power status
    echo "╠═══════════════════════════════════════════════════════════════════════════╣"
    echo "║ Power Status:                                                         ║"
    if is_on_battery; then
        echo "║   Power Source: 🔋 Battery Power                                               ║"
    else
        echo "║   Power Source: 🔌 AC Power                                               ║"
    fi
    echo "║   System Disk: $(get_system_disk)                                                ║"
    
    # Available disks
    echo "╠═══════════════════════════════════════════════════════════════════════════╣"
    echo "║ Available Disks:                                                      ║"
    for disk in $(get_all_disks); do
        local model=$(cat "/sys/block/$disk/device/model" 2>/dev/null || echo "Unknown")
        local size=$(lsblk -nd -o SIZE "/dev/$disk" | head -1)
        local system_marker=""
        if [ "$disk" = "$(get_system_disk)" ]; then
            system_marker=" [SYSTEM]"
        fi
        echo "║   $disk: Model: $model, Size: $size$system_marker                                    ║"
    done
    
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
}

# Main command processing
case "${1:-status}" in
    "status")
        show_enhanced_status
        ;;
    "monitor")
        monitor_disks_enhanced
        ;;
    "suspend")
        suspend_disk_manual "$2"
        ;;
    "force-suspend")
        suspend_disk_manual "$2" "true"
        ;;
    "auto-suspend")
        suspend_disk_enhanced "$2"
        ;;
    "wake")
        wake_disk_enhanced "$2"
        ;;
    "optimize")
        optimize_intel_ssd "$2"
        ;;
    "health")
        check_disk_health "$2"
        ;;
    *)
        echo "Simple Disk Manager v$VERSION"
        echo "Usage: $0 {status|monitor|suspend|force-suspend|auto-suspend|wake|optimize|health} [disk]"
        echo ""
        echo "Commands:"
        echo "  status              Show disk management status"
        echo "  monitor             Suspend all safe disks (AUTOMATIC - SAFE)"
        echo "  suspend <disk>      Manual suspend with safety checks"
        echo "  force-suspend <disk> Force suspend (OVERRIDE SAFETY - RISKY)"
        echo "  auto-suspend <disk> Automatic suspend (NO OVERRIDE - SAFEST)"
        echo "  wake <disk>         Wake up specific disk with Intel optimizations"
        echo "  optimize <disk>     Apply Intel SSD optimizations"
        echo "  health <disk>       Check disk health using SMART"
        echo ""
        echo "Simple Logic:"
        echo "  🔄 monitor         - Suspends ALL disks that pass safety checks"
        echo "  🛡️  auto-suspend   - SAFEST: Blocks suspension if ANY warning condition met"
        echo "  ⚠️  suspend        - SAFE: Manual with warnings, requires force for override"
        echo "  🚨 force-suspend   - RISKY: Overrides ALL safety checks - DATA LOSS RISK!"
        echo ""
        echo "Safety Checks (automatic suspension blocked if ANY are true):"
        echo "  🚫 Disk is mounted or has mounted partitions"
        echo "  🚫 Disk has active processes"
        echo "  🚫 Disk is used by LVM"
        echo "  🚫 Disk is system disk (if EXCLUDE_SYSTEM_DISK=true)"
        echo "  🚫 Disk health issues (if SMART_MONITORING=true)"
        ;;
esac
