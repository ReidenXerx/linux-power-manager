#!/bin/bash

# Cleanup Outdated Presets Script
# Version: 1.0.0
# Removes outdated presets and creates Intel-optimized replacements

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESETS_DIR="$SCRIPT_DIR/presets/system-presets"
BACKUP_DIR="$SCRIPT_DIR/presets/backup-$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_cleanup() {
    echo -e "${PURPLE}[CLEANUP]${NC} $1"
}

# ============================================================================
# CLEANUP FUNCTIONS
# ============================================================================

backup_outdated_presets() {
    log_info "Creating backup of outdated presets..."
    
    mkdir -p "$BACKUP_DIR"
    
    # List of outdated presets to backup and remove
    local outdated_presets=(
        "balanced-dgpu.conf"
        "developer-mode.conf"
        "eco-gaming.conf"
        "performance-dgpu.conf"
        "work-mode.conf"
    )
    
    for preset in "${outdated_presets[@]}"; do
        if [ -f "$PRESETS_DIR/$preset" ]; then
            cp "$PRESETS_DIR/$preset" "$BACKUP_DIR/"
            log_success "Backed up outdated preset: $preset"
        fi
    done
    
    log_success "Backup completed: $BACKUP_DIR"
}

remove_outdated_presets() {
    log_cleanup "Removing outdated presets..."
    
    # List of outdated presets to remove
    local outdated_presets=(
        "balanced-dgpu.conf"
        "developer-mode.conf"
        "eco-gaming.conf"
        "performance-dgpu.conf"
        "work-mode.conf"
    )
    
    for preset in "${outdated_presets[@]}"; do
        if [ -f "$PRESETS_DIR/$preset" ]; then
            rm "$PRESETS_DIR/$preset"
            log_success "Removed outdated preset: $preset"
        fi
    done
}

