#!/bin/bash

# ==============================================================================
# DYNAMIC PRESET UPDATER
# Updates all TLP presets to use dynamic Intel GPU frequency detection
# ==============================================================================

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="/usr/local/share/power-manager/lib"
PRESETS_DIR="/usr/local/share/power-manager/presets/system-presets"
PROJECT_PRESETS_DIR="/home/vadim/Documents/Projects/linux-power-manager/presets/system-presets"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load Intel GPU dynamic detection
if [ -f "$LIB_DIR/intel-gpu-detection.sh" ]; then
    source "$LIB_DIR/intel-gpu-detection.sh"
else
    echo "ERROR: Intel GPU detection library not found: $LIB_DIR/intel-gpu-detection.sh"
    exit 1
fi

# Update a single preset file with dynamic GPU frequencies
update_preset_file() {
    local preset_file="$1"
    local preset_name="$2"
    
    if [ ! -f "$preset_file" ]; then
        echo "WARNING: Preset file not found: $preset_file"
        return 1
    fi
    
    echo -e "${BLUE}Updating $preset_name preset with dynamic GPU frequencies...${NC}"
    
    # Create temporary file
    local temp_file=$(mktemp)
    
    # Copy original file
    cp "$preset_file" "$temp_file"
    
    # Generate dynamic GPU configuration for this preset
    local gpu_config=$(generate_intel_gpu_tlp_config "$preset_name")
    
    if [ $? -eq 0 ] && [ -n "$gpu_config" ]; then
        # Remove old Intel GPU configuration lines
        sed -i '/^INTEL_GPU_MIN_FREQ_ON_AC=/d' "$temp_file"
        sed -i '/^INTEL_GPU_MAX_FREQ_ON_AC=/d' "$temp_file"
        sed -i '/^INTEL_GPU_BOOST_FREQ_ON_AC=/d' "$temp_file"
        sed -i '/^INTEL_GPU_MIN_FREQ_ON_BAT=/d' "$temp_file"
        sed -i '/^INTEL_GPU_MAX_FREQ_ON_BAT=/d' "$temp_file"
        sed -i '/^INTEL_GPU_BOOST_FREQ_ON_BAT=/d' "$temp_file"
        sed -i '/^INTEL_GPU_DVFS_ON_AC=/d' "$temp_file"
        sed -i '/^INTEL_GPU_DVFS_ON_BAT=/d' "$temp_file"
        sed -i '/^#INTEL_GPU_MIN_FREQ_ON_AC=/d' "$temp_file"
        sed -i '/^#INTEL_GPU_MAX_FREQ_ON_AC=/d' "$temp_file"
        sed -i '/^#INTEL_GPU_BOOST_FREQ_ON_AC=/d' "$temp_file"
        
        # Remove old Intel GPU comment blocks
        sed -i '/^# Intel Arc Graphics - /,/^$/d' "$temp_file"
        sed -i '/^# Intel GPU - /,/^$/d' "$temp_file"
        
        # Find a good place to insert GPU configuration (after PCIe section)
        if grep -q "^PCIE_ASPM_ON" "$temp_file"; then
            # Insert after PCIe section
            sed -i "/^PCIE_ASPM_ON_BAT=/a\\
\\
$gpu_config\\
" "$temp_file"
        elif grep -q "^CPU_ENERGY_PERF_POLICY_ON_BAT=" "$temp_file"; then
            # Insert after CPU section if no PCIe section
            sed -i "/^CPU_ENERGY_PERF_POLICY_ON_BAT=/a\\
\\
$gpu_config\\
" "$temp_file"
        else
            # Append at the end if nothing else works
            echo "" >> "$temp_file"
            echo "$gpu_config" >> "$temp_file"
        fi
        
        # Replace original file
        sudo cp "$temp_file" "$preset_file"
        echo -e "${GREEN}✅ Updated $preset_name with dynamic GPU frequencies${NC}"
    else
        echo -e "${YELLOW}⚠️ Could not generate dynamic GPU config for $preset_name${NC}"
    fi
    
    # Cleanup
    rm -f "$temp_file"
}

# Main update process
main() {
    echo -e "${BLUE}=== Dynamic Preset Updater ===${NC}"
    echo "Updating all TLP presets with dynamic Intel GPU frequency detection..."
    echo ""
    
    # Detect Intel GPU frequencies first
    if ! detect_intel_gpu_frequencies; then
        echo "ERROR: Could not detect Intel GPU frequencies"
        exit 1
    fi
    
    echo -e "${GREEN}Intel GPU detected:${NC} Min=${INTEL_GPU_DETECTED_MIN}MHz, Max=${INTEL_GPU_DETECTED_MAX}MHz, RPn=${INTEL_GPU_DETECTED_RPn}MHz"
    echo ""
    
    # Update all preset files
    local presets=(
        "balanced"
        "ultra-eco" 
        "intel-eco"
        "gaming-max"
        "intel-arc-creative"
        "intel-arc-optimized"
        "intel-hybrid-performance"
    )
    
    for preset in "${presets[@]}"; do
        # Update project files first
        if [ -f "$PROJECT_PRESETS_DIR/${preset}.conf" ]; then
            update_preset_file "$PROJECT_PRESETS_DIR/${preset}.conf" "$preset"
        fi
        
        # Update installed system files
        if [ -f "$PRESETS_DIR/${preset}.conf" ]; then
            update_preset_file "$PRESETS_DIR/${preset}.conf" "$preset"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✅ All presets updated with dynamic Intel GPU frequencies!${NC}"
    echo ""
    echo "Updated presets are optimized for:"
    echo "• Power efficiency (since NVIDIA handles gaming)"
    echo "• Universal Intel GPU compatibility" 
    echo "• No more hardcoded frequency values"
    echo ""
    echo "Test with: power-control balanced"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
