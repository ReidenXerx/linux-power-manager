#!/bin/bash

# Universal Power Status Manager with Enhanced Preset Integration
# Works with both KDE and GNOME environments
# Integrated with power-control.sh preset system

CONFIG_FILE="$HOME/.config/power-manager.conf"
POWER_CONTROL_SCRIPT="/usr/local/bin/power-control.sh"
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

# Create config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Initialize config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
AUTO_ECO_ON_STARTUP=true
AUTO_ECO_ON_WAKE=true
PREFER_GNOME_NATIVE=true
EOF
fi

# Source config
source "$CONFIG_FILE"

# Check if enhanced power control is available
has_power_control() {
    [ -f "$POWER_CONTROL_SCRIPT" ] && [ -x "$POWER_CONTROL_SCRIPT" ]
}

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

# Check if powerprofilesctl is available
has_powerprofilesctl() {
    command -v powerprofilesctl >/dev/null 2>&1
}

# Check if gsettings is available
has_gsettings() {
    command -v gsettings >/dev/null 2>&1
}

# Get battery information
get_battery_info() {
    local desktop=$(detect_desktop)
    local battery_path="/sys/class/power_supply/BAT0"
    
    if [ -d "$battery_path" ]; then
        local capacity=$(cat "$battery_path/capacity" 2>/dev/null || echo "N/A")
        local status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
        echo "🔋 Battery: ${capacity}% (${status})"
    elif command -v acpi >/dev/null 2>&1; then
        local battery_info=$(acpi -b | head -1)
        echo "🔋 Battery: $battery_info"
    else
        echo "🔋 Battery: Unable to detect"
    fi
}

# Get power profile using different methods
get_power_profile() {
    local desktop=$(detect_desktop)
    
    # Try powerprofilesctl first (works on both KDE and GNOME)
    if has_powerprofilesctl; then
        echo "$(powerprofilesctl get)"
        return 0
    fi
    
    # GNOME-specific method
    if [ "$desktop" = "gnome" ] && has_gsettings; then
        local profile=$(gsettings get org.gnome.settings-daemon.plugins.power power-button-action 2>/dev/null || echo "unknown")
        echo "gnome:$profile"
        return 0
    fi
    
    # KDE-specific method (using powerdevil)
    if [ "$desktop" = "kde" ] && command -v kreadconfig5 >/dev/null 2>&1; then
        local profile=$(kreadconfig5 --file powermanagementprofilesrc --group AC --key icon 2>/dev/null || echo "unknown")
        echo "kde:$profile"
        return 0
    fi
    
    echo "unknown"
}

# Get current preset from power control system
get_current_preset() {
    if has_power_control; then
        "$POWER_CONTROL_SCRIPT" status | grep "Active Preset:" | sed 's/.*Active Preset: *//' | sed 's/ *║.*//' || echo "none"
    else
        echo "unavailable"
    fi
}

# Get GPU status if available
get_gpu_status() {
    if has_power_control; then
        "$POWER_CONTROL_SCRIPT" gpu-status 2>/dev/null | grep "Current GPU mode:" | cut -d':' -f2 | xargs || echo "unavailable"
    else
        echo "unavailable"
    fi
}

# Set power profile
set_power_profile() {
    local mode="$1"
    local desktop=$(detect_desktop)
    
    case "$mode" in
        "power-saver"|"eco")
            if has_powerprofilesctl; then
                powerprofilesctl set power-saver
                echo "✅ Set power profile to power-saver via powerprofilesctl"
            elif [ "$desktop" = "gnome" ] && has_gsettings; then
                gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 1800
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 900
                echo "✅ Applied power-saver settings via GNOME settings"
            else
                echo "⚠️  Unable to set power profile - no suitable method found"
                return 1
            fi
            ;;
        "performance")
            if has_powerprofilesctl; then
                powerprofilesctl set performance
                echo "✅ Set power profile to performance via powerprofilesctl"
            elif [ "$desktop" = "gnome" ] && has_gsettings; then
                gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing'
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
                echo "✅ Applied performance settings via GNOME settings"
            else
                echo "⚠️  Unable to set power profile - no suitable method found"
                return 1
            fi
            ;;
        "balanced")
            if has_powerprofilesctl; then
                powerprofilesctl set balanced
                echo "✅ Set power profile to balanced via powerprofilesctl"
            elif [ "$desktop" = "gnome" ] && has_gsettings; then
                gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800
                echo "✅ Applied balanced settings via GNOME settings"
            else
                echo "⚠️  Unable to set power profile - no suitable method found"
                return 1
            fi
            ;;
        *)
            echo "❌ Invalid power mode: $mode"
            return 1
            ;;
    esac
}

