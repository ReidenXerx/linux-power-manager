#!/bin/bash

# Linux Power Manager - Disk Management Module
# Automatic and on-demand disk suspension system
# Version: 1.0.0

VERSION="1.0.0"
CONFIG_FILE="$HOME/.config/power-control.conf"
DISK_CONFIG_FILE="$HOME/.config/disk-manager.conf"
ACTIVITY_LOG="/tmp/disk-activity.log"
WHITELIST_FILE="/tmp/disk-manager-whitelist"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
MAGENTA='\033[0;95m'
NC='\033[0m' # No Color

# Create config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Initialize disk management configuration if it doesn't exist
if [ ! -f "$DISK_CONFIG_FILE" ]; then
    cat > "$DISK_CONFIG_FILE" << DISK_CONF_EOF
# Disk Management Configuration
DISK_MANAGEMENT_ENABLED=true
AUTO_SUSPEND_ENABLED=true
INACTIVITY_TIMEOUT=300
SUSPEND_ON_BATTERY_ONLY=true
MONITORED_DISKS="auto"
EXCLUDE_SYSTEM_DISK=true
LOG_DISK_ACTIVITY=false
NVME_POWER_MANAGEMENT=true
DISK_CONF_EOF
fi

# Source configurations
source "$CONFIG_FILE" 2>/dev/null || true
source "$DISK_CONFIG_FILE" 2>/dev/null || true

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# ============================================================================
# DISK DETECTION AND MANAGEMENT FUNCTIONS
# ============================================================================

# Check if running on battery
is_on_battery() {
    local battery_path="/sys/class/power_supply/BAT0"
    if [ -d "$battery_path" ]; then
        local status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
        [ "$status" = "Discharging" ]
    else
        # Use acpi as fallback
        if command -v acpi > /dev/null 2>&1; then
            acpi -b | grep -q "Discharging"
        else
            # Assume on battery if we can't determine (conservative approach)
            return 0
        fi
    fi
}

# Get all available disks
get_all_disks() {
    lsblk -nd -o NAME,TYPE,SIZE | awk '$2=="disk" && $3!="0B" {print $1}' | sort
}

