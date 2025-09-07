#!/bin/bash

# Modular Power Control System
# Version: 1.0.0
# Flexible, composable power management with separate system and GPU presets

# ============================================================================
# MODULAR CONFIGURATION
# ============================================================================

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
PRESETS_DIR="$SCRIPT_DIR/../presets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
MAGENTA='\033[0;95m'
NC='\033[0m' # No Color

# ============================================================================
# MODULAR INITIALIZATION
# ============================================================================

# Initialize modular system
init_modular_system() {
    # Source enterprise libraries if available
    if [ -f "$LIB_DIR/enterprise-logging.sh" ]; then
        source "$LIB_DIR/enterprise-logging.sh"
        init_logging
    fi
    
    if [ -f "$LIB_DIR/enterprise-validation.sh" ]; then
        source "$LIB_DIR/enterprise-validation.sh"
        init_validation
    fi
    
    if [ -f "$LIB_DIR/desktop-detection.sh" ]; then
        source "$LIB_DIR/desktop-detection.sh"
    fi
    
    if [ -f "$LIB_DIR/enterprise-monitoring.sh" ]; then
        source "$LIB_DIR/enterprise-monitoring.sh"
        init_metrics
    fi
    
    # Source modular system
    if [ -f "$LIB_DIR/modular-power-system.sh" ]; then
        source "$LIB_DIR/modular-power-system.sh"
        init_modular_system
    else
        error "Modular power system not found: $LIB_DIR/modular-power-system.sh"
        exit 1
    fi
}

# ============================================================================
# MODULAR LOGGING FUNCTIONS
# ============================================================================

# Enhanced logging functions
log() {
    local message="$1"
    local context="${2:-GENERAL}"
    
    if command -v log_info >/dev/null 2>&1; then
        log_info "$message" "$context"
    else
        echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $message"
    fi
}

error() {
    local message="$1"
    local context="${2:-ERROR}"
    
    if command -v log_error >/dev/null 2>&1; then
        log_error "$message" "$context"
    else
        echo -e "${RED}[ERROR]${NC} $message" >&2
    fi
}

success() {
    local message="$1"
    local context="${2:-SUCCESS}"
    
    if command -v log_success >/dev/null 2>&1; then
        log_success "$message" "$context"
    else
        echo -e "${GREEN}[SUCCESS]${NC} $message"
    fi
}

warning() {
    local message="$1"
    local context="${2:-WARNING}"
    
    if command -v log_warning >/dev/null 2>&1; then
        log_warning "$message" "$context"
    else
        echo -e "${YELLOW}[WARNING]${NC} $message"
    fi
}

info() {
    local message="$1"
    local context="${2:-INFO}"
    
    if command -v log_info >/dev/null 2>&1; then
        log_info "$message" "$context"
    else
        echo -e "${CYAN}[INFO]${NC} $message"
    fi
}

# ============================================================================
# MODULAR IMPLEMENTATION FUNCTIONS
# ============================================================================

# Apply TLP configuration
apply_tlp_configuration() {
    local mode="$1"
    
    if ! should_use_tlp; then
        log_debug "TLP not available or disabled, skipping TLP configuration" "TLP"
        return 0
    fi
    
    log_info "Applying TLP configuration: $mode" "TLP"
    
    case "$mode" in
        "bat")
            sudo tlp bat >/dev/null 2>&1
            success "TLP set to battery mode"
            ;;
        "ac")
            sudo tlp ac >/dev/null 2>&1
            success "TLP set to AC mode"
            ;;
        "balanced"|"auto")
            sudo tlp start >/dev/null 2>&1
            success "TLP set to balanced mode"
            ;;
        *)
            warning "Unknown TLP mode: $mode"
            return 1
            ;;
    esac
}

