#!/bin/bash

# Unified Power Control System with TLP Integration v2.2.0
# Combines power management, hibernation, TLP integration and universal desktop support
# Works with KDE, GNOME, and other environments
# TLP integration only active on GNOME (KDE conflicts with TLP)
# Added: GPU switching with envycontrol and comprehensive preset system

VERSION="2.2.0"
CONFIG_FILE="$HOME/.config/power-control.conf"
PRESETS_FILE="$HOME/.config/power-presets.conf"
SCRIPT_DIR="$HOME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
MAGENTA='\033[0;95m'
NC='\033[0m' # No Color

# Hibernation settings
SWAP_DEVICE="/dev/nvme0n1p5"
SWAP_MAPPER="hibernate-swap"
SWAP_PATH="/dev/mapper/$SWAP_MAPPER"

# Create config directory if it does not exist
mkdir -p "$HOME/.config"

# Initialize config file if it does not exist
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << CONF_EOF
# Unified Power Control Configuration
AUTO_ECO_ON_STARTUP=true
AUTO_ECO_ON_WAKE=true
PREFER_GNOME_NATIVE=true
HIBERNATION_ENABLED=true
TLP_INTEGRATION_ENABLED=true
TLP_ONLY_ON_GNOME=true
GPU_SWITCHING_ENABLED=true
DEFAULT_PRESET=balanced
CONF_EOF
fi

# Initialize comprehensive presets file
if [ ! -f "$PRESETS_FILE" ]; then
    cat > "$PRESETS_FILE" << PRESETS_EOF
# Enhanced Power Presets Configuration
# Format: PRESET_NAME_SETTING=value

# Ultra Eco - Maximum battery life
ULTRA_ECO_TLP_MODE=bat
ULTRA_ECO_GPU_MODE=integrated
ULTRA_ECO_POWER_PROFILE=power-saver
ULTRA_ECO_DESCRIPTION="Maximum battery savings with integrated GPU only"

# Eco Gaming - Light gaming with good battery
ECO_GAMING_TLP_MODE=balanced
ECO_GAMING_GPU_MODE=hybrid
ECO_GAMING_POWER_PROFILE=balanced
ECO_GAMING_DESCRIPTION="Light gaming performance with good battery life"

# Balanced - Default balanced mode (original)
BALANCED_TLP_MODE=auto
BALANCED_GPU_MODE=hybrid
BALANCED_POWER_PROFILE=balanced
BALANCED_DESCRIPTION="Balanced performance and efficiency"

# Balanced with dGPU - Your requested preset
BALANCED_DGPU_TLP_MODE=balanced
BALANCED_DGPU_GPU_MODE=hybrid
BALANCED_DGPU_POWER_PROFILE=balanced
BALANCED_DGPU_DESCRIPTION="Balanced mode with discrete GPU capabilities"

# Performance - High performance (original)
PERFORMANCE_TLP_MODE=ac
PERFORMANCE_GPU_MODE=hybrid
PERFORMANCE_POWER_PROFILE=performance
PERFORMANCE_DESCRIPTION="High performance for demanding tasks"

# Performance with dGPU - Your requested preset
PERFORMANCE_DGPU_TLP_MODE=ac
PERFORMANCE_DGPU_GPU_MODE=nvidia
PERFORMANCE_DGPU_POWER_PROFILE=performance
PERFORMANCE_DGPU_DESCRIPTION="Performance mode with discrete GPU for maximum power"

# Gaming Max - Maximum gaming performance
GAMING_MAX_TLP_MODE=ac
GAMING_MAX_GPU_MODE=nvidia
GAMING_MAX_POWER_PROFILE=performance
GAMING_MAX_DESCRIPTION="Maximum performance for gaming and intensive workloads"

# Work Mode - Optimized for productivity
WORK_MODE_TLP_MODE=balanced
WORK_MODE_GPU_MODE=integrated
WORK_MODE_POWER_PROFILE=balanced
WORK_MODE_DESCRIPTION="Optimized for office work and productivity with good battery"

# Developer Mode - For development workloads
DEVELOPER_MODE_TLP_MODE=ac
DEVELOPER_MODE_GPU_MODE=hybrid
DEVELOPER_MODE_POWER_PROFILE=performance
DEVELOPER_MODE_DESCRIPTION="Optimized for development with compilation and testing"
PRESETS_EOF
fi

# Source config files
source "$CONFIG_FILE"
source "$PRESETS_FILE" 2>/dev/null || true

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
# SYSTEM DETECTION FUNCTIONS
# ============================================================================

# Detect desktop environment
detect_desktop() {
    if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$DESKTOP_SESSION" = "gnome" ]; then
        echo "gnome"
    elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "plasma" ]; then
        echo "kde"
    else
        echo "unknown"
    fi
}