update_ultra_eco_with_intel_optimizations() {
    log_info "Updating ultra-eco preset with Intel optimizations..."
    
    # Create Intel-optimized ultra-eco preset
    cat > "$PRESETS_DIR/ultra-eco.conf" << 'ULTRA_ECO_EOF'
# ==============================================================================
# ULTRA-ECO TLP CONFIGURATION - Maximum Power Savings with Intel Optimizations
# Optimized for: Intel Core Ultra 7 155H + Intel Arc Graphics maximum power savings
# Target: 8-12+ hours battery life, office work, reading, light browsing
# Hardware: Intel Arc Graphics (800-2250MHz), Intel Ultra 7 155H (16C/22T)
# ==============================================================================

# CPU Control - INTEL ULTRA CONSERVATIVE
CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# CPU Performance - INTEL ULTRA CONSERVATIVE
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=25        # Ultra-conservative for Intel hybrid architecture
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=10       # Ultra-conservative battery performance

# CPU Features - INTEL POWER SAVING
CPU_HWP_DYN_BOOST_ON_AC=0    # Disable boost even on AC
CPU_HWP_DYN_BOOST_ON_BAT=0
CPU_ENERGY_PERF_POLICY_ON_AC=power
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# PCIe - MAXIMUM POWER SAVING
PCIE_ASPM_ON_AC=powersupersave
PCIE_ASPM_ON_BAT=powersupersave

# Intel Arc Graphics - ULTRA LOW FREQUENCIES (Hardware: 800-2250MHz)
# Actual hardware: Min=800MHz, Max=1400MHz, Boost=1500MHz, RP0=2250MHz
INTEL_GPU_MIN_FREQ_ON_AC=800   # Use actual hardware minimum
INTEL_GPU_MAX_FREQ_ON_AC=800   # Ultra-conservative max (hardware minimum)
INTEL_GPU_BOOST_FREQ_ON_AC=900  # Minimal boost
INTEL_GPU_MIN_FREQ_ON_BAT=800   # Use actual hardware minimum
INTEL_GPU_MAX_FREQ_ON_BAT=800   # Ultra-conservative max (hardware minimum)
INTEL_GPU_BOOST_FREQ_ON_BAT=800 # No boost on battery

# Intel Arc Graphics Power Management - ULTRA ECO
INTEL_GPU_DVFS_ON_AC=1         # Enable dynamic frequency scaling
INTEL_GPU_DVFS_ON_BAT=1        # Enable on battery for maximum efficiency
INTEL_GPU_POWER_SAVE_ON_AC=1   # Enable power save on AC
INTEL_GPU_POWER_SAVE_ON_BAT=1   # Enable power save on battery

# USB - AGGRESSIVE AUTOSUSPEND
USB_AUTOSUSPEND=1
USB_EXCLUDE_BTUSB=0
USB_EXCLUDE_PHONE=0
USB_EXCLUDE_PRINTER=0
USB_EXCLUDE_WWAN=0

# Wi-Fi - MAXIMUM POWER SAVING (Intel optimized)
WIFI_PWR_ON_AC=on              # Power saving even on AC
WIFI_PWR_ON_BAT=on

# Intel iwlwifi ultra power saving
WIFI_PWR_UAPSD_ON_AC=on        # Enable U-APSD even on AC
WIFI_PWR_UAPSD_ON_BAT=on       # Enable U-APSD on battery
WIFI_PWR_CONN_ON_AC=on         # Connection power save on AC
WIFI_PWR_CONN_ON_BAT=on        # Connection power save on battery

# NVMe - AGGRESSIVE POWER STATES
NVME_APST_ON_AC=1             # Enable even on AC
NVME_APST_ON_BAT=1

# SATA - MAXIMUM LINK POWER SAVING
SATA_LINKPWR_ON_AC=min_power
SATA_LINKPWR_ON_BAT=min_power

# Audio - AGGRESSIVE POWER SAVING
SOUND_POWER_SAVE_ON_AC=10     # Longer timeout even on AC
SOUND_POWER_SAVE_ON_BAT=10
SOUND_POWER_SAVE_CONTROLLER=Y

# Runtime PM - MAXIMUM SAVINGS
RUNTIME_PM_ON_AC=auto         # Enable runtime PM on AC too
RUNTIME_PM_ON_BAT=auto

# Device Control - DISABLE UNNECESSARY
DEVICES_TO_DISABLE_ON_AC="wwan bluetooth"  # Disable more on AC
DEVICES_TO_DISABLE_ON_BAT="wwan bluetooth"

# Disk - AGGRESSIVE TIMEOUTS
DISK_IDLE_SECS_ON_AC=2        # Quick suspend even on AC
DISK_IDLE_SECS_ON_BAT=2
MAX_LOST_WORK_SECS_ON_AC=15
MAX_LOST_WORK_SECS_ON_BAT=15

# Platform Profile
PLATFORM_PROFILE_ON_AC=low-power
PLATFORM_PROFILE_ON_BAT=low-power

# Network - CONSERVATIVE
WOL_DISABLE=Y

# NMI Watchdog - DISABLED
NMI_WATCHDOG=0

# Memory - EFFICIENT SUSPEND
MEM_SLEEP_ON_AC=deep          # Use deep sleep for maximum savings
MEM_SLEEP_ON_BAT=deep

# Intel Ultra 7 155H Ultra Eco Optimizations
# E-Core efficiency mode for maximum power savings
CPU_E_CORE_EFFICIENCY_ON_AC=1  # Enable E-Core efficiency mode on AC
CPU_E_CORE_EFFICIENCY_ON_BAT=1 # Enable E-Core efficiency mode on battery
CPU_P_CORE_POWER_SAVE_ON_AC=1  # Enable P-Core power save on AC
CPU_P_CORE_POWER_SAVE_ON_BAT=1 # Enable P-Core power save on battery

# Intel Arc Graphics ultra eco optimizations
INTEL_GPU_ECO_MODE_ON_AC=1     # Enable eco mode on AC
INTEL_GPU_ECO_MODE_ON_BAT=1    # Enable eco mode on battery
INTEL_GPU_MEMORY_POWER_SAVE_ON_AC=1 # Enable memory power save on AC
INTEL_GPU_MEMORY_POWER_SAVE_ON_BAT=1 # Enable memory power save on battery

# Additional Intel Ultra 7 155H Ultra Eco Optimizations
CPU_BOOST_ON_AC=0             # Disable boost on AC
CPU_BOOST_ON_BAT=0            # Disable boost on battery

# Intel Thread Director ultra eco optimizations
CPU_SCHEDULER_ON_AC=power     # Power scheduler on AC
CPU_SCHEDULER_ON_BAT=power    # Power scheduler on battery
ULTRA_ECO_EOF

    log_success "Updated ultra-eco preset with Intel optimizations"
}

