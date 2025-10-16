#!/bin/bash

# ==============================================================================
# NVIDIA FREEZE SESSION MANAGER
# ==============================================================================
# Description: Automatically manages NVIDIA freeze session configurations
#              based on current GPU mode to prevent system freezes
# Version: 1.0.0
# Author: Linux Power Manager
# ==============================================================================

# NVIDIA Freeze Session Manager Configuration
FREEZE_SUSPEND_CONFIG="/etc/systemd/system/systemd-suspend.service.d/20-restore-freeze-sessions.conf"
FREEZE_HIBERNATE_CONFIG="/etc/systemd/system/systemd-hibernate.service.d/20-restore-freeze-sessions.conf"

# Logging functions (fallback if not available)
log_info() {
    echo -e "\033[0;36m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# ==============================================================================
# FREEZE SESSION MANAGEMENT FUNCTIONS
# ==============================================================================

# Check current GPU mode
get_current_gpu_mode() {
    local gpu_mode="unknown"
    
    # Use envycontrol for GPU mode detection
    if command -v envycontrol >/dev/null 2>&1; then
        gpu_mode=$(envycontrol --query 2>/dev/null | tr -d '\n' || echo "unknown")
    fi
    
    # Normalize mode names
    case "$gpu_mode" in
        "nvidia"|"discrete"|"dedicated")
            echo "nvidia"
            ;;
        "integrated"|"intel")
            echo "integrated"
            ;;
        "hybrid")
            echo "hybrid"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if freeze session configs exist
freeze_configs_exist() {
    [ -f "${FREEZE_SUSPEND_CONFIG}" ] || [ -f "${FREEZE_HIBERNATE_CONFIG}" ]
}

# Check if freeze session configs are disabled (have .disabled extension)
freeze_configs_disabled() {
    [ -f "${FREEZE_SUSPEND_CONFIG}.disabled" ] || [ -f "${FREEZE_HIBERNATE_CONFIG}.disabled" ]
}

# Enable freeze session overrides (for Intel/integrated GPU mode)
enable_freeze_session_overrides() {
    local changed=false
    
    log_info "Enabling freeze session overrides for Intel GPU mode"
    
    # Create directories if they don't exist
    sudo mkdir -p "$(dirname "$FREEZE_SUSPEND_CONFIG")"
    sudo mkdir -p "$(dirname "$FREEZE_HIBERNATE_CONFIG")"
    
    # Enable suspend service override
    if [ -f "${FREEZE_SUSPEND_CONFIG}.disabled" ]; then
        sudo mv "${FREEZE_SUSPEND_CONFIG}.disabled" "${FREEZE_SUSPEND_CONFIG}"
        changed=true
    elif [ ! -f "${FREEZE_SUSPEND_CONFIG}" ]; then
        sudo tee "${FREEZE_SUSPEND_CONFIG}" >/dev/null << 'EOF'
[Service]
# Override NVIDIA's SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false setting
# This restores normal suspend behavior when using integrated graphics
Environment=
EOF
        changed=true
    fi
    
    # Enable hibernate service override
    if [ -f "${FREEZE_HIBERNATE_CONFIG}.disabled" ]; then
        sudo mv "${FREEZE_HIBERNATE_CONFIG}.disabled" "${FREEZE_HIBERNATE_CONFIG}"
        changed=true
    elif [ ! -f "${FREEZE_HIBERNATE_CONFIG}" ]; then
        sudo tee "${FREEZE_HIBERNATE_CONFIG}" >/dev/null << 'EOF'
[Service]
# Override NVIDIA's SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false setting
# This restores normal suspend behavior when using integrated graphics
Environment=
EOF
        changed=true
    fi
    
    if [ "$changed" = "true" ]; then
        sudo systemctl daemon-reload
        log_success "Freeze session overrides enabled for Intel GPU suspend/resume"
    else
        log_info "Freeze session overrides already enabled"
    fi
}

# Disable freeze session overrides (for NVIDIA GPU mode)
disable_freeze_session_overrides() {
    local changed=false
    
    log_info "Disabling freeze session overrides for NVIDIA GPU mode"
    
    # Disable suspend service override
    if [ -f "${FREEZE_SUSPEND_CONFIG}" ]; then
        sudo mv "${FREEZE_SUSPEND_CONFIG}" "${FREEZE_SUSPEND_CONFIG}.disabled"
        changed=true
    fi
    
    # Disable hibernate service override
    if [ -f "${FREEZE_HIBERNATE_CONFIG}" ]; then
        sudo mv "${FREEZE_HIBERNATE_CONFIG}" "${FREEZE_HIBERNATE_CONFIG}.disabled"
        changed=true
    fi
    
    if [ "$changed" = "true" ]; then
        sudo systemctl daemon-reload
        log_success "Freeze session overrides disabled for NVIDIA GPU suspend/resume"
    else
        log_info "Freeze session overrides already disabled"
    fi
}