# Check available tools
has_powerprofilesctl() { command -v powerprofilesctl > /dev/null 2>&1; }
has_gsettings() { command -v gsettings > /dev/null 2>&1; }
has_acpi() { command -v acpi > /dev/null 2>&1; }
has_sensors() { command -v sensors > /dev/null 2>&1; }
has_tlp() { command -v tlp > /dev/null 2>&1; }
has_envycontrol() { command -v envycontrol > /dev/null 2>&1; }

# ============================================================================
# GPU MANAGEMENT FUNCTIONS
# ============================================================================

get_current_gpu_mode() {
    if has_envycontrol; then
        envycontrol --query 2>/dev/null || echo "unknown"
    else
        echo "unavailable"
    fi
}

set_gpu_mode() {
    local mode="$1"
    local reboot_required=false
    
    if [ "$GPU_SWITCHING_ENABLED" != "true" ]; then
        info "GPU switching disabled in config - skipping GPU mode change"
        return 0
    fi
    
    if ! has_envycontrol; then
        warning "envycontrol not available - skipping GPU mode change"
        return 1
    fi
    
    local current_mode=$(get_current_gpu_mode)
    if [ "$current_mode" = "$mode" ]; then
        info "GPU already in $mode mode"
        return 0
    fi
    
    log "Switching GPU mode from $current_mode to $mode..."
    
    case "$mode" in
        "integrated"|"intel")
            if sudo envycontrol -s integrated --force-comp --coolbits 24 > /dev/null 2>&1; then
                success "GPU switched to integrated mode"
                reboot_required=true
            else
                error "Failed to switch GPU to integrated mode"
                return 1
            fi
            ;;
        "hybrid")
            if sudo envycontrol -s hybrid --force-comp --coolbits 24 --rtd3 > /dev/null 2>&1; then
                success "GPU switched to hybrid mode"
                reboot_required=true
            else
                error "Failed to switch GPU to hybrid mode"
                return 1
            fi
            ;;
        "nvidia"|"discrete")
            if sudo envycontrol -s nvidia --force-comp --coolbits 24 > /dev/null 2>&1; then
                success "GPU switched to discrete/nvidia mode"
                reboot_required=true
            else
                error "Failed to switch GPU to nvidia mode"
                return 1
            fi
            ;;
        *)
            error "Invalid GPU mode: $mode (use: integrated, hybrid, nvidia)"
            return 1
            ;;
    esac
    
    if [ "$reboot_required" = "true" ]; then
        warning "⚠️  GPU mode change requires reboot to take effect"
        echo "   ${CYAN}Run 'sudo reboot' when ready${NC}"
    fi
    
    return 0
}

# ============================================================================
# TLP INTEGRATION FUNCTIONS  
# ============================================================================

should_use_tlp() {
    local desktop=$(detect_desktop)
    
    # Only use TLP if enabled in config
    if [ "$TLP_INTEGRATION_ENABLED" != "true" ]; then
        return 1
    fi
    
    # Check if TLP is available
    if ! has_tlp; then
        return 1
    fi
    
    # If configured to only use on GNOME, check desktop
    if [ "$TLP_ONLY_ON_GNOME" = "true" ] && [ "$desktop" != "gnome" ]; then
        info "TLP integration disabled on $desktop (TLP_ONLY_ON_GNOME=true)"
        return 1
    fi
    
    return 0
}

tlp_start() {
    if should_use_tlp; then
        log "Starting TLP service..."
        if sudo systemctl start tlp 2>/dev/null; then
            success "TLP service started"
            return 0
        else
            warning "Failed to start TLP service"
            return 1
        fi
    fi
    return 0
}

tlp_stop() {
    if has_tlp && systemctl is-active tlp >/dev/null 2>&1; then
        log "Stopping TLP service..."
        if sudo systemctl stop tlp 2>/dev/null; then
            success "TLP service stopped"
        else
            warning "Failed to stop TLP service"
        fi
    fi
}

tlp_apply_settings() {
    if should_use_tlp; then
        log "Applying TLP power settings..."
        if sudo tlp start >/dev/null 2>&1; then
            success "TLP settings applied"
            return 0
        else
            warning "Failed to apply TLP settings"
            return 1
        fi
    fi
    return 0
}

tlp_set_mode() {
    local mode="$1"
    
    if ! should_use_tlp; then
        return 0
    fi
    
    case "$mode" in
        "ac"|"performance")
            log "Switching TLP to AC/Performance mode..."
            if sudo tlp ac >/dev/null 2>&1; then
                success "TLP switched to AC mode"
            else
                warning "Failed to switch TLP to AC mode"
            fi
            ;;
        "bat"|"battery"|"eco")
            log "Switching TLP to Battery/Eco mode..."
            if sudo tlp bat >/dev/null 2>&1; then
                success "TLP switched to Battery mode"
            else
                warning "Failed to switch TLP to Battery mode"
            fi
            ;;
        "balanced"|"auto")
            log "Applying TLP balanced/auto settings..."
            if sudo tlp start >/dev/null 2>&1; then
                success "TLP balanced mode applied"
            else
                warning "Failed to apply TLP balanced mode"
            fi
            ;;
    esac
}