# Apply power profile
apply_power_profile() {
    local profile="$1"
    local desktop=$(detect_desktop_environment 2>/dev/null || detect_desktop)
    
    log_info "Applying power profile: $profile for desktop: $desktop" "POWER"
    
    # Try powerprofilesctl first
    if has_powerprofilesctl && powerprofilesctl list >/dev/null 2>&1; then
        if powerprofilesctl set "$profile" 2>/dev/null; then
            success "Power profile set to $profile via powerprofilesctl"
            return 0
        fi
    fi
    
    # Fallback to desktop-specific methods
    case "$desktop" in
        "gnome")
            if has_gsettings; then
                case "$profile" in
                    "power-saver")
                        gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
                        success "Applied power-saver settings via GNOME"
                        ;;
                    "performance")
                        gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing'
                        success "Applied performance settings via GNOME"
                        ;;
                esac
            fi
            ;;
        "kde")
            # KDE-specific power profile handling
            log_info "KDE power profile handling not implemented yet" "POWER"
            ;;
    esac
}

# Apply WiFi optimizations
apply_wifi_optimizations() {
    local mode="$1"
    local wifi_interface=""
    
    # Get WiFi interface
    wifi_interface=$(ip link show | grep -E "wl|wlan" | cut -d: -f2 | tr -d ' ' | head -1)
    if [ -z "$wifi_interface" ]; then
        log_debug "No WiFi interface found, skipping WiFi optimizations" "WIFI"
        return 0
    fi
    
    # Check if Intel WiFi
    if ! lspci | grep -i "intel.*network\|intel.*wifi" > /dev/null; then
        log_debug "No Intel WiFi detected, skipping Intel-specific optimizations" "WIFI"
        return 0
    fi
    
    log_info "Applying WiFi optimizations ($mode mode)" "WIFI"
    
    case "$mode" in
        "aggressive")
            # Ultra-eco mode: Maximum power saving
            if command -v iw >/dev/null 2>&1; then
                sudo iw dev "$wifi_interface" set power_save on 2>/dev/null || true
            fi
            echo 4 2>/dev/null | sudo tee /sys/module/iwlwifi/parameters/power_level >/dev/null || true
            ;;
        "balanced")
            # Balanced mode: Good balance of power saving and performance
            if command -v iw >/dev/null 2>&1; then
                sudo iw dev "$wifi_interface" set power_save on 2>/dev/null || true
            fi
            echo 3 2>/dev/null | sudo tee /sys/module/iwlwifi/parameters/power_level >/dev/null || true
            ;;
        "performance")
            # Performance mode: Minimal power saving for best performance
            if command -v iw >/dev/null 2>&1; then
                sudo iw dev "$wifi_interface" set power_save off 2>/dev/null || true
            fi
            echo 1 2>/dev/null | sudo tee /sys/module/iwlwifi/parameters/power_level >/dev/null || true
            ;;
        *)
            # Default: balanced approach
            if command -v iw >/dev/null 2>&1; then
                sudo iw dev "$wifi_interface" set power_save on 2>/dev/null || true
            fi
            echo 3 2>/dev/null | sudo tee /sys/module/iwlwifi/parameters/power_level >/dev/null || true
            ;;
    esac
    
    success "WiFi optimizations applied ($mode mode)"
}

# Apply disk optimizations
apply_disk_optimizations() {
    local mode="$1"
    
    if ! has_disk_manager; then
        log_debug "Disk manager not available, skipping disk optimizations" "DISK"
        return 0
    fi
    
    log_info "Applying disk optimizations ($mode mode)" "DISK"
    
    case "$mode" in
        "aggressive")
            # Aggressive disk power saving
            if command -v disk-manager.sh >/dev/null 2>&1; then
                disk-manager.sh suspend-all 2>/dev/null || true
            fi
            ;;
        "balanced")
            # Balanced disk management
            if command -v disk-manager.sh >/dev/null 2>&1; then
                disk-manager.sh optimize-balanced 2>/dev/null || true
            fi
            ;;
        "performance")
            # Wake all disks for performance
            if command -v disk-manager.sh >/dev/null 2>&1; then
                disk-manager.sh wake-all 2>/dev/null || true
            fi
            ;;
    esac
    
    success "Disk optimizations applied ($mode mode)"
}

