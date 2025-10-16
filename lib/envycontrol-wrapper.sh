#!/bin/bash

# ==============================================================================
# ENVYCONTROL WRAPPER WITH FREEZE SESSION MANAGEMENT
# ==============================================================================
# Description: Wraps envycontrol commands to automatically manage freeze sessions
# Version: 1.0.0
# Author: Linux Power Manager
# ==============================================================================

# Path to the real envycontrol
REAL_ENVYCONTROL="/usr/bin/envycontrol-real"
FREEZE_MANAGER="/usr/local/bin/nvidia-freeze-manager"

# Check if the real envycontrol exists
if [ ! -f "$REAL_ENVYCONTROL" ]; then
    echo "Error: Real envycontrol not found at $REAL_ENVYCONTROL" >&2
    exit 1
fi

# Function to handle GPU switch with freeze session management
handle_gpu_switch() {
    local switch_command="$1"
    local target_mode="$2"
    
    echo "[ENVYCONTROL WRAPPER] Intercepted GPU switch to: $target_mode"
    
    # Get current mode before switching
    local current_mode=$($REAL_ENVYCONTROL --query 2>/dev/null || echo "unknown")
    
    # Pre-configure freeze session based on target mode
    if [ -f "$FREEZE_MANAGER" ]; then
        case "$target_mode" in
            "integrated")
                echo "[ENVYCONTROL WRAPPER] Pre-configuring freeze session for Intel GPU"
                $FREEZE_MANAGER enable 2>/dev/null || true
                ;;
            "nvidia"|"discrete")
                echo "[ENVYCONTROL WRAPPER] Pre-configuring freeze session for NVIDIA GPU"
                $FREEZE_MANAGER disable 2>/dev/null || true
                ;;
            "hybrid")
                echo "[ENVYCONTROL WRAPPER] Hybrid mode - keeping current freeze session config"
                ;;
        esac
    fi
    
    # Execute the real envycontrol command
    echo "[ENVYCONTROL WRAPPER] Executing: $REAL_ENVYCONTROL $switch_command $target_mode"
    $REAL_ENVYCONTROL $switch_command $target_mode
    local exit_code=$?
    
    # Post-switch configuration (if no reboot required)
    if [ $exit_code -eq 0 ]; then
        # Small delay to let the switch settle
        sleep 1
        
        # Verify the switch worked and update freeze session if needed
        local new_mode=$($REAL_ENVYCONTROL --query 2>/dev/null || echo "unknown")
        
        if [ "$new_mode" != "$current_mode" ] && [ -f "$FREEZE_MANAGER" ]; then
            echo "[ENVYCONTROL WRAPPER] GPU mode changed from $current_mode to $new_mode"
            echo "[ENVYCONTROL WRAPPER] Auto-configuring freeze session for new mode"
            $FREEZE_MANAGER auto 2>/dev/null || true
        fi
    fi
    
    return $exit_code
}

# Parse envycontrol arguments
case "$1" in
    "--switch"|"-s")
        if [ -n "$2" ]; then
            handle_gpu_switch "--switch" "$2"
        else
            echo "Error: --switch requires a mode (integrated, nvidia, hybrid)" >&2
            exit 1
        fi
        ;;
    "--query"|"-q")
        # Pass through query commands without interception
        exec $REAL_ENVYCONTROL "$@"
        ;;
    "--help"|"-h"|"")
        # Pass through help and empty commands
        exec $REAL_ENVYCONTROL "$@"
        ;;
    *)
        # For any other commands, check if it's a switch command
        if echo "$*" | grep -q -E "(integrated|nvidia|hybrid)" && echo "$*" | grep -q -E "(-s|--switch)"; then
            # Extract the mode from arguments
            local mode=""
            if echo "$*" | grep -q "integrated"; then
                mode="integrated"
            elif echo "$*" | grep -q "nvidia"; then
                mode="nvidia"  
            elif echo "$*" | grep -q "hybrid"; then
                mode="hybrid"
            fi
            
            if [ -n "$mode" ]; then
                handle_gpu_switch "--switch" "$mode"
            else
                # If we can't parse it, pass through
                exec $REAL_ENVYCONTROL "$@"
            fi
        else
            # Pass through all other commands unchanged
            exec $REAL_ENVYCONTROL "$@"
        fi
        ;;
esac
