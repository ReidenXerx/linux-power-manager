#!/bin/bash

# ==============================================================================
# INTEL GPU DYNAMIC FREQUENCY DETECTION - POWER EFFICIENCY FOCUSED
# For systems with NVIDIA dedicated GPU (Intel iGPU for efficiency only)
# ==============================================================================

# Detect Intel GPU frequency ranges dynamically
detect_intel_gpu_frequencies() {
    local gpu_card="/sys/class/drm/card0"
    
    # Check if Intel GPU exists
    if [ ! -d "$gpu_card" ]; then
        echo "WARNING: No Intel GPU found" >&2
        return 1
    fi
    
    # Check if it's an Intel GPU
    local gpu_driver=$(readlink -f "$gpu_card/device/driver" 2>/dev/null | xargs basename 2>/dev/null || echo "unknown")
    if [ "$gpu_driver" != "i915" ]; then
        echo "WARNING: Not an Intel GPU (driver: $gpu_driver)" >&2
        return 1
    fi
    
    # Get GPU frequency ranges
    local GT_MIN_FREQ=$(cat "$gpu_card/gt_min_freq_mhz" 2>/dev/null || echo "100")
    local GT_MAX_FREQ=$(cat "$gpu_card/gt_max_freq_mhz" 2>/dev/null || echo "2250")
    local GT_RPn_FREQ=$(cat "$gpu_card/gt_RPn_freq_mhz" 2>/dev/null || echo "800")  # Efficient min
    
    # Export detected frequencies
    export INTEL_GPU_DETECTED_MIN="$GT_MIN_FREQ"
    export INTEL_GPU_DETECTED_MAX="$GT_MAX_FREQ"
    export INTEL_GPU_DETECTED_RPn="$GT_RPn_FREQ"    # Efficient minimum
    
    # Calculate POWER-EFFICIENT frequencies only (no performance modes)
    # Use Intel's RPn (800MHz) as minimum - Intel's recommended efficient minimum
    
    # Ultra Eco: Absolute minimum power consumption
    export INTEL_GPU_ULTRA_ECO_MIN="$GT_RPn_FREQ"                  # Use Intel's efficient minimum (800MHz)
    export INTEL_GPU_ULTRA_ECO_MAX="$GT_RPn_FREQ"                  # Stay at efficient minimum
    export INTEL_GPU_ULTRA_ECO_BOOST="$GT_RPn_FREQ"               # No boost needed
    
    # Eco: Minimal power with basic functionality
    export INTEL_GPU_ECO_MIN="$GT_RPn_FREQ"                        # Use Intel's efficient minimum
    export INTEL_GPU_ECO_MAX=$(( GT_RPn_FREQ + 100 ))              # Slightly above efficient
    export INTEL_GPU_ECO_BOOST=$(( GT_RPn_FREQ + 200 ))            # Conservative boost
    
    # Balanced: Good balance for desktop/productivity (no gaming)
    export INTEL_GPU_BALANCED_MIN="$GT_RPn_FREQ"                   # Use Intel's efficient minimum
    export INTEL_GPU_BALANCED_MAX=$(( GT_RPn_FREQ + 300 ))         # Decent for desktop work
    export INTEL_GPU_BALANCED_BOOST=$(( GT_RPn_FREQ + 400 ))       # Light boost for responsiveness
    
    # Creative: For content creation (video editing, etc.) but still conservative
    export INTEL_GPU_CREATIVE_MIN="$GT_RPn_FREQ"                   # Use Intel's efficient minimum
    export INTEL_GPU_CREATIVE_MAX=$(( GT_RPn_FREQ + 500 ))         # Higher for media work
    export INTEL_GPU_CREATIVE_BOOST=$(( GT_RPn_FREQ + 600 ))       # Moderate boost for encoding
    
    return 0
}