# ============================================================================
# POWER PROFILE FUNCTIONS (keeping your existing ones)
# ============================================================================

get_power_profile() {
    # Try powerprofilesctl first (works on both KDE and GNOME)
    if has_powerprofilesctl; then
        echo "$(powerprofilesctl get)"
        return 0
    fi
    
    # GNOME-specific method
    if [ "$(detect_desktop)" = "gnome" ] && has_gsettings; then
        local profile=$(gsettings get org.gnome.settings-daemon.plugins.power power-button-action 2>/dev/null || echo "unknown")
        echo "gnome:$profile"
        return 0
    fi
    
    # KDE-specific method
    if [ "$(detect_desktop)" = "kde" ] && command -v kreadconfig5 > /dev/null 2>&1; then
        local profile=$(kreadconfig5 --file powermanagementprofilesrc --group AC --key icon 2>/dev/null || echo "unknown")
        echo "kde:$profile"
        return 0
    fi
    
    echo "unknown"
}

set_power_profile() {
    local mode="$1"
    local desktop=$(detect_desktop)
    
    case "$mode" in
        "power-saver"|"eco")
            # Apply TLP battery mode first for deeper power savings
            tlp_set_mode "bat"
            
            if has_powerprofilesctl; then
                powerprofilesctl set power-saver
                success "Set power profile to power-saver via powerprofilesctl"
            elif [ "$desktop" = "gnome" ] && has_gsettings; then
                gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 1800
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 900
                success "Applied power-saver settings via GNOME settings"
            else
                warning "Unable to set power profile - no suitable method found"
                return 1
            fi
            
            # Apply additional eco mode settings
            if [ -f "$SCRIPT_DIR/eco-mode.sh" ]; then
                "$SCRIPT_DIR/eco-mode.sh"
            fi
            ;;
        "performance")
            # Apply TLP AC mode first
            tlp_set_mode "ac"
            
            if has_powerprofilesctl; then
                powerprofilesctl set performance
                success "Set power profile to performance via powerprofilesctl"
            elif [ "$desktop" = "gnome" ] && has_gsettings; then
                gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing'
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
                success "Applied performance settings via GNOME settings"
            else
                warning "Unable to set power profile - no suitable method found"
                return 1
            fi
            
            # Apply additional performance mode settings
            if [ -f "$SCRIPT_DIR/performance-mode.sh" ]; then
                "$SCRIPT_DIR/performance-mode.sh"
            fi
            ;;
        "balanced")
            # Use balanced TLP mode (auto-detect AC/BAT)
            tlp_apply_settings
            
            if has_powerprofilesctl; then
                powerprofilesctl set balanced
                success "Set power profile to balanced via powerprofilesctl"
            elif [ "$desktop" = "gnome" ] && has_gsettings; then
                gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800
                success "Applied balanced settings via GNOME settings"
            else
                warning "Unable to set power profile - no suitable method found"
                return 1
            fi
            ;;
        *)
            error "Invalid power mode: $mode"
            return 1
            ;;
    esac
}

# ============================================================================
# PRESET MANAGEMENT FUNCTIONS
# ============================================================================

get_available_presets() {
    # Extract preset names from config file
    grep "_DESCRIPTION=" "$PRESETS_FILE" 2>/dev/null | sed 's/_DESCRIPTION=.*//' | sort -u | tr '[:upper:]' '[:lower:]'
}