# Apply GPU mode
apply_gpu_mode() {
    local mode="$1"
    local reboot_required=false
    
    echo "Applying GPU mode: $mode"
    
    # Handle different GPU switching methods
    if has_supergfxctl; then
        case "$mode" in
            "integrated")
                sudo supergfxctl -m integrated 2>/dev/null
                success "Switched to integrated GPU mode"
                ;;
            "hybrid")
                sudo supergfxctl -m hybrid 2>/dev/null
                success "Switched to hybrid GPU mode"
                ;;
            "nvidia"|"discrete")
                sudo supergfxctl -m dedicated 2>/dev/null
                success "Switched to discrete GPU mode"
                ;;
        esac
    elif has_envycontrol; then
        case "$mode" in
            "integrated")
                sudo envycontrol -s integrated 2>/dev/null
                success "Switched to integrated GPU mode"
                ;;
            "hybrid")
                sudo envycontrol -s hybrid 2>/dev/null
                success "Switched to hybrid GPU mode"
                ;;
            "nvidia"|"discrete")
                sudo envycontrol -s nvidia 2>/dev/null
                success "Switched to discrete GPU mode"
                ;;
        esac
    else
        warning "No GPU switching tool available"
        return 1
    fi
    
    # Check if reboot is required
    local new_mode=$(get_gpu_mode)
    if [ "$new_mode" != "$mode" ]; then
        reboot_required=true
        warning "GPU mode change requires reboot to take effect"
    fi
    
    if [ "$reboot_required" = "true" ]; then
        return 2  # Special return code for reboot required
    else
        return 0
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Check if TLP should be used
should_use_tlp() {
    if ! has_tlp; then
        return 1
    fi
    
    # Check if TLP is enabled in config
    if [ -f "$HOME/.config/modular-power.conf" ]; then
        source "$HOME/.config/modular-power.conf"
        if [ "$SYSTEM_POWER_MANAGEMENT" = "false" ]; then
            return 1
        fi
    fi
    
    return 0
}

# Get GPU mode
get_gpu_mode() {
    if has_supergfxctl; then
        supergfxctl -g 2>/dev/null || echo "unknown"
    elif has_envycontrol; then
        envycontrol --query 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Get battery info
get_battery_info() {
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        local capacity=$(cat /sys/class/power_supply/BAT0/capacity)
        local status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")
        echo "${capacity}% (${status})"
    else
        echo "No battery detected"
    fi
}

# Get CPU temperature
get_cpu_temperature() {
    if has_sensors; then
        sensors 2>/dev/null | grep "Package id 0" | awk '{print $4}' || echo "N/A"
    else
        echo "N/A"
    fi
}

# Get system load
get_system_load() {
    if [ -f /proc/loadavg ]; then
        awk '{print $1}' /proc/loadavg
    else
        echo "N/A"
    fi
}

# Detect desktop environment
detect_desktop() {
    if command -v detect_desktop_environment >/dev/null 2>&1; then
        detect_desktop_environment
    else
        # Fallback to basic detection
        if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$DESKTOP_SESSION" = "gnome" ]; then
            echo "gnome"
        elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "plasma" ]; then
            echo "kde"
        else
            echo "unknown"
        fi
    fi
}

# Check tool availability
has_powerprofilesctl() { command -v powerprofilesctl > /dev/null 2>&1; }
has_gsettings() { command -v gsettings > /dev/null 2>&1; }
has_sensors() { command -v sensors > /dev/null 2>&1; }
has_tlp() { command -v tlp > /dev/null 2>&1; }
has_envycontrol() { command -v envycontrol > /dev/null 2>&1; }
has_supergfxctl() { command -v supergfxctl > /dev/null 2>&1; }
has_disk_manager() { [ -x "$(dirname "$0")/disk-manager.sh" ] || [ -x "/usr/local/bin/disk-manager.sh" ]; }

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Initialize modular system
init_modular_system

# Process command
if [ $# -eq 0 ]; then
    show_modular_help
else
    process_modular_command "$@"
fi