# Apply enhanced preset using power control system
apply_preset() {
    local preset="$1"
    
    if ! has_power_control; then
        echo "❌ Enhanced power control system not available"
        echo "   Please ensure $POWER_CONTROL_SCRIPT exists and is executable"
        return 1
    fi
    
    echo -e "${CYAN}🎯 Applying enhanced preset: $preset${NC}"
    "$POWER_CONTROL_SCRIPT" "$preset"
}

# List available presets
list_presets() {
    if ! has_power_control; then
        echo "❌ Enhanced power control system not available"
        return 1
    fi
    
    echo -e "${BLUE}📋 Available Enhanced Presets:${NC}"
    echo "================================"
    "$POWER_CONTROL_SCRIPT" list-presets
}

# Interactive preset selector
select_preset() {
    if ! has_power_control; then
        echo "❌ Enhanced power control system not available"
        return 1
    fi
    
    echo -e "${BLUE}🎯 Enhanced Preset Selection${NC}"
    echo "============================="
    echo ""
    
    # Get available presets using a more direct approach
    local presets=()
    mapfile -t presets < <("$POWER_CONTROL_SCRIPT" list-presets | grep -v "=" | grep -v ":" | grep -v "^$" | grep -v "^  ")
    
    if [ ${#presets[@]} -eq 0 ]; then
        echo "❌ No presets found"
        return 1
    fi
    
    echo "Available presets:"
    for i in "${!presets[@]}"; do
        echo "  $((i+1)). ${presets[i]}"
    done
    echo "  $((${#presets[@]}+1)). Cancel"
    echo ""
    
    read -p "Select preset (1-$((${#presets[@]}+1))): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#presets[@]} ]; then
        local selected_preset="${presets[$((choice-1))]}"
        echo ""
        apply_preset "$selected_preset"
    elif [ "$choice" -eq $((${#presets[@]}+1)) ]; then
        echo "Operation cancelled"
        return 0
    else
        echo "❌ Invalid selection"
        return 1
    fi
}

# Show comprehensive power status with enhanced info
show_status() {
    local desktop=$(detect_desktop)
    
    echo -e "${BLUE}🔋 Enhanced Universal Power Status${NC}"
    echo "===================================="
    echo -e "${YELLOW}Desktop Environment:${NC} $desktop"
    echo ""
    
    # Battery information
    get_battery_info
    echo ""
    
    # Power profile
    echo -e "${YELLOW}Power Profile:${NC} $(get_power_profile)"
    
    # Enhanced preset info if available
    if has_power_control; then
        local current_preset=$(get_current_preset)
        echo -e "${YELLOW}Active Preset:${NC} $current_preset"
        
        local gpu_status=$(get_gpu_status)
        if [ "$gpu_status" != "unavailable" ]; then
            echo -e "${YELLOW}GPU Mode:${NC} $gpu_status"
        fi
    fi
    
    # CPU information
    if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
        local turbo_status=$([ "$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)" = "0" ] && echo "Enabled" || echo "Disabled")
        echo -e "${YELLOW}Turbo Boost:${NC} $turbo_status"
    fi
    
    # Temperature
    if command -v sensors >/dev/null 2>&1; then
        local temp=$(sensors | grep "Package id 0" | awk '{print $4}' 2>/dev/null)
        if [ -n "$temp" ]; then
            echo -e "${YELLOW}CPU Temperature:${NC} $temp"
        fi
    fi
    
    # CPU frequencies
    echo -e "${YELLOW}CPU Frequencies (first 4 cores):${NC}"
    if command -v bc >/dev/null 2>&1; then
        cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | head -4 | while read freq; do
            echo "   $(echo "scale=2; $freq/1000" | bc) MHz"
        done
    fi
    
    # Configuration
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Auto-eco on startup: $AUTO_ECO_ON_STARTUP"
    echo "  Auto-eco on wake: $AUTO_ECO_ON_WAKE"
    echo "  Prefer GNOME native: $PREFER_GNOME_NATIVE"
    
    # Available power management tools
    echo ""
    echo -e "${YELLOW}Available Tools:${NC}"
    echo "  powerprofilesctl: $(has_powerprofilesctl && echo "Yes" || echo "No")"
    echo "  gsettings: $(has_gsettings && echo "Yes" || echo "No")"
    echo "  acpi: $(command -v acpi >/dev/null 2>&1 && echo "Yes" || echo "No")"
    echo "  sensors: $(command -v sensors >/dev/null 2>&1 && echo "Yes" || echo "No")"
    echo "  Enhanced power control: $(has_power_control && echo "Yes" || echo "No")"
}

# GNOME-specific power management (unchanged)
gnome_power_management() {
    if [ ! has_gsettings ]; then
        echo "❌ gsettings not available - GNOME power management not possible"
        return 1
    fi
    
    echo -e "${BLUE}🐧 GNOME Power Management${NC}"
    echo "1. Set screen brightness"
    echo "2. Configure suspend settings"
    echo "3. Set power button action"
    echo "4. Configure automatic suspend"
    echo "5. Back to main menu"
    
    read -p "Select option (1-5): " choice
    
    case "$choice" in
        1)
            read -p "Enter brightness (0-100): " brightness
            gsettings set org.gnome.settings-daemon.plugins.power idle-brightness "$brightness"
            echo "✅ Screen brightness set to $brightness%"
            ;;
        2)
            echo "Suspend settings:"
            echo "1. Never suspend"
            echo "2. Suspend after 15 minutes"
            echo "3. Suspend after 30 minutes"
            echo "4. Suspend after 1 hour"
            read -p "Select (1-4): " suspend_choice
            
            case "$suspend_choice" in
                1) timeout=0 ;;
                2) timeout=900 ;;
                3) timeout=1800 ;;
                4) timeout=3600 ;;
                *) echo "Invalid choice"; return 1 ;;
            esac
            
            gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout "$timeout"
            gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout "$timeout"
            echo "✅ Suspend timeout set to $timeout seconds"
            ;;
        3)
            echo "Power button actions:"
            echo "1. Nothing"
            echo "2. Suspend"
            echo "3. Hibernate"
            echo "4. Power off"
            read -p "Select (1-4): " action_choice
            
            case "$action_choice" in
                1) action="nothing" ;;
                2) action="suspend" ;;
                3) action="hibernate" ;;
                4) action="shutdown" ;;
                *) echo "Invalid choice"; return 1 ;;
            esac
            
            gsettings set org.gnome.settings-daemon.plugins.power power-button-action "$action"
            echo "✅ Power button action set to $action"
            ;;
        4)
            read -p "Enable automatic suspend? (y/n): " auto_suspend
            if [ "$auto_suspend" = "y" ]; then
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800
                echo "✅ Automatic suspend enabled"
            else
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
                gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
                echo "✅ Automatic suspend disabled"
            fi
            ;;
        5)
            return 0
            ;;
        *)
            echo "Invalid choice"
            return 1
            ;;
    esac
}