get_preset_info() {
    local preset="$1"
    local preset_upper=$(echo "$preset" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    local tlp_var="${preset_upper}_TLP_MODE"
    local gpu_var="${preset_upper}_GPU_MODE"
    local profile_var="${preset_upper}_POWER_PROFILE"
    local desc_var="${preset_upper}_DESCRIPTION"
    
    # Source the presets file again to get latest values
    source "$PRESETS_FILE" 2>/dev/null
    
    local tlp_mode=$(eval echo \$${tlp_var})
    local gpu_mode=$(eval echo \$${gpu_var})
    local power_profile=$(eval echo \$${profile_var})
    local description=$(eval echo "\$${desc_var}")
    
    echo "TLP_MODE=$tlp_mode"
    echo "GPU_MODE=$gpu_mode"
    echo "POWER_PROFILE=$power_profile"
    echo "DESCRIPTION=$description"
}

apply_preset() {
    local preset="$1"
    local preset_upper=$(echo "$preset" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    # Check if preset exists
    if ! grep -q "^${preset_upper}_DESCRIPTION=" "$PRESETS_FILE" 2>/dev/null; then
        error "Preset '$preset' not found"
        echo "Available presets:"
        get_available_presets
        return 1
    fi
    
    info "Applying power preset: $preset"
    
    # Get preset configuration
    local preset_info=$(get_preset_info "$preset")
    
    # Parse the preset info line by line instead of eval
    local TLP_MODE=$(echo "$preset_info" | grep "^TLP_MODE=" | cut -d'=' -f2)
    local GPU_MODE=$(echo "$preset_info" | grep "^GPU_MODE=" | cut -d'=' -f2)
    local POWER_PROFILE=$(echo "$preset_info" | grep "^POWER_PROFILE=" | cut -d'=' -f2)
    local DESCRIPTION=$(echo "$preset_info" | grep "^DESCRIPTION=" | cut -d'=' -f2-)
    
    echo -e "${MAGENTA}🎯 Applying preset: $preset${NC}"
    echo "   Description: $DESCRIPTION"
    echo "   TLP Mode: ${YELLOW}$TLP_MODE${NC}"
    echo "   GPU Mode: ${YELLOW}$GPU_MODE${NC}"
    echo "   Power Profile: ${YELLOW}$POWER_PROFILE${NC}"
    echo ""
    
    local errors=0
    
    # Apply TLP mode first
    if [ -n "$TLP_MODE" ] && [ "$TLP_MODE" != "none" ]; then
        tlp_set_mode "$TLP_MODE" || ((errors++))
    fi
    
    # Apply GPU mode (potentially requiring reboot)
    if [ -n "$GPU_MODE" ] && [ "$GPU_MODE" != "none" ]; then
        set_gpu_mode "$GPU_MODE" || ((errors++))
    fi
    
    # Apply system power profile
    if [ -n "$POWER_PROFILE" ] && [ "$POWER_PROFILE" != "none" ]; then
        set_power_profile "$POWER_PROFILE" || ((errors++))
    fi
    
    # Update current preset in config
    sed -i "s/DEFAULT_PRESET=.*/DEFAULT_PRESET=$preset/" "$CONFIG_FILE" 2>/dev/null
    
    if [ $errors -eq 0 ]; then
        success "Preset '$preset' applied successfully!"
    else
        warning "Preset '$preset' applied with $errors errors"
    fi
    
    return $errors
}

list_presets() {
    echo -e "${BLUE}📋 Available Power Presets:${NC}"
    echo "================================"
    
    local current_preset="$DEFAULT_PRESET"
    
    while IFS= read -r preset; do
        if [ -n "$preset" ]; then
            local preset_info=$(get_preset_info "$preset")
            
            # Parse the preset info line by line instead of eval
            local TLP_MODE=$(echo "$preset_info" | grep "^TLP_MODE=" | cut -d'=' -f2)
            local GPU_MODE=$(echo "$preset_info" | grep "^GPU_MODE=" | cut -d'=' -f2)
            local POWER_PROFILE=$(echo "$preset_info" | grep "^POWER_PROFILE=" | cut -d'=' -f2)
            local DESCRIPTION=$(echo "$preset_info" | grep "^DESCRIPTION=" | cut -d'=' -f2-)
            
            local marker=""
            if [ "$preset" = "$current_preset" ]; then
                marker="${GREEN}[ACTIVE]${NC} "
            fi
            
            echo -e "${marker}${CYAN}$preset${NC}"
            echo -e "  ${DESCRIPTION}"
            echo -e "  TLP: ${YELLOW}$TLP_MODE${NC} | GPU: ${YELLOW}$GPU_MODE${NC} | Profile: ${YELLOW}$POWER_PROFILE${NC}"
            echo ""
        fi
    done < <(get_available_presets)
}

# ============================================================================
# HIBERNATION FUNCTIONS (keeping all your existing ones)
# ============================================================================

is_swap_active() {
    swapon --show | grep -q "$SWAP_PATH\\|/dev/dm-1"
}

is_luks_open() {
    [ -e "$SWAP_PATH" ]
}

activate_hibernation_swap() {
    log "🔓 Activating encrypted swap for hibernation..."
    
    if is_swap_active; then
        success "Swap is already active"
        return 0
    fi
    
    if ! is_luks_open; then
        log "Unlocking encrypted swap partition..."
        if ! sudo cryptsetup luksOpen "$SWAP_DEVICE" "$SWAP_MAPPER"; then
            error "Failed to unlock encrypted swap"
            return 1
        fi
    else
        log "LUKS device already unlocked"
    fi
    
    if ! sudo file -sL "$SWAP_PATH" | grep -q swap; then
        log "Creating swap filesystem..."
        if ! sudo mkswap "$SWAP_PATH"; then
            error "Failed to create swap filesystem"
            return 1
        fi
    fi
    
    log "Activating swap..."
    if ! sudo swapon "$SWAP_PATH"; then
        error "Failed to activate swap"
        return 1
    fi
    
    # Set hibernation resume parameters
    echo "252:1" | sudo tee /sys/power/resume > /dev/null
    echo "0" | sudo tee /sys/power/resume_offset > /dev/null
    
    success "Encrypted swap activated for hibernation"
    return 0
}

deactivate_hibernation_swap() {
    log "🔒 Deactivating encrypted swap..."
    
    if is_swap_active; then
        log "Turning off swap..."
        sudo swapoff "$SWAP_PATH" 2>/dev/null || true
    fi
    
    if is_luks_open; then
        log "Closing encrypted swap partition..."
        sudo cryptsetup luksClose "$SWAP_MAPPER" 2>/dev/null || true
    fi
    
    success "Encrypted swap deactivated (energy saving mode)"
}

hibernation_status() {
    echo "🌙 Hibernation System Status:"
    echo "  Enabled: $HIBERNATION_ENABLED"
    echo "  Swap device: $SWAP_DEVICE"
    echo "  LUKS mapper: $SWAP_MAPPER"
    
    if is_luks_open; then
        echo "  LUKS status: 🔓 OPEN"
    else
        echo "  LUKS status: 🔒 CLOSED"
    fi
    
    if is_swap_active; then
        echo "  Swap status: ✅ ACTIVE"
        echo "  Swap size: $(swapon --show --noheadings | awk '{print $3}' 2>/dev/null || echo 'N/A')"
    else
        echo "  Swap status: 💤 INACTIVE (energy saving)"
    fi
    
    echo "  Resume device: $(cat /sys/power/resume 2>/dev/null || echo 'not set')"
}

hibernate_system() {
    if [ "$HIBERNATION_ENABLED" != "true" ]; then
        error "Hibernation is disabled in config"
        return 1
    fi
    
    log "🌙 Preparing system for hibernation..."
    
    # Activate hibernation swap if needed
    if ! is_swap_active; then
        if ! activate_hibernation_swap; then
            error "Failed to prepare hibernation - swap activation failed"
            return 1
        fi
    fi
    
    # Sync and prepare system
    log "Syncing filesystems..."
    sync
    
    log "Hibernating system..."
    if sudo systemctl hibernate; then
        success "System hibernated successfully"
    else
        error "Hibernation failed"
        return 1
    fi
}

# ============================================================================
# STATUS & DISPLAY FUNCTIONS
# ============================================================================

get_battery_info() {
    local battery_path="/sys/class/power_supply/BAT0"
    
    if [ -d "$battery_path" ]; then
        local capacity=$(cat "$battery_path/capacity" 2>/dev/null || echo "N/A")
        local status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
        echo "🔋 Battery: ${capacity}% (${status})"
    elif has_acpi; then
        local battery_info=$(acpi -b | head -1)
        echo "🔋 Battery: $battery_info"
    else
        echo "🔋 Battery: Unable to detect"
    fi
}

show_comprehensive_status() {
    local desktop=$(detect_desktop)
    local current_preset="$DEFAULT_PRESET"
    
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}               ${CYAN}🚀 ENHANCED POWER CONTROL v${VERSION}${NC}                     ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Current Preset Info
    echo -e "${PURPLE}║${NC} ${YELLOW}Active Preset: ${MAGENTA}${current_preset}${NC}                                           ${PURPLE}║${NC}"
    if grep -q "^$(echo "$current_preset" | tr '[:lower:]' '[:upper:]' | tr '-' '_')_DESCRIPTION=" "$PRESETS_FILE" 2>/dev/null; then
        local preset_info=$(get_preset_info "$current_preset")
        eval "$preset_info"
        echo -e "${PURPLE}║${NC}   Description: $DESCRIPTION                                              ${PURPLE}║${NC}"
    fi
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # System Info
    echo -e "${PURPLE}║${NC} ${YELLOW}System Status:${NC}                                                       ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}   Desktop Environment: $desktop                                          ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}   $(get_battery_info)                                                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}   Power Profile: $(get_power_profile)                                        ${PURPLE}║${NC}"
    
    # GPU Information
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC} ${YELLOW}GPU Status:${NC}                                                          ${PURPLE}║${NC}"
    if has_envycontrol; then
        local gpu_mode=$(get_current_gpu_mode)
        echo -e "${PURPLE}║${NC}   Current GPU Mode: ${CYAN}${gpu_mode}${NC}                                      ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}   GPU Switching: $([ "$GPU_SWITCHING_ENABLED" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")                              ${PURPLE}║${NC}"
    else
        echo -e "${PURPLE}║${NC}   envycontrol: ❌ Not available                                        ${PURPLE}║${NC}"
    fi
    
    # CPU Information  
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC} ${YELLOW}CPU Status:${NC}                                                          ${PURPLE}║${NC}"
    if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
        local turbo_status=$([ "$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)" = "0" ] && echo "Enabled" || echo "Disabled")
        echo -e "${PURPLE}║${NC}   Turbo Boost: $turbo_status                                           ${PURPLE}║${NC}"
    fi
    
    # Temperature
    if has_sensors; then
        local temp=$(sensors 2>/dev/null | grep "Package id 0" | awk '{print $4}' 2>/dev/null)
        if [ -n "$temp" ]; then
            echo -e "${PURPLE}║${NC}   CPU Temperature: $temp                                         ${PURPLE}║${NC}"
        fi
    fi
    
    # TLP Status
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC} ${YELLOW}TLP Integration:${NC}                                                     ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}   TLP Available: $(has_tlp && echo "✅ Yes" || echo "❌ No")                                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}   TLP Integration: $([ "$TLP_INTEGRATION_ENABLED" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")                              ${PURPLE}║${NC}"
    if has_tlp; then
        local tlp_status=$(systemctl is-active tlp 2>/dev/null || echo "inactive")
        echo -e "${PURPLE}║${NC}   TLP Service: $tlp_status                                           ${PURPLE}║${NC}"
    fi
    
    if [ "$HIBERNATION_ENABLED" = "true" ]; then
        echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${PURPLE}║${NC} ${YELLOW}Hibernation Status:${NC}                                               ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}   LUKS Status: $(is_luks_open && echo "🔓 OPEN" || echo "🔒 CLOSED")                              ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}   Swap Status: $(is_swap_active && echo "✅ ACTIVE" || echo "💤 INACTIVE")                        ${PURPLE}║${NC}"
    fi
    
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
}