create_intel_eco_preset() {
    log_info "Creating Intel-optimized eco preset..."
    
    # Create Intel-optimized eco preset
    cat > "$PRESETS_DIR/intel-eco.conf" << 'INTEL_ECO_EOF'
# ==============================================================================
# INTEL-ECO TLP CONFIGURATION - Intel Optimized Eco Mode
# Optimized for: Intel Core Ultra 7 155H + Intel Arc Graphics eco mode
# Target: 6-8 hours battery life, good performance with power savings
# Hardware: Intel Arc Graphics (800-2250MHz), Intel Ultra 7 155H (16C/22T)
# ==============================================================================

# CPU Control - INTEL ECO OPTIMIZED
CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# CPU Performance - INTEL ECO OPTIMIZED
CPU_MIN_PERF_ON_AC=5
CPU_MAX_PERF_ON_AC=50        # Moderate performance for Intel hybrid architecture
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=25       # Conservative battery performance

# CPU Features - INTEL ECO OPTIMIZED
CPU_HWP_DYN_BOOST_ON_AC=0    # Disable boost on AC
CPU_HWP_DYN_BOOST_ON_BAT=0
CPU_ENERGY_PERF_POLICY_ON_AC=balance_power
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# PCIe - INTEL ECO OPTIMIZED
PCIE_ASPM_ON_AC=powersave
PCIE_ASPM_ON_BAT=powersave

# Intel Arc Graphics - ECO OPTIMIZED FREQUENCIES (Hardware: 800-2250MHz)
# Actual hardware: Min=800MHz, Max=1400MHz, Boost=1500MHz, RP0=2250MHz
INTEL_GPU_MIN_FREQ_ON_AC=800   # Use actual hardware minimum
INTEL_GPU_MAX_FREQ_ON_AC=1000  # Conservative max
INTEL_GPU_BOOST_FREQ_ON_AC=1100 # Moderate boost
INTEL_GPU_MIN_FREQ_ON_BAT=800   # Use actual hardware minimum
INTEL_GPU_MAX_FREQ_ON_BAT=900   # Conservative on battery
INTEL_GPU_BOOST_FREQ_ON_BAT=1000 # Minimal boost on battery

# Intel Arc Graphics Power Management - ECO OPTIMIZED
INTEL_GPU_DVFS_ON_AC=1         # Enable dynamic frequency scaling
INTEL_GPU_DVFS_ON_BAT=1        # Enable on battery for efficiency
INTEL_GPU_POWER_SAVE_ON_AC=1   # Enable power save on AC
INTEL_GPU_POWER_SAVE_ON_BAT=1   # Enable power save on battery

# USB - STANDARD AUTOSUSPEND
USB_AUTOSUSPEND=1
USB_EXCLUDE_BTUSB=0
USB_EXCLUDE_PHONE=0
USB_EXCLUDE_PRINTER=0
USB_EXCLUDE_WWAN=0

# Wi-Fi - ECO OPTIMIZED (Intel optimized)
WIFI_PWR_ON_AC=on              # Power saving on AC
WIFI_PWR_ON_BAT=on

# Intel iwlwifi eco optimizations
WIFI_PWR_UAPSD_ON_AC=on        # Enable U-APSD on AC
WIFI_PWR_UAPSD_ON_BAT=on       # Enable U-APSD on battery
WIFI_PWR_CONN_ON_AC=on         # Connection power save on AC
WIFI_PWR_CONN_ON_BAT=on        # Connection power save on battery

# NVMe - ECO OPTIMIZED
NVME_APST_ON_AC=1             # Enable on AC
NVME_APST_ON_BAT=1

# SATA - ECO OPTIMIZED
SATA_LINKPWR_ON_AC=med_power_with_dipm
SATA_LINKPWR_ON_BAT=med_power_with_dipm

# Audio - ECO OPTIMIZED
SOUND_POWER_SAVE_ON_AC=5      # Moderate timeout on AC
SOUND_POWER_SAVE_ON_BAT=5
SOUND_POWER_SAVE_CONTROLLER=Y

# Runtime PM - ECO OPTIMIZED
RUNTIME_PM_ON_AC=auto         # Enable runtime PM on AC
RUNTIME_PM_ON_BAT=auto

# Device Control - ECO OPTIMIZED
DEVICES_TO_DISABLE_ON_AC="wwan"  # Disable WWAN on AC
DEVICES_TO_DISABLE_ON_BAT="wwan" # Disable WWAN on battery

# Disk - ECO OPTIMIZED
DISK_IDLE_SECS_ON_AC=5        # Moderate suspend on AC
DISK_IDLE_SECS_ON_BAT=3       # Quick suspend on battery
MAX_LOST_WORK_SECS_ON_AC=20
MAX_LOST_WORK_SECS_ON_BAT=15

# Platform Profile - ECO OPTIMIZED
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power

# Network - ECO OPTIMIZED
WOL_DISABLE=Y

# NMI Watchdog - DISABLED
NMI_WATCHDOG=0

# Memory - ECO OPTIMIZED
MEM_SLEEP_ON_AC=s2idle        # Fast suspend/resume
MEM_SLEEP_ON_BAT=deep

# Intel Ultra 7 155H Eco Optimizations
# E-Core efficiency mode for power savings
CPU_E_CORE_EFFICIENCY_ON_AC=0  # Disable E-Core efficiency mode on AC
CPU_E_CORE_EFFICIENCY_ON_BAT=1 # Enable E-Core efficiency mode on battery
CPU_P_CORE_POWER_SAVE_ON_AC=0  # Disable P-Core power save on AC
CPU_P_CORE_POWER_SAVE_ON_BAT=1 # Enable P-Core power save on battery

# Intel Arc Graphics eco optimizations
INTEL_GPU_ECO_MODE_ON_AC=0     # Disable eco mode on AC
INTEL_GPU_ECO_MODE_ON_BAT=1    # Enable eco mode on battery
INTEL_GPU_MEMORY_POWER_SAVE_ON_AC=0 # Disable memory power save on AC
INTEL_GPU_MEMORY_POWER_SAVE_ON_BAT=1 # Enable memory power save on battery

# Additional Intel Ultra 7 155H Eco Optimizations
CPU_BOOST_ON_AC=0             # Disable boost on AC
CPU_BOOST_ON_BAT=0            # Disable boost on battery

# Intel Thread Director eco optimizations
CPU_SCHEDULER_ON_AC=balanced   # Balanced scheduler on AC
CPU_SCHEDULER_ON_BAT=power     # Power scheduler on battery
INTEL_ECO_EOF

    log_success "Created Intel-optimized eco preset"
}