# Get dynamic GPU frequency for a specific mode and type
get_intel_gpu_freq() {
    local preset_mode="$1"  # ultra-eco, eco, balanced, creative
    local freq_type="$2"    # min, max, boost
    local power_state="$3"  # ac, bat
    
    # Ensure frequencies are detected
    detect_intel_gpu_frequencies || return 1
    
    case "$preset_mode" in
        "ultra-eco")
            case "$freq_type" in
                "min") echo "$INTEL_GPU_ULTRA_ECO_MIN" ;;
                "max") echo "$INTEL_GPU_ULTRA_ECO_MAX" ;;
                "boost") echo "$INTEL_GPU_ULTRA_ECO_BOOST" ;;
            esac
            ;;
        "eco"|"intel-eco")
            case "$freq_type" in
                "min") echo "$INTEL_GPU_ECO_MIN" ;;
                "max") 
                    if [ "$power_state" = "bat" ]; then
                        echo "$INTEL_GPU_ECO_MAX"
                    else
                        echo "$(( INTEL_GPU_ECO_MAX + 100 ))"  # Slightly higher on AC
                    fi
                    ;;
                "boost") 
                    if [ "$power_state" = "bat" ]; then
                        echo "$INTEL_GPU_ECO_BOOST"
                    else
                        echo "$(( INTEL_GPU_ECO_BOOST + 100 ))"  # Slightly higher on AC
                    fi
                    ;;
            esac
            ;;
        "balanced")
            case "$freq_type" in
                "min") echo "$INTEL_GPU_BALANCED_MIN" ;;
                "max") 
                    if [ "$power_state" = "bat" ]; then
                        echo "$INTEL_GPU_BALANCED_MAX"
                    else
                        echo "$(( INTEL_GPU_BALANCED_MAX + 200 ))"  # Higher on AC
                    fi
                    ;;
                "boost") 
                    if [ "$power_state" = "bat" ]; then
                        echo "$INTEL_GPU_BALANCED_BOOST"
                    else
                        echo "$(( INTEL_GPU_BALANCED_BOOST + 200 ))"  # Higher on AC
                    fi
                    ;;
            esac
            ;;
        "creative"|"intel-arc-creative")
            case "$freq_type" in
                "min") echo "$INTEL_GPU_CREATIVE_MIN" ;;
                "max") 
                    if [ "$power_state" = "bat" ]; then
                        echo "$(( INTEL_GPU_CREATIVE_MAX - 100 ))"  # Lower on battery
                    else
                        echo "$INTEL_GPU_CREATIVE_MAX"
                    fi
                    ;;
                "boost") 
                    if [ "$power_state" = "bat" ]; then
                        echo "$(( INTEL_GPU_CREATIVE_BOOST - 100 ))"  # Lower on battery
                    else
                        echo "$INTEL_GPU_CREATIVE_BOOST"
                    fi
                    ;;
            esac
            ;;
        "gaming"|"gaming-max"|"performance"|"intel-arc-optimized"|"intel-hybrid-performance")
            # For gaming/performance presets, keep iGPU conservative since NVIDIA does the work
            case "$freq_type" in
                "min") echo "$INTEL_GPU_BALANCED_MIN" ;;
                "max") echo "$INTEL_GPU_BALANCED_MAX" ;;
                "boost") echo "$INTEL_GPU_BALANCED_BOOST" ;;
            esac
            ;;
        *)
            # Default to balanced
            get_intel_gpu_freq "balanced" "$freq_type" "$power_state"
            ;;
    esac
}

# Generate dynamic TLP GPU configuration
generate_intel_gpu_tlp_config() {
    local preset_mode="$1"  # eco, balanced, creative, etc.
    
    # Detect frequencies
    detect_intel_gpu_frequencies || return 1
    
    local gpu_min_ac=$(get_intel_gpu_freq "$preset_mode" "min" "ac")
    local gpu_max_ac=$(get_intel_gpu_freq "$preset_mode" "max" "ac")
    local gpu_boost_ac=$(get_intel_gpu_freq "$preset_mode" "boost" "ac")
    
    local gpu_min_bat=$(get_intel_gpu_freq "$preset_mode" "min" "bat")
    local gpu_max_bat=$(get_intel_gpu_freq "$preset_mode" "max" "bat")
    local gpu_boost_bat=$(get_intel_gpu_freq "$preset_mode" "boost" "bat")
    
    cat << EOF
# Intel GPU - POWER EFFICIENT (Auto-detected: Min=${INTEL_GPU_DETECTED_MIN}, RPn=${INTEL_GPU_DETECTED_RPn})
# Note: Using Intel's RPn (${INTEL_GPU_DETECTED_RPn}MHz) as minimum for efficiency
# Note: Optimized for power efficiency since NVIDIA handles gaming workloads
INTEL_GPU_MIN_FREQ_ON_AC=$gpu_min_ac
INTEL_GPU_MAX_FREQ_ON_AC=$gpu_max_ac
INTEL_GPU_BOOST_FREQ_ON_AC=$gpu_boost_ac

INTEL_GPU_MIN_FREQ_ON_BAT=$gpu_min_bat
INTEL_GPU_MAX_FREQ_ON_BAT=$gpu_max_bat
INTEL_GPU_BOOST_FREQ_ON_BAT=$gpu_boost_bat

# Intel GPU Power Management - EFFICIENCY FOCUSED
INTEL_GPU_DVFS_ON_AC=1
INTEL_GPU_DVFS_ON_BAT=1
EOF
}

# Test function to show detected frequencies
show_detected_intel_gpu_info() {
    echo "=== Intel GPU Dynamic Detection (Power Efficiency Focus) ==="
    
    if detect_intel_gpu_frequencies; then
        echo "Hardware Detected:"
        echo "  Min Freq: ${INTEL_GPU_DETECTED_MIN} MHz"
        echo "  Max Freq: ${INTEL_GPU_DETECTED_MAX} MHz"  
        echo "  RPn (Efficient): ${INTEL_GPU_DETECTED_RPn} MHz"
        echo ""
        echo "Power-Efficient Presets:"
        echo "  Ultra Eco Max: ${INTEL_GPU_ULTRA_ECO_MAX} MHz"
        echo "  Eco Max: ${INTEL_GPU_ECO_MAX} MHz"
        echo "  Balanced Max: ${INTEL_GPU_BALANCED_MAX} MHz"
        echo "  Creative Max: ${INTEL_GPU_CREATIVE_MAX} MHz"
        echo ""
        echo "Note: Gaming presets use balanced iGPU settings since NVIDIA handles gaming."
        
        echo ""
        echo "=== Sample TLP Config (Balanced) ==="
        generate_intel_gpu_tlp_config "balanced"
    else
        echo "ERROR: Could not detect Intel GPU frequencies"
        return 1
    fi
}