# ============================================================================
# CONFIGURATION FUNCTIONS (keeping your existing ones plus GPU)
# ============================================================================

configure_system() {
    echo -e "${BLUE}🔧 Enhanced Power Control Configuration${NC}"
    echo "=========================================="
    echo "Current settings:"
    echo "  Auto-eco on startup: $AUTO_ECO_ON_STARTUP"
    echo "  Auto-eco on wake: $AUTO_ECO_ON_WAKE"
    echo "  Prefer GNOME native: $PREFER_GNOME_NATIVE"
    echo "  Hibernation enabled: $HIBERNATION_ENABLED"
    echo "  TLP integration: $TLP_INTEGRATION_ENABLED"
    echo "  TLP only on GNOME: $TLP_ONLY_ON_GNOME"
    echo "  GPU switching enabled: $GPU_SWITCHING_ENABLED"
    echo "  Default preset: $DEFAULT_PRESET"
    echo ""
    
    read -p "Enable auto-eco on startup? (y/n): " startup
    read -p "Enable auto-eco on wake from sleep? (y/n): " wake
    read -p "Prefer GNOME native settings over powerprofilesctl? (y/n): " gnome_native
    read -p "Enable hibernation support? (y/n): " hibernation
    read -p "Enable TLP integration? (y/n): " tlp_integration
    read -p "Use TLP only on GNOME (recommended)? (y/n): " tlp_gnome_only
    read -p "Enable GPU switching with envycontrol? (y/n): " gpu_switching
    
    echo ""
    echo "Available presets:"
    get_available_presets
    echo ""
    read -p "Enter default preset name: " default_preset
    
    AUTO_ECO_ON_STARTUP=$([ "$startup" = "y" ] && echo "true" || echo "false")
    AUTO_ECO_ON_WAKE=$([ "$wake" = "y" ] && echo "true" || echo "false")
    PREFER_GNOME_NATIVE=$([ "$gnome_native" = "y" ] && echo "true" || echo "false")
    HIBERNATION_ENABLED=$([ "$hibernation" = "y" ] && echo "true" || echo "false")
    TLP_INTEGRATION_ENABLED=$([ "$tlp_integration" = "y" ] && echo "true" || echo "false")
    TLP_ONLY_ON_GNOME=$([ "$tlp_gnome_only" = "y" ] && echo "true" || echo "false")
    GPU_SWITCHING_ENABLED=$([ "$gpu_switching" = "y" ] && echo "true" || echo "false")
    DEFAULT_PRESET="$default_preset"
    
    cat > "$CONFIG_FILE" << CONF_EOF
# Unified Power Control Configuration
AUTO_ECO_ON_STARTUP=$AUTO_ECO_ON_STARTUP
AUTO_ECO_ON_WAKE=$AUTO_ECO_ON_WAKE
PREFER_GNOME_NATIVE=$PREFER_GNOME_NATIVE
HIBERNATION_ENABLED=$HIBERNATION_ENABLED
TLP_INTEGRATION_ENABLED=$TLP_INTEGRATION_ENABLED
TLP_ONLY_ON_GNOME=$TLP_ONLY_ON_GNOME
GPU_SWITCHING_ENABLED=$GPU_SWITCHING_ENABLED
DEFAULT_PRESET=$DEFAULT_PRESET
CONF_EOF
    
    success "Configuration saved!"
}