# Auto-configure freeze session based on current GPU mode
auto_configure_freeze_session() {
    local current_mode=$(get_current_gpu_mode)
    
    log_info "Auto-configuring freeze session for GPU mode: $current_mode"
    
    case "$current_mode" in
        "nvidia"|"discrete")
            # NVIDIA/discrete mode: Disable freeze session overrides
            # Let NVIDIA handle suspend properly
            disable_freeze_session_overrides
            ;;
        "integrated")
            # Intel integrated mode: Enable freeze session overrides
            # Intel needs proper freeze session handling
            enable_freeze_session_overrides
            ;;
        "hybrid")
            # Hybrid mode: Keep current configuration
            # Hybrid mode can handle both, so don't change
            log_info "Hybrid mode detected - keeping current freeze session configuration"
            ;;
        "unknown")
            log_warning "Unknown GPU mode - not changing freeze session configuration"
            return 1
            ;;
    esac
    
    return 0
}

# Show current freeze session status
show_freeze_session_status() {
    local current_mode=$(get_current_gpu_mode)
    
    echo "=== NVIDIA Freeze Session Manager Status ==="
    echo "Current GPU Mode: $current_mode"
    echo ""
    
    if [ -f "${FREEZE_SUSPEND_CONFIG}" ]; then
        echo "Suspend Override: ENABLED (Intel GPU optimized)"
    elif [ -f "${FREEZE_SUSPEND_CONFIG}.disabled" ]; then
        echo "Suspend Override: DISABLED (NVIDIA GPU optimized)"
    else
        echo "Suspend Override: NOT CONFIGURED"
    fi
    
    if [ -f "${FREEZE_HIBERNATE_CONFIG}" ]; then
        echo "Hibernate Override: ENABLED (Intel GPU optimized)"
    elif [ -f "${FREEZE_HIBERNATE_CONFIG}.disabled" ]; then
        echo "Hibernate Override: DISABLED (NVIDIA GPU optimized)"
    else
        echo "Hibernate Override: NOT CONFIGURED"
    fi
    
    echo ""
    echo "Configuration Files:"
    echo "  Suspend Config: $FREEZE_SUSPEND_CONFIG"
    echo "  Hibernate Config: $FREEZE_HIBERNATE_CONFIG"
}

# ==============================================================================
# INTEGRATION FUNCTIONS FOR POWER CONTROL SYSTEM
# ==============================================================================

# Hook function to be called after GPU mode change
on_gpu_mode_changed() {
    local new_mode="$1"
    local old_mode="$2"
    
    log_info "GPU mode changed from $old_mode to $new_mode - updating freeze session configuration"
    
    # Wait a moment for GPU switch to settle
    sleep 2
    
    # Auto-configure based on new mode
    auto_configure_freeze_session
}

# Hook function to be called before applying GPU preset
on_apply_gpu_preset() {
    local preset_name="$1"
    local gpu_mode="$2"
    
    log_info "Applying GPU preset '$preset_name' with mode '$gpu_mode'"
    
    # Pre-configure freeze session based on target mode
    case "$gpu_mode" in
        "nvidia"|"discrete")
            disable_freeze_session_overrides
            ;;
        "integrated")
            enable_freeze_session_overrides
            ;;
        "hybrid")
            log_info "Hybrid mode preset - keeping current freeze session configuration"
            ;;
    esac
}

# ==============================================================================
# MAIN CLI INTERFACE
# ==============================================================================

main() {
    case "${1:-status}" in
        "status"|"show")
            show_freeze_session_status
            ;;
        "auto"|"configure")
            auto_configure_freeze_session
            ;;
        "enable")
            enable_freeze_session_overrides
            ;;
        "disable")
            disable_freeze_session_overrides
            ;;
        "gpu-mode")
            echo $(get_current_gpu_mode)
            ;;
        "help"|"--help"|"-h")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  status      Show current freeze session configuration status"
            echo "  auto        Auto-configure based on current GPU mode"
            echo "  enable      Enable freeze session overrides (for Intel GPU)"
            echo "  disable     Disable freeze session overrides (for NVIDIA GPU)"
            echo "  gpu-mode    Show current GPU mode"
            echo "  help        Show this help message"
            echo ""
            echo "This tool automatically manages NVIDIA freeze session configurations"
            echo "to prevent system freezes when switching between GPU modes."
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