# Enhanced configuration
configure_auto() {
    echo -e "${BLUE}🔧 Universal Power Manager Configuration${NC}"
    echo "========================================"
    echo "Current settings:"
    echo "  Auto-eco on startup: $AUTO_ECO_ON_STARTUP"
    echo "  Auto-eco on wake: $AUTO_ECO_ON_WAKE"
    echo "  Prefer GNOME native: $PREFER_GNOME_NATIVE"
    echo ""
    
    read -p "Enable auto-eco on startup? (y/n): " startup
    read -p "Enable auto-eco on wake from sleep? (y/n): " wake
    read -p "Prefer GNOME native settings over powerprofilesctl? (y/n): " gnome_native
    
    AUTO_ECO_ON_STARTUP=$([ "$startup" = "y" ] && echo "true" || echo "false")
    AUTO_ECO_ON_WAKE=$([ "$wake" = "y" ] && echo "true" || echo "false")
    PREFER_GNOME_NATIVE=$([ "$gnome_native" = "y" ] && echo "true" || echo "false")
    
    cat > "$CONFIG_FILE" << EOF
AUTO_ECO_ON_STARTUP=$AUTO_ECO_ON_STARTUP
AUTO_ECO_ON_WAKE=$AUTO_ECO_ON_WAKE
PREFER_GNOME_NATIVE=$PREFER_GNOME_NATIVE
EOF
    
    echo -e "${GREEN}✅ Configuration saved!${NC}"
}

# Apply startup mode
apply_startup_mode() {
    if [ "$AUTO_ECO_ON_STARTUP" = "true" ]; then
        echo "🌱 Auto-applying eco-mode on startup..."
        set_power_profile "power-saver"
        if [ -f "$SCRIPT_DIR/eco-mode.sh" ]; then
            "$SCRIPT_DIR/eco-mode.sh"
        fi
    fi
}