# ============================================================================
# AUTO-APPLICATION FUNCTIONS (keeping your existing ones)
# ============================================================================

apply_startup_mode() {
    # Start TLP service if needed
    tlp_start
    
    if [ "$AUTO_ECO_ON_STARTUP" = "true" ]; then
        echo "🌱 Auto-applying eco-mode on startup..."
        # Wait for session to stabilize for PolicyKit authorization
        sleep 5
        apply_preset "ultra-eco"
    else
        # Apply default preset or fallback to TLP
        if [ -n "$DEFAULT_PRESET" ] && grep -q "^$(echo "$DEFAULT_PRESET" | tr '[:lower:]' '[:upper:]' | tr '-' '_')_DESCRIPTION=" "$PRESETS_FILE" 2>/dev/null; then
            apply_preset "$DEFAULT_PRESET"
        else
            tlp_apply_settings
        fi
    fi
}

apply_wake_mode() {
    # Restart TLP if needed
    if should_use_tlp; then
        tlp_start
    fi
    
    if [ "$AUTO_ECO_ON_WAKE" = "true" ]; then
        echo "🌱 Auto-applying eco-mode on wake..."
        apply_preset "ultra-eco"
    else
        # Apply default preset or fallback to TLP
        if [ -n "$DEFAULT_PRESET" ] && grep -q "^$(echo "$DEFAULT_PRESET" | tr '[:lower:]' '[:upper:]' | tr '-' '_')_DESCRIPTION=" "$PRESETS_FILE" 2>/dev/null; then
            apply_preset "$DEFAULT_PRESET"
        else
            tlp_apply_settings
        fi
    fi
    
    # Post-hibernation cleanup (your existing code)
    if [ "$HIBERNATION_ENABLED" = "true" ]; then
        log "Restarting services after hibernation..."
        
        # Restart system services
        sudo systemctl start NetworkManager.service 2>/dev/null || true
        sudo systemctl start bluetooth.service 2>/dev/null || true
        
        # Restart user services
        systemctl --user start pipewire.service pipewire.socket 2>/dev/null || true
        systemctl --user start pulseaudio.service 2>/dev/null || true
        
        sleep 5
        deactivate_hibernation_swap
    fi
}