# Get system/root disk
get_system_disk() {
    local root_mount=$(df / | tail -1 | awk '{print $1}')
    local system_disk="unknown"
    
    # Handle different root device types
    if [[ "$root_mount" == /dev/mapper/* ]]; then
        # For LUKS/LVM devices, trace back to physical disk
        # Get the underlying block device from the mapper
        local underlying_device=$(lsblk -no NAME "$root_mount" | tail -n +2 | head -1)
        if [ -z "$underlying_device" ]; then
            # Alternative method: parse lsblk tree to find the physical disk
            system_disk=$(lsblk -no NAME | grep -B 20 "$(basename "$root_mount")" | grep -E "^[a-z]+[0-9]+n[0-9]+$|^sd[a-z]+$" | tail -1)
        else
            # Get the parent disk from the underlying device
            system_disk=$(lsblk -no PKNAME "/dev/$underlying_device" 2>/dev/null | head -1)
            if [ -z "$system_disk" ]; then
                # Extract disk name from partition (e.g., nvme1n1p3 -> nvme1n1)
                system_disk=$(echo "$underlying_device" | sed 's/p[0-9]*$//' | sed 's/[0-9]*$//')
            fi
        fi
    elif [[ "$root_mount" == /dev/nvme* ]]; then
        # Direct NVMe partition
        system_disk=$(echo "$root_mount" | sed 's|/dev/||' | sed 's/p[0-9]*$//')
    elif [[ "$root_mount" == /dev/sd* ]]; then
        # Direct SATA partition
        system_disk=$(echo "$root_mount" | sed 's|/dev/||' | sed 's/[0-9]*$//')
    else
        # Fallback: try lsblk PKNAME
        system_disk=$(lsblk -no PKNAME "$root_mount" 2>/dev/null | head -1)
    fi
    
    # Additional validation - trace through lsblk tree if still unknown
    if [ "$system_disk" = "unknown" ] || [ -z "$system_disk" ]; then
        # Get all physical disks and check which one contains the root filesystem
        local all_disks=$(lsblk -nd -o NAME,TYPE | awk '$2=="disk" {print $1}')
        for disk in $all_disks; do
            if lsblk "/dev/$disk" | grep -q "$(basename "$root_mount")"; then
                system_disk="$disk"
                break
            fi
        done
    fi
    
    echo "${system_disk:-unknown}"
}

# Get monitored disks based on configuration
get_monitored_disks() {
    local system_disk=$(get_system_disk)
    
    if [ "$MONITORED_DISKS" = "auto" ]; then
        # Auto-detect non-system disks
        local all_disks=($(get_all_disks))
        local monitored=()
        
        for disk in "${all_disks[@]}"; do
            if [ "$EXCLUDE_SYSTEM_DISK" = "true" ] && [ "$disk" = "$system_disk" ]; then
                continue
            fi
            monitored+=("$disk")
        done
        
        printf '%s\n' "${monitored[@]}"
    else
        # Use configured disk list
        echo "$MONITORED_DISKS" | tr ',' '\n' | tr ' ' '\n' | grep -v '^$'
    fi
}

# Check if disk exists and is manageable
is_disk_manageable() {
    local disk="$1"
    
    # Check if disk exists
    if [ ! -b "/dev/$disk" ]; then
        return 1
    fi
    
    # Check if it's a physical disk (not a partition)
    if ! lsblk -nd "/dev/$disk" > /dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Get disk model and info
get_disk_info() {
    local disk="$1"
    
    if [ -f "/sys/block/$disk/device/model" ]; then
        local model=$(cat "/sys/block/$disk/device/model" 2>/dev/null | xargs)
        local size=$(lsblk -nd -o SIZE "/dev/$disk" 2>/dev/null)
        echo "Model: $model, Size: $size"
    elif command -v lsblk > /dev/null 2>&1; then
        lsblk -nd -o SIZE,MODEL "/dev/$disk" 2>/dev/null | awk '{print "Size: " $1 ", Model: " $2}'
    else
        echo "Unknown"
    fi
}

# Check disk activity
get_disk_activity() {
    local disk="$1"
    local stats_file="/sys/block/$disk/stat"
    
    if [ -f "$stats_file" ]; then
        # Read I/O stats: reads, writes
        awk '{print $1 + $5}' "$stats_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Check if disk is currently suspended/sleeping
is_disk_sleeping() {
    local disk="$1"
    
    # For NVMe drives, check power state using nvme-cli
    if [[ "$disk" == nvme* ]] && command -v nvme > /dev/null 2>&1; then
        local power_state=$(sudo nvme get-feature -f 0x02 "/dev/$disk" 2>/dev/null | sed -n 's/.*Current value:0x0*\([0-9a-f]*\).*/\1/p' | tail -c 2)
        # Convert hex to decimal for power state comparison
        local power_state_dec=$((0x${power_state:-0}))
        # Power states > 0 indicate low power modes (state 0 = active, >0 = various low power states)
        if [ "$power_state_dec" -gt 0 ] 2>/dev/null; then
            return 0
        else
            return 1
        fi
    elif [[ "$disk" == nvme* ]]; then
        # Fallback: check runtime PM status
        local nvme_path="/sys/block/$disk/device"
        if [ -f "$nvme_path/power/runtime_status" ]; then
            local runtime_status=$(cat "$nvme_path/power/runtime_status" 2>/dev/null || echo "unsupported")
            [ "$runtime_status" = "suspended" ]
        else
            return 1
        fi
    else
        # For SATA drives, use hdparm if available
        if command -v hdparm > /dev/null 2>&1; then
            local state=$(sudo hdparm -C "/dev/$disk" 2>/dev/null | grep "drive state" | awk '{print $NF}')
            [ "$state" = "standby" ] || [ "$state" = "sleeping" ]
        else
            return 1
        fi
    fi
}

# ============================================================================
# WHITELIST MANAGEMENT FUNCTIONS
# ============================================================================

# Add disk to temporary whitelist (prevents automatic suspension)
add_to_whitelist() {
    local disk="$1"
    local duration="${2:-3600}"  # Default 1 hour
    
    # Remove existing entries for this disk to prevent duplicates
    remove_from_whitelist "$disk"
    
    # Handle never expire case (duration=0)
    local expiry_time
    if [ "$duration" -eq 0 ]; then
        expiry_time=2147483647  # Unix timestamp max (year 2038) for "never expire"
        info "Added $disk to whitelist (never expires - remove manually or suspend disk)"
    else
        expiry_time=$(($(date +%s) + duration))
        info "Added $disk to whitelist for $duration seconds"
    fi
    
    # Create whitelist entry: disk:expiry_timestamp
    echo "$disk:$expiry_time" >> "$WHITELIST_FILE"
}

# Remove disk from whitelist
remove_from_whitelist() {
    local disk="$1"
    
    if [ -f "$WHITELIST_FILE" ]; then
        grep -v "^$disk:" "$WHITELIST_FILE" > "${WHITELIST_FILE}.tmp" || true
        mv "${WHITELIST_FILE}.tmp" "$WHITELIST_FILE" 2>/dev/null || true
        # Remove empty whitelist file
        [ ! -s "$WHITELIST_FILE" ] && rm -f "$WHITELIST_FILE"
        info "Removed $disk from whitelist"
    fi
}

# Check if disk is whitelisted (not expired)
is_whitelisted() {
    local disk="$1"
    local current_time=$(date +%s)
    
    if [ ! -f "$WHITELIST_FILE" ]; then
        return 1
    fi
    
    while IFS=':' read -r whitelisted_disk expiry_time; do
        if [ "$whitelisted_disk" = "$disk" ]; then
            if [ "$current_time" -lt "$expiry_time" ]; then
                return 0  # Disk is whitelisted and not expired
            else
                # Remove expired entry
                remove_from_whitelist "$disk"
                return 1
            fi
        fi
    done < "$WHITELIST_FILE"
    
    return 1
}

# Clean expired entries from whitelist
clean_whitelist() {
    local current_time=$(date +%s)
    local temp_file="${WHITELIST_FILE}.cleaning"
    
    if [ ! -f "$WHITELIST_FILE" ]; then
        return 0
    fi
    
    while IFS=':' read -r disk expiry_time; do
        if [ "$current_time" -lt "$expiry_time" ]; then
            echo "$disk:$expiry_time" >> "$temp_file"
        fi
    done < "$WHITELIST_FILE"
    
    if [ -f "$temp_file" ]; then
        mv "$temp_file" "$WHITELIST_FILE"
    else
        rm -f "$WHITELIST_FILE"
    fi
}

# Show current whitelist
show_whitelist() {
    echo -e "${CYAN}🛡️  Current Disk Whitelist:${NC}"
    echo "========================"
    
    if [ ! -f "$WHITELIST_FILE" ]; then
        echo "No disks currently whitelisted"
        return
    fi
    
    local current_time=$(date +%s)
    local found_active=false
    
    while IFS=':' read -r disk expiry_time; do
        if [ "$current_time" -lt "$expiry_time" ]; then
            # Check if it's a "never expire" entry (year 2038 timestamp)
            if [ "$expiry_time" -eq 2147483647 ]; then
                echo -e "${YELLOW}$disk${NC}: Protected ${GREEN}forever${NC} (never expires)"
            else
                local remaining=$((expiry_time - current_time))
                local hours=$((remaining / 3600))
                local minutes=$(((remaining % 3600) / 60))
                echo -e "${YELLOW}$disk${NC}: Protected for ${hours}h ${minutes}m"
            fi
            found_active=true
        fi
    done < "$WHITELIST_FILE"
    
    if [ "$found_active" = "false" ]; then
        echo "No disks currently whitelisted (all entries expired)"
        rm -f "$WHITELIST_FILE"
    fi
}

# ============================================================================
# DISK SUSPENSION FUNCTIONS
# ============================================================================

# Suspend a disk
suspend_disk() {
    local disk="$1"
    local force="${2:-false}"
    
    if ! is_disk_manageable "$disk"; then
        error "Disk $disk is not manageable"
        return 1
    fi
    
    # Check if disk is already sleeping
    if is_disk_sleeping "$disk"; then
        info "Disk $disk is already suspended"
        
        # Remove from whitelist even if already suspended (handles never-expire case)
        if is_whitelisted "$disk"; then
            remove_from_whitelist "$disk"
            info "🚫 Removed $disk from whitelist (already suspended - resuming automatic management)"
        fi
        
        return 0
    fi
    
    # Check if we should only suspend on battery
    if [ "$SUSPEND_ON_BATTERY_ONLY" = "true" ] && [ "$force" != "true" ]; then
        if ! is_on_battery; then
            info "Not suspending $disk - AC power detected (SUSPEND_ON_BATTERY_ONLY=true)"
            return 0
        fi
    fi
    
    log "Suspending disk $disk..."
    
    # Sync filesystem data first
    sync
    
    local success=false
    
    # Handle NVMe drives
    if [[ "$disk" == nvme* ]] && [ "$NVME_POWER_MANAGEMENT" = "true" ]; then
        local nvme_path="/sys/block/$disk/device"
        
        # Try to put NVMe device into low power state
        if [ -f "$nvme_path/power/control" ]; then
            if echo "auto" | sudo tee "$nvme_path/power/control" > /dev/null 2>&1; then
                success=true
            fi
        fi
        
        # Additional NVMe power saving
        if [ -f "$nvme_path/queue/scheduler" ]; then
            echo "none" | sudo tee "$nvme_path/queue/scheduler" > /dev/null 2>&1
        fi
        
    else
        # Handle SATA drives with hdparm
        if command -v hdparm > /dev/null 2>&1; then
            # Put drive to standby immediately
            if sudo hdparm -y "/dev/$disk" > /dev/null 2>&1; then
                success=true
            fi
            
            # Set spindown timeout (5 minutes = 60 * 5 seconds)
            sudo hdparm -S 60 "/dev/$disk" > /dev/null 2>&1
        fi
    fi
    
    if [ "$success" = "true" ]; then
        success "Disk $disk suspended successfully"
        
        # Remove from whitelist if manually suspended
        # This handles the case where a user manually suspends a disk that was set to "never expire"
        if is_whitelisted "$disk"; then
            remove_from_whitelist "$disk"
            info "🚫 Removed $disk from whitelist (manually suspended - resuming automatic management)"
        fi
        
        # Log activity if enabled
        if [ "$LOG_DISK_ACTIVITY" = "true" ]; then
            echo "$(date): Suspended disk $disk" >> "$ACTIVITY_LOG"
        fi
        
        return 0
    else
        warning "Failed to suspend disk $disk"
        return 1
    fi
}

# Wake up a disk
wake_disk() {
    local disk="$1"
    local auto_whitelist="${2:-true}"  # Default: add to whitelist when manually woken
    
    if ! is_disk_manageable "$disk"; then
        error "Disk $disk is not manageable"
        return 1
    fi
    
    log "Waking up disk $disk..."
    
    local success=false
    
    # Handle NVMe drives
    if [[ "$disk" == nvme* ]]; then
        local nvme_path="/sys/block/$disk/device"
        
        if [ -f "$nvme_path/power/control" ]; then
            if echo "on" | sudo tee "$nvme_path/power/control" > /dev/null 2>&1; then
                success=true
            fi
        fi
        
        # Touch the device to wake it up
        sudo dd if="/dev/$disk" of=/dev/null bs=512 count=1 > /dev/null 2>&1 || true
        
    else
        # Handle SATA drives
        # Simple read operation to wake up the drive
        sudo dd if="/dev/$disk" of=/dev/null bs=512 count=1 > /dev/null 2>&1 && success=true
    fi
    
    if [ "$success" = "true" ]; then
        success "Disk $disk woken up successfully"
        
        # Add to whitelist using configured default expiry
        if [ "$auto_whitelist" = "true" ]; then
            # Check if disk is already whitelisted and preserve never-expire setting
            local was_whitelisted=false
            local was_never_expire=false
            if is_whitelisted "$disk"; then
                was_whitelisted=true
                # Check if it was never-expire by checking the timestamp
                local current_time=$(date +%s)
                while IFS=':' read -r whitelisted_disk expiry_time; do
                    if [ "$whitelisted_disk" = "$disk" ] && [ "$expiry_time" -eq 2147483647 ]; then
                        was_never_expire=true
                        break
                    fi
                done < "$WHITELIST_FILE" 2>/dev/null
            fi
            
            # If disk was on never-expire whitelist, preserve that setting
            if [ "$was_never_expire" = "true" ]; then
                add_to_whitelist "$disk" 0  # Restore never-expire
                info "🛡️  $disk restored to never-expire whitelist protection"
            else
                # Use configured default expiry
                local default_expiry="${WHITELIST_DEFAULT_EXPIRY:-3600}"
                add_to_whitelist "$disk" "$default_expiry"
                if [ "$default_expiry" -eq 0 ]; then
                    info "🛡️  $disk protected from auto-suspension forever (never expires)"
                else
                    local hours=$((default_expiry / 3600))
                    local minutes=$(((default_expiry % 3600) / 60))
                    if [ $hours -gt 0 ]; then
                        info "🛡️  $disk protected from auto-suspension for ${hours}h ${minutes}m"
                    else
                        info "🛡️  $disk protected from auto-suspension for ${minutes}m"
                    fi
                fi
            fi
        fi
        
        # Log activity if enabled
        if [ "$LOG_DISK_ACTIVITY" = "true" ]; then
            echo "$(date): Woken up disk $disk" >> "$ACTIVITY_LOG"
        fi
        
        return 0
    else
        warning "Failed to wake up disk $disk"
        return 1
    fi
}

# Monitor disk activity and suspend inactive disks
monitor_and_suspend() {
    local timeout="${INACTIVITY_TIMEOUT:-300}"
    
    if [ "$DISK_MANAGEMENT_ENABLED" != "true" ] || [ "$AUTO_SUSPEND_ENABLED" != "true" ]; then
        info "Automatic disk suspension is disabled"
        return 0
    fi
    
    log "Starting disk activity monitoring (timeout: ${timeout}s)"
    
    local monitored_disks=($(get_monitored_disks))
    if [ ${#monitored_disks[@]} -eq 0 ]; then
        warning "No disks configured for monitoring"
        return 1
    fi
    
    info "Monitoring disks: ${monitored_disks[*]}"
    
    # Initialize activity tracking
    declare -A last_activity
    declare -A current_activity
    
    # Get initial activity levels
    for disk in "${monitored_disks[@]}"; do
        if is_disk_manageable "$disk"; then
            last_activity[$disk]=$(get_disk_activity "$disk")
        fi
    done
    
    # Wait for the timeout period
    sleep "$timeout"
    
    # Clean expired whitelist entries
    clean_whitelist
    
    # Check activity and suspend inactive disks
    local suspended_count=0
    local whitelisted_count=0
    
    for disk in "${monitored_disks[@]}"; do
        if ! is_disk_manageable "$disk"; then
            continue
        fi
        
        # Check if disk is whitelisted (manually woken recently)
        if is_whitelisted "$disk"; then
            info "🛡️  Disk $disk is whitelisted, skipping auto-suspension"
            ((whitelisted_count++))
            continue
        fi
        
        current_activity[$disk]=$(get_disk_activity "$disk")
        
        # Compare activity levels
        if [ "${current_activity[$disk]}" -eq "${last_activity[$disk]}" ] 2>/dev/null; then
            # No activity detected, suspend disk
            if suspend_disk "$disk"; then
                ((suspended_count++))
            fi
        else
            info "Disk $disk has activity, keeping active"
        fi
    done
    
    if [ $suspended_count -gt 0 ]; then
        success "Suspended $suspended_count inactive disk(s)"
    else
        info "No disks suspended - all have recent activity"
    fi
}

# ============================================================================
# STATUS AND DISPLAY FUNCTIONS
# ============================================================================

# Show comprehensive disk status
show_disk_status() {
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                    ${CYAN}💾 DISK MANAGEMENT STATUS v${VERSION}${NC}                     ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Configuration Status
    echo -e "${PURPLE}║${NC} ${YELLOW}Configuration:${NC}                                                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}   Disk Management: $([ "$DISK_MANAGEMENT_ENABLED" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")                                    ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}   Auto Suspend: $([ "$AUTO_SUSPEND_ENABLED" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")                                       ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}   Inactivity Timeout: ${INACTIVITY_TIMEOUT}s                                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}   Battery Only: $([ "$SUSPEND_ON_BATTERY_ONLY" = "true" ] && echo "✅ Yes" || echo "❌ No")                                          ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}   System Disk Excluded: $([ "$EXCLUDE_SYSTEM_DISK" = "true" ] && echo "✅ Yes" || echo "❌ No")                                   ${PURPLE}║${NC}"
    
    # Power Status
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC} ${YELLOW}Power Status:${NC}                                                         ${PURPLE}║${NC}"
    if is_on_battery; then
        echo -e "${PURPLE}║${NC}   Power Source: 🔋 Battery (disk suspension active)                       ${PURPLE}║${NC}"
    else
        echo -e "${PURPLE}║${NC}   Power Source: 🔌 AC Power                                               ${PURPLE}║${NC}"
    fi
    
    # System Disk Info
    local system_disk=$(get_system_disk)
    echo -e "${PURPLE}║${NC}   System Disk: $system_disk                                                ${PURPLE}║${NC}"
    
    # Monitored Disks
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC} ${YELLOW}Monitored Disks:${NC}                                                      ${PURPLE}║${NC}"
    
    local monitored_disks=($(get_monitored_disks))
    if [ ${#monitored_disks[@]} -eq 0 ]; then
        echo -e "${PURPLE}║${NC}   No disks configured for monitoring                                     ${PURPLE}║${NC}"
    else
        for disk in "${monitored_disks[@]}"; do
            if is_disk_manageable "$disk"; then
                local disk_info=$(get_disk_info "$disk")
                local sleep_status="❓ Unknown"
                
                if is_disk_sleeping "$disk"; then
                    sleep_status="💤 Sleeping"
                else
                    sleep_status="⚡ Active"
                fi
                
                echo -e "${PURPLE}║${NC}   $disk: $sleep_status                                           ${PURPLE}║${NC}"
                echo -e "${PURPLE}║${NC}     $disk_info                                               ${PURPLE}║${NC}"
            else
                echo -e "${PURPLE}║${NC}   $disk: ❌ Not manageable                                         ${PURPLE}║${NC}"
            fi
        done
    fi
    
    # All Available Disks
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC} ${YELLOW}All Available Disks:${NC}                                                  ${PURPLE}║${NC}"
    
    local all_disks=($(get_all_disks))
    for disk in "${all_disks[@]}"; do
        local disk_info=$(get_disk_info "$disk")
        local marker=""
        
        if [ "$disk" = "$system_disk" ]; then
            marker=" ${YELLOW}[SYSTEM]${NC}"
        fi
        
        echo -e "${PURPLE}║${NC}   $disk: $disk_info$marker                                    ${PURPLE}║${NC}"
    done
    
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
}

# List all disks with detailed info
list_disks() {
    echo -e "${BLUE}💾 Available Disks for Management:${NC}"
    echo "=================================="
    
    local all_disks=($(get_all_disks))
    local system_disk=$(get_system_disk)
    
    for disk in "${all_disks[@]}"; do
        local disk_info=$(get_disk_info "$disk")
        local status_info=""
        
        if [ "$disk" = "$system_disk" ]; then
            status_info=" ${YELLOW}[SYSTEM DISK]${NC}"
        fi
        
        if is_disk_sleeping "$disk"; then
            status_info="$status_info ${BLUE}[SLEEPING]${NC}"
        else
            status_info="$status_info ${GREEN}[ACTIVE]${NC}"
        fi
        
        echo -e "${CYAN}$disk${NC}: $disk_info$status_info"
    done
}

# ============================================================================
# CONFIGURATION FUNCTIONS
# ============================================================================

# Configure disk management settings
configure_disk_management() {
    echo -e "${BLUE}🔧 Disk Management Configuration${NC}"
    echo "================================="
    echo "Current settings:"
    echo "  Disk management enabled: $DISK_MANAGEMENT_ENABLED"
    echo "  Auto suspend enabled: $AUTO_SUSPEND_ENABLED"
    echo "  Inactivity timeout: $INACTIVITY_TIMEOUT seconds"
    echo "  Suspend on battery only: $SUSPEND_ON_BATTERY_ONLY"
    echo "  Exclude system disk: $EXCLUDE_SYSTEM_DISK"
    echo "  Monitored disks: $MONITORED_DISKS"
    echo "  Log disk activity: $LOG_DISK_ACTIVITY"
    echo "  NVMe power management: $NVME_POWER_MANAGEMENT"
    echo ""
    
    read -p "Enable disk management? (y/n): " disk_mgmt
    read -p "Enable automatic suspension? (y/n): " auto_suspend
    read -p "Inactivity timeout in seconds [300]: " timeout
    read -p "Suspend only on battery power? (y/n): " battery_only
    read -p "Exclude system disk from suspension? (y/n): " exclude_system
    read -p "Enable activity logging? (y/n): " logging
    read -p "Enable NVMe power management? (y/n): " nvme_pm
    
    # Set defaults
    timeout=${timeout:-300}
    
    # Configure monitored disks
    echo ""
    echo "Available disks:"
    list_disks
    echo ""
    echo "Disk configuration options:"
    echo "  'auto' - Automatically manage all non-system disks"
    echo "  'nvme0n1,nvme1n1' - Specific comma-separated disk list"
    echo "  'none' - Disable disk monitoring"
    read -p "Monitored disks [auto]: " monitored
    monitored=${monitored:-auto}
    
    # Save configuration
    DISK_MANAGEMENT_ENABLED=$([ "$disk_mgmt" = "y" ] && echo "true" || echo "false")
    AUTO_SUSPEND_ENABLED=$([ "$auto_suspend" = "y" ] && echo "true" || echo "false")
    INACTIVITY_TIMEOUT="$timeout"
    SUSPEND_ON_BATTERY_ONLY=$([ "$battery_only" = "y" ] && echo "true" || echo "false")
    EXCLUDE_SYSTEM_DISK=$([ "$exclude_system" = "y" ] && echo "true" || echo "false")
    LOG_DISK_ACTIVITY=$([ "$logging" = "y" ] && echo "true" || echo "false")
    NVME_POWER_MANAGEMENT=$([ "$nvme_pm" = "y" ] && echo "true" || echo "false")
    MONITORED_DISKS="$monitored"
    
    cat > "$DISK_CONFIG_FILE" << DISK_CONF_EOF
# Disk Management Configuration
DISK_MANAGEMENT_ENABLED=$DISK_MANAGEMENT_ENABLED
AUTO_SUSPEND_ENABLED=$AUTO_SUSPEND_ENABLED
INACTIVITY_TIMEOUT=$INACTIVITY_TIMEOUT
SUSPEND_ON_BATTERY_ONLY=$SUSPEND_ON_BATTERY_ONLY
MONITORED_DISKS="$MONITORED_DISKS"
EXCLUDE_SYSTEM_DISK=$EXCLUDE_SYSTEM_DISK
LOG_DISK_ACTIVITY=$LOG_DISK_ACTIVITY
NVME_POWER_MANAGEMENT=$NVME_POWER_MANAGEMENT
DISK_CONF_EOF
    
    success "Disk management configuration saved!"
}

# ============================================================================
# HELP AND MAIN PROCESSING
# ============================================================================

show_help() {
    echo -e "${CYAN}💾 Linux Power Manager - Disk Management Module v${VERSION}${NC}"
    echo "=================================================================="
    echo ""
    echo -e "${YELLOW}Disk Management Commands:${NC}"
    echo "  status               - Show comprehensive disk management status"
    echo "  list                 - List all available disks"
    echo "  suspend <disk>       - Suspend specific disk (e.g., nvme1n1)"
    echo "  suspend-all          - Suspend all monitored disks"
    echo "  wake <disk>          - Wake up specific disk"
    echo "  wake-all             - Wake up all disks"
    echo "  force-suspend <disk> - Force suspend disk (ignore battery check)"
    echo ""
    echo -e "${YELLOW}Monitoring Commands:${NC}"
    echo "  monitor              - Run one-time disk activity monitoring"
    echo "  monitor-daemon       - Start continuous monitoring (SAFE - auto-stops after 24h)"
    echo "  stop-daemon          - Stop running monitoring daemon"
    echo ""
    echo -e "${YELLOW}Configuration Commands:${NC}"
    echo "  config               - Configure disk management settings"
    echo "  enable               - Enable disk management"
    echo "  disable              - Disable disk management"
    echo ""
    echo -e "${YELLOW}Whitelist Commands:${NC}"
    echo "  whitelist            - Show current whitelist"
    echo "  whitelist-add <disk> [duration] - Add disk to whitelist (default: ${WHITELIST_DEFAULT_EXPIRY:-3600}s)"
    echo "  whitelist-remove <disk> - Remove disk from whitelist"
    echo "  whitelist-clear      - Clear entire whitelist"
    echo ""
    echo -e "${YELLOW}Information Commands:${NC}"
    echo "  activity <disk>      - Show current disk activity"
    echo "  sleeping <disk>      - Check if disk is sleeping"
    echo "  system-disk          - Show system disk"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 suspend nvme1n1           # Suspend secondary NVMe drive"
    echo "  $0 suspend-all               # Suspend all monitored disks"
    echo "  $0 monitor                   # Check and suspend inactive disks"
    echo "  $0 config                    # Configure disk management"
    echo ""
    echo -e "${YELLOW}Current Configuration:${NC}"
    echo "  Disk Management: $([ "$DISK_MANAGEMENT_ENABLED" = "true" ] && echo "Enabled" || echo "Disabled")"
    echo "  Auto Suspend: $([ "$AUTO_SUSPEND_ENABLED" = "true" ] && echo "Enabled" || echo "Disabled")"
    echo "  Monitored Disks: $MONITORED_DISKS"
    echo "  Timeout: $INACTIVITY_TIMEOUT seconds"
}

# ============================================================================
# MAIN COMMAND PROCESSING
# ============================================================================

case "$1" in
    "status")
        show_disk_status
        ;;
    "list")
        list_disks
        ;;
    "suspend")
        if [ -n "$2" ]; then
            suspend_disk "$2"
        else
            error "Please specify disk name (e.g., nvme1n1)"
            exit 1
        fi
        ;;
    "suspend-all")
        log "Suspending all monitored disks..."
        suspended=0
        monitored_disks=($(get_monitored_disks))
        for disk in "${monitored_disks[@]}"; do
            if suspend_disk "$disk"; then
                ((suspended++))
            fi
        done
        success "Suspended $suspended disk(s)"
        ;;
    "wake")
        if [ -n "$2" ]; then
            wake_disk "$2"
        else
            error "Please specify disk name (e.g., nvme1n1)"
            exit 1
        fi
        ;;
    "wake-all")
        log "Waking up all disks..."
        woken=0
        all_disks=($(get_all_disks))
        for disk in "${all_disks[@]}"; do
            if wake_disk "$disk"; then
                ((woken++))
            fi
        done
        success "Woken up $woken disk(s)"
        ;;
    "force-suspend")
        if [ -n "$2" ]; then
            suspend_disk "$2" "true"
        else
            error "Please specify disk name (e.g., nvme1n1)"
            exit 1
        fi
        ;;
    "monitor")
        monitor_and_suspend
        ;;
    "monitor-daemon")
        log "Starting continuous disk monitoring daemon..."
        # Safety measures to prevent system freezes
        max_iterations=1440  # 24 hours at 1-minute intervals
        iteration_count=0
        consecutive_errors=0
        max_consecutive_errors=5
        
        # Create PID file for daemon management
        pid_file="/tmp/disk-manager-daemon.pid"
        echo $$ > "$pid_file"
        
        # Trap signals for clean exit
        trap 'log "Disk monitoring daemon stopped"; rm -f "$pid_file"; exit 0' TERM INT
        
        while [ $iteration_count -lt $max_iterations ]; do
            # Memory usage check - exit if system is under memory pressure
            available_mem=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo "1000")
            if [ "$available_mem" -lt 200 ]; then
                warning "Low memory detected ($available_mem MB), stopping daemon to prevent system issues"
                break
            fi
            
            # Check if daemon should continue running
            if [ ! -f "$pid_file" ]; then
                log "PID file removed, stopping daemon"
                break
            fi
            
            # Run monitoring with error handling
            if monitor_and_suspend; then
                consecutive_errors=0
            else
                ((consecutive_errors++))
                warning "Monitoring cycle $iteration_count failed (consecutive errors: $consecutive_errors)"
                
                if [ $consecutive_errors -ge $max_consecutive_errors ]; then
                    error "Too many consecutive errors, stopping daemon for safety"
                    break
                fi
            fi
            
            ((iteration_count++))
            
            # Progress logging every hour
            if [ $((iteration_count % 60)) -eq 0 ]; then
                log "Daemon running: $iteration_count cycles completed, $(($max_iterations - $iteration_count)) remaining"
            fi
            
            # Sleep with interruptible check
            for i in {1..60}; do
                sleep 1
                if [ ! -f "$pid_file" ]; then
                    break 2
                fi
            done
        done
        
        rm -f "$pid_file"
        log "Disk monitoring daemon finished after $iteration_count cycles"
        ;;
    "config")
        configure_disk_management
        ;;
    "enable")
        sed -i 's/DISK_MANAGEMENT_ENABLED=.*/DISK_MANAGEMENT_ENABLED=true/' "$DISK_CONFIG_FILE"
        success "Disk management enabled"
        ;;
    "disable")
        sed -i 's/DISK_MANAGEMENT_ENABLED=.*/DISK_MANAGEMENT_ENABLED=false/' "$DISK_CONFIG_FILE"
        warning "Disk management disabled"
        ;;
    "activity")
        if [ -n "$2" ]; then
            activity=$(get_disk_activity "$2")
            echo "Disk $2 activity count: $activity"
        else
            error "Please specify disk name"
            exit 1
        fi
        ;;
    "sleeping")
        if [ -n "$2" ]; then
            if is_disk_sleeping "$2"; then
                echo "Disk $2 is sleeping"
            else
                echo "Disk $2 is active"
            fi
        else
            error "Please specify disk name"
            exit 1
        fi
        ;;
    "system-disk")
        echo "System disk: $(get_system_disk)"
        ;;
    "whitelist")
        show_whitelist
        ;;
    "whitelist-add")
        if [ -n "$2" ]; then
            duration="${3:-${WHITELIST_DEFAULT_EXPIRY:-3600}}"  # Use configured default or 1 hour fallback
            add_to_whitelist "$2" "$duration"
            success "Added $2 to whitelist for $duration seconds"
        else
            error "Please specify disk name (e.g., nvme1n1)"
            exit 1
        fi
        ;;
    "whitelist-remove")
        if [ -n "$2" ]; then
            remove_from_whitelist "$2"
        else
            error "Please specify disk name (e.g., nvme1n1)"
            exit 1
        fi
        ;;
    "whitelist-clear")
        if [ -f "$WHITELIST_FILE" ]; then
            rm -f "$WHITELIST_FILE"
            success "Whitelist cleared"
        else
            info "Whitelist is already empty"
        fi
        ;;
    "stop-daemon")
        pid_file="/tmp/disk-manager-daemon.pid"
        if [ -f "$pid_file" ]; then
            daemon_pid=$(cat "$pid_file" 2>/dev/null)
            if [ -n "$daemon_pid" ] && kill -0 "$daemon_pid" 2>/dev/null; then
                log "Stopping disk monitoring daemon (PID: $daemon_pid)..."
                kill -TERM "$daemon_pid" 2>/dev/null || kill -KILL "$daemon_pid" 2>/dev/null
                rm -f "$pid_file"
                success "Disk monitoring daemon stopped"
            else
                rm -f "$pid_file"
                warning "Daemon PID file found but process not running"
            fi
        else
            info "No daemon PID file found - daemon may not be running"
        fi
        ;;
    *)
        show_help
        ;;
esac