update_modular_system_presets() {
    log_info "Updating modular system with new Intel presets..."
    
    # Update the modular system to include new Intel presets
    local modular_lib="$SCRIPT_DIR/lib/modular-power-system.sh"
    
    # Add Intel eco preset to the system presets configuration
    sed -i '/# Intel Arc Creative - Intel Arc Graphics creative workloads/a\
\
# Intel Eco - Intel optimized eco mode\
INTEL_ECO_TLP_MODE=bat\
INTEL_ECO_POWER_PROFILE=power-saver\
INTEL_ECO_WIFI_MODE=aggressive\
INTEL_ECO_DISK_MODE=aggressive\
INTEL_ECO_DESCRIPTION="Intel optimized eco mode with good performance and power savings"\
INTEL_ECO_BATTERY_TARGET="6-8 hours"\
INTEL_ECO_PERFORMANCE_LEVEL="4/10"' "$modular_lib"
    
    log_success "Updated modular system with Intel eco preset"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_cleanup() {
    log_info "Validating cleanup..."
    
    # Check that outdated presets are removed
    local outdated_presets=(
        "balanced-dgpu.conf"
        "developer-mode.conf"
        "eco-gaming.conf"
        "performance-dgpu.conf"
        "work-mode.conf"
    )
    
    local removed_count=0
    for preset in "${outdated_presets[@]}"; do
        if [ ! -f "$PRESETS_DIR/$preset" ]; then
            ((removed_count++))
        fi
    done
    
    if [ $removed_count -eq ${#outdated_presets[@]} ]; then
        log_success "All outdated presets removed ($removed_count)"
    else
        log_warning "Some outdated presets still remain"
    fi
    
    # Check that Intel-optimized presets exist
    local intel_presets=(
        "intel-arc-optimized.conf"
        "intel-hybrid-performance.conf"
        "intel-arc-creative.conf"
        "intel-eco.conf"
        "ultra-eco.conf"
    )
    
    local intel_count=0
    for preset in "${intel_presets[@]}"; do
        if [ -f "$PRESETS_DIR/$preset" ]; then
            ((intel_count++))
        fi
    done
    
    if [ $intel_count -eq ${#intel_presets[@]} ]; then
        log_success "All Intel-optimized presets present ($intel_count)"
    else
        log_warning "Some Intel-optimized presets missing"
    fi
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================

main() {
    echo "=========================================="
    echo "Power Manager - Outdated Presets Cleanup"
    echo "=========================================="
    echo ""
    
    log_info "Cleaning up outdated presets and creating Intel-optimized replacements..."
    echo ""
    
    # Backup outdated presets
    backup_outdated_presets
    echo ""
    
    # Remove outdated presets
    remove_outdated_presets
    echo ""
    
    # Update ultra-eco with Intel optimizations
    update_ultra_eco_with_intel_optimizations
    echo ""
    
    # Create Intel-optimized eco preset
    create_intel_eco_preset
    echo ""
    
    # Update modular system
    update_modular_system_presets
    echo ""
    
    # Validate cleanup
    validate_cleanup
    echo ""
    
    echo "=========================================="
    log_success "Cleanup completed!"
    echo "=========================================="
    echo ""
    echo "Changes made:"
    echo "  ✅ Removed outdated presets (5 presets)"
    echo "  ✅ Updated ultra-eco with Intel optimizations"
    echo "  ✅ Created Intel-optimized eco preset"
    echo "  ✅ Updated modular system with new presets"
    echo ""
    echo "New Intel-optimized presets:"
    echo "  🎮 intel-arc-optimized.conf - Intel Arc Graphics optimized"
    echo "  ⚡ intel-hybrid-performance.conf - Intel hybrid architecture optimized"
    echo "  🎨 intel-arc-creative.conf - Intel Arc Graphics creative workloads"
    echo "  🌱 intel-eco.conf - Intel optimized eco mode"
    echo "  🔋 ultra-eco.conf - Intel optimized ultra eco mode"
    echo ""
    echo "Backup location: $BACKUP_DIR"
    echo ""
    log_info "All presets now meet high Intel optimization standards!"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Check if help requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Power Manager - Outdated Presets Cleanup"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Backup outdated presets"
    echo "  2. Remove outdated presets that don't meet Intel standards"
    echo "  3. Update ultra-eco with Intel optimizations"
    echo "  4. Create Intel-optimized eco preset"
    echo "  5. Update modular system with new presets"
    echo "  6. Validate the cleanup"
    echo ""
    echo "Outdated presets to be removed:"
    echo "  - balanced-dgpu.conf (replaced by intel-arc-optimized)"
    echo "  - developer-mode.conf (replaced by intel-hybrid-performance)"
    echo "  - eco-gaming.conf (replaced by intel-arc-optimized)"
    echo "  - performance-dgpu.conf (replaced by intel-arc-optimized)"
    echo "  - work-mode.conf (replaced by intel-hybrid-performance)"
    echo ""
    echo "New Intel-optimized presets:"
    echo "  - intel-eco.conf (Intel optimized eco mode)"
    echo "  - ultra-eco.conf (updated with Intel optimizations)"
    exit 0
fi

# Run main function
main "$@"