# ============================================================================
# HELP & MAIN PROCESSING
# ============================================================================

show_help() {
    echo -e "${CYAN}🚀 Enhanced Power Control System with GPU Integration v${VERSION}${NC}"
    echo "======================================================================"
    echo ""
    echo -e "${YELLOW}🎯 Power Presets (Complete Pool):${NC}"
    echo "  ultra-eco         - Maximum battery saving (integrated GPU + eco mode)"
    echo "  eco-gaming        - Light gaming with battery (hybrid GPU + balanced)"
    echo "  balanced          - Default balanced mode (hybrid GPU + balanced TLP)"
    echo "  balanced-dgpu     - Balanced with dGPU capabilities (hybrid + balanced)"
    echo "  performance       - High performance mode (hybrid GPU + AC TLP)"
    echo "  performance-dgpu  - Performance with dGPU (nvidia GPU + AC TLP)"
    echo "  gaming-max        - Maximum gaming power (nvidia GPU + performance)"
    echo "  work-mode         - Productivity optimized (integrated + balanced)"
    echo "  developer-mode    - Development workloads (hybrid + performance)"
    echo ""
    echo -e "${YELLOW}Legacy Power Commands (PRESERVED):${NC}"
    echo "  eco               - Switch to eco/power-saver mode (+ TLP battery mode)"
    echo "  performance       - Switch to performance mode (+ TLP AC mode)" 
    echo "  balanced          - Switch to balanced mode (+ TLP auto mode)"
    echo ""
    echo -e "${YELLOW}Preset Management:${NC}"
    echo "  list-presets      - List all available power presets"
    echo "  preset <name>     - Apply specific preset by name"
    echo ""
    echo -e "${YELLOW}GPU Commands:${NC}"
    echo "  gpu-integrated    - Switch to integrated GPU only"
    echo "  gpu-hybrid        - Switch to hybrid GPU mode"  
    echo "  gpu-nvidia        - Switch to discrete/nvidia GPU"
    echo "  gpu-status        - Show current GPU mode"
    echo ""
    echo -e "${YELLOW}System Commands:${NC}"
    echo "  status            - Show comprehensive power status"
    echo "  config            - Configure auto-eco, hibernation, TLP and GPU settings"
    echo "  enable-auto       - Enable auto eco-mode"
    echo "  disable-auto      - Disable auto eco-mode"
    echo ""
    echo -e "${YELLOW}TLP Commands:${NC}"
    echo "  tlp-start         - Start TLP service"
    echo "  tlp-stop          - Stop TLP service" 
    echo "  tlp-ac            - Force TLP AC mode"
    echo "  tlp-bat           - Force TLP battery mode"
    echo "  tlp-status        - Show TLP status"
    echo ""
    echo -e "${YELLOW}Hibernation Commands:${NC}"
    echo "  hibernate         - Hibernate with encrypted swap"
    echo "  hibstatus         - Show hibernation system status"
    echo "  swap-on           - Manually activate hibernation swap"
    echo "  swap-off          - Manually deactivate hibernation swap"
    echo ""
    echo -e "${YELLOW}System Integration:${NC}"
    echo "  startup           - Apply startup power mode (used by systemd)"
    echo "  wake              - Apply wake power mode (used by systemd)"
    echo "  desktop           - Show detected desktop environment"
    echo ""
    echo -e "${YELLOW}Environment Detection:${NC}"
    echo "  Desktop: $(detect_desktop)"
    echo "  powerprofilesctl: $(has_powerprofilesctl && echo "Available" || echo "Not available")"
    echo "  gsettings: $(has_gsettings && echo "Available" || echo "Not available")"
    echo "  tlp: $(has_tlp && echo "Available" || echo "Not available")"
    echo -e "${MAGENTA}  envycontrol: $(has_envycontrol && echo "✅ Available" || echo "❌ Not available")${NC}"
}