# Apply wake mode
apply_wake_mode() {
    if [ "$AUTO_ECO_ON_WAKE" = "true" ]; then
        echo "🌱 Auto-applying eco-mode on wake..."
        set_power_profile "power-saver"
        if [ -f "$SCRIPT_DIR/eco-mode.sh" ]; then
            "$SCRIPT_DIR/eco-mode.sh"
        fi
    fi
}

# Show help
show_help() {
    echo -e "${BLUE}🔋 Enhanced Universal Power Mode Manager${NC}"
    echo "Usage: $0 [command]"
    echo ""
    echo -e "${YELLOW}Basic Commands:${NC}"
    echo "  eco          - Switch to eco mode"
    echo "  performance  - Switch to performance mode"
    echo "  balanced     - Switch to balanced mode"
    echo "  status       - Show current power status"
    echo "  config       - Configure auto-eco settings"
    echo "  gnome        - GNOME-specific power management"
    echo "  enable-auto  - Enable auto eco-mode"
    echo "  disable-auto - Disable auto eco-mode"
    echo "  startup      - Apply startup power mode (used by systemd)"
    echo "  wake         - Apply wake power mode (used by sleep/wake handler)"
    echo "  desktop      - Show detected desktop environment"
    echo ""
    echo -e "${YELLOW}Enhanced Preset Commands:${NC}"
    echo "  presets       - List all available enhanced presets"
    echo "  select-preset - Interactive preset selection"
    echo "  apply-preset  - Apply specific preset (usage: apply-preset <preset_name>)"
    echo ""
    echo -e "${YELLOW}Enhanced Preset Examples:${NC}"
    echo "  $0 apply-preset balanced-dgpu     - Balanced mode with discrete GPU"
    echo "  $0 apply-preset performance-dgpu  - Performance mode with discrete GPU"
    echo "  $0 apply-preset ultra-eco         - Maximum battery savings"
    echo "  $0 apply-preset gaming-max        - Maximum gaming performance"
    echo ""
    echo -e "${YELLOW}Environment Detection:${NC}"
    echo "  Desktop: $(detect_desktop)"
    echo "  powerprofilesctl: $(has_powerprofilesctl && echo "Available" || echo "Not available")"
    echo "  gsettings: $(has_gsettings && echo "Available" || echo "Not available")"
    echo "  Enhanced power control: $(has_power_control && echo "Available" || echo "Not available")"
}

# Main command processing
case "$1" in
    "eco")
        set_power_profile "power-saver"
        # Also run the original eco-mode script if it exists
        if [ -f "$SCRIPT_DIR/eco-mode.sh" ]; then
            "$SCRIPT_DIR/eco-mode.sh"
        fi
        ;;
    "performance")
        set_power_profile "performance"
        # Also run the original performance-mode script if it exists
        if [ -f "$SCRIPT_DIR/performance-mode.sh" ]; then
            "$SCRIPT_DIR/performance-mode.sh"
        fi
        ;;
    "balanced")
        set_power_profile "balanced"
        ;;
    "status")
        show_status
        ;;
    "config")
        configure_auto
        ;;
    "gnome")
        gnome_power_management
        ;;
    "enable-auto")
        sed -i 's/AUTO_ECO_ON_STARTUP=.*/AUTO_ECO_ON_STARTUP=true/' "$CONFIG_FILE"
        sed -i 's/AUTO_ECO_ON_WAKE=.*/AUTO_ECO_ON_WAKE=true/' "$CONFIG_FILE"
        echo -e "${GREEN}✅ Auto-eco mode enabled for startup and wake${NC}"
        ;;
    "disable-auto")
        sed -i 's/AUTO_ECO_ON_STARTUP=.*/AUTO_ECO_ON_STARTUP=false/' "$CONFIG_FILE"
        sed -i 's/AUTO_ECO_ON_WAKE=.*/AUTO_ECO_ON_WAKE=false/' "$CONFIG_FILE"
        echo -e "${YELLOW}🚫 Auto-eco mode disabled${NC}"
        ;;
    "startup")
        apply_startup_mode
        ;;
    "wake")
        apply_wake_mode
        ;;
    "desktop")
        echo "Detected desktop environment: $(detect_desktop)"
        ;;
    "presets")
        list_presets
        ;;
    "select-preset")
        select_preset
        ;;
    "apply-preset")
        if [ -z "$2" ]; then
            echo "❌ Usage: $0 apply-preset <preset_name>"
            echo "   Use '$0 presets' to see available presets"
            exit 1
        fi
        apply_preset "$2"
        ;;
    *)
        show_help
        ;;
esac