# ============================================================================
# MAIN COMMAND PROCESSING
# ============================================================================

case "$1" in
    # Power preset commands (NEW - your comprehensive pool)
    "ultra-eco")
        apply_preset "ultra-eco"
        ;;
    "eco-gaming")
        apply_preset "eco-gaming"
        ;;
    "balanced-dgpu")
        apply_preset "balanced-dgpu"
        ;;
    "performance-dgpu")
        apply_preset "performance-dgpu"
        ;;
    "gaming-max")
        apply_preset "gaming-max"
        ;;
    "work-mode")
        apply_preset "work-mode"
        ;;
    "developer-mode")
        apply_preset "developer-mode"
        ;;
    "preset")
        if [ -n "$2" ]; then
            apply_preset "$2"
        else
            error "Please specify preset name"
            echo "Available presets:"
            get_available_presets
        fi
        ;;
    
    # Legacy power profile commands (PRESERVED - no changes to maintain compatibility)
    "eco"|"power-saver")
        set_power_profile "power-saver"
        ;;
    "performance")
        set_power_profile "performance"
        ;;
    "balanced")
        set_power_profile "balanced"
        ;;
    
    # Preset management commands
    "list-presets")
        list_presets
        ;;
    
    # GPU-specific commands
    "gpu-integrated")
        set_gpu_mode "integrated"
        ;;
    "gpu-hybrid")
        set_gpu_mode "hybrid"
        ;;
    "gpu-nvidia")
        set_gpu_mode "nvidia"
        ;;
    "gpu-status")
        echo "Current GPU mode: $(get_current_gpu_mode)"
        ;;
    
    # System commands (PRESERVED)
    "status")
        show_comprehensive_status
        ;;
    "config")
        configure_system
        ;;
    "enable-auto")
        sed -i 's/AUTO_ECO_ON_STARTUP=.*/AUTO_ECO_ON_STARTUP=true/' "$CONFIG_FILE"
        sed -i 's/AUTO_ECO_ON_WAKE=.*/AUTO_ECO_ON_WAKE=true/' "$CONFIG_FILE"
        success "Auto-eco mode enabled for startup and wake"
        ;;
    "disable-auto")
        sed -i 's/AUTO_ECO_ON_STARTUP=.*/AUTO_ECO_ON_STARTUP=false/' "$CONFIG_FILE"
        sed -i 's/AUTO_ECO_ON_WAKE=.*/AUTO_ECO_ON_WAKE=false/' "$CONFIG_FILE"
        warning "Auto-eco mode disabled"
        ;;
    
    # TLP commands (PRESERVED)
    "tlp-start")
        tlp_start
        ;;
    "tlp-stop")
        tlp_stop
        ;;
    "tlp-ac")
        tlp_set_mode "ac"
        ;;
    "tlp-bat")
        tlp_set_mode "bat"
        ;;
    "tlp-status")
        if has_tlp; then
            sudo tlp-stat -s
        else
            error "TLP not available"
        fi
        ;;
    
    # Hibernation commands (PRESERVED - keeping all your existing ones)
    "hibernate")
        # Stop TLP before hibernation to prevent conflicts
        tlp_stop
        hibernate_system
        ;;
    "hibstatus")
        hibernation_status
        ;;
    "swap-on")
        activate_hibernation_swap
        ;;
    "swap-off")
        deactivate_hibernation_swap
        ;;
    
    # System integration (PRESERVED)
    "startup")
        apply_startup_mode
        ;;
    "wake")
        apply_wake_mode
        ;;
    "desktop")
        echo "Detected desktop environment: $(detect_desktop)"
        ;;
    
    # Help and default
    *)
        show_help
        ;;
esac
