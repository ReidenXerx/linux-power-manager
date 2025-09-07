#!/bin/bash

# Migration Script: Fixed Presets → Modular System
# Version: 1.0.0
# Migrates from fixed preset system to modular system

set -e

# ============================================================================
# MIGRATION CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"
MIGRATION_LOG="$SCRIPT_DIR/migration.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[$timestamp]${NC} $message" | tee -a "$MIGRATION_LOG"
}

error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[$timestamp] ERROR${NC} $message" | tee -a "$MIGRATION_LOG"
}

success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[$timestamp] SUCCESS${NC} $message" | tee -a "$MIGRATION_LOG"
}

warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[$timestamp] WARNING${NC} $message" | tee -a "$MIGRATION_LOG"
}

# ============================================================================
# BACKUP FUNCTIONS
# ============================================================================

create_backup() {
    local file="$1"
    local backup_name="$2"
    
    if [ -f "$file" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_file="$BACKUP_DIR/${backup_name}.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_file"
        log "Created backup: $backup_file"
        return 0
    else
        warning "File not found for backup: $file"
        return 1
    fi
}

# ============================================================================
# MIGRATION FUNCTIONS
# ============================================================================

# Migrate old preset system to modular system
migrate_preset_system() {
    log "Migrating preset system to modular approach..."
    
    local old_presets_file="$HOME/.config/power-presets.conf"
    local new_system_presets="$HOME/.config/system-presets.conf"
    local new_gpu_presets="$HOME/.config/gpu-presets.conf"
    local new_composite_presets="$HOME/.config/composite-presets.conf"
    
    # Backup old presets file
    if [ -f "$old_presets_file" ]; then
        create_backup "$old_presets_file" "power-presets.conf"
    fi
    
    # Create organized preset directories
    create_organized_preset_directories
    
    # Create modular configuration files
    create_modular_configurations
    
    # Migrate existing presets
    migrate_existing_presets "$old_presets_file"
    
    success "Preset system migrated to modular approach"
}

# Create organized preset directories
create_organized_preset_directories() {
    log "Creating organized preset directories..."
    
    local presets_dir="$SCRIPT_DIR/presets"
    local system_presets_dir="$presets_dir/system-presets"
    local gpu_presets_dir="$presets_dir/gpu-presets"
    local composite_presets_dir="$presets_dir/composite-presets"
    
    # Create directories
    mkdir -p "$system_presets_dir"
    mkdir -p "$gpu_presets_dir"
    mkdir -p "$composite_presets_dir"
    
    # Move existing TLP presets to system presets
    local old_tlp_dir="$SCRIPT_DIR/configs/tlp-presets"
    if [ -d "$old_tlp_dir" ]; then
        mv "$old_tlp_dir"/* "$system_presets_dir/" 2>/dev/null || true
        rmdir "$old_tlp_dir" 2>/dev/null || true
    fi
    
    success "Organized preset directories created"
}

# Create modular configuration files
create_modular_configurations() {
    log "Creating modular configuration files..."
    
    # Create modular power configuration
    cat > "$HOME/.config/modular-power.conf" << MODULAR_CONF_EOF
# Modular Power Management Configuration
# Version: 1.0.0
# Migrated from fixed preset system

# System Management
SYSTEM_POWER_MANAGEMENT=true
GPU_POWER_MANAGEMENT=true
AUTONOMOUS_SYSTEM_GPU=true

# Default Presets
DEFAULT_SYSTEM_PRESET=balanced
DEFAULT_GPU_PRESET=hybrid
DEFAULT_COMPOSITE_PRESET=balanced-hybrid

# Auto-Application
AUTO_APPLY_ON_STARTUP=true
AUTO_APPLY_ON_WAKE=true
AUTO_APPLY_ON_AC_CHANGE=true

# Logging
MODULAR_LOGGING_ENABLED=true
LOG_LEVEL=6

# Validation
VALIDATION_ENABLED=true
PRESET_VALIDATION=true
CONFIG_VALIDATION=true

# Monitoring
MONITORING_ENABLED=true
PRESET_MONITORING=true
PERFORMANCE_MONITORING=true
MODULAR_CONF_EOF
    
    # Create system presets configuration
    cat > "$HOME/.config/system-presets.conf" << SYSTEM_PRESETS_EOF
# System Power Presets Configuration
# Format: PRESET_NAME_SETTING=value
# These presets control TLP, power profiles, WiFi, disk, and other hardware

# Ultra Eco - Maximum power savings
ULTRA_ECO_TLP_MODE=bat
ULTRA_ECO_POWER_PROFILE=power-saver
ULTRA_ECO_WIFI_MODE=aggressive
ULTRA_ECO_DISK_MODE=aggressive
ULTRA_ECO_DESCRIPTION="Maximum power savings for all hardware components"
ULTRA_ECO_BATTERY_TARGET="8-12+ hours"
ULTRA_ECO_PERFORMANCE_LEVEL="1/10"

# Eco - Good power savings
ECO_TLP_MODE=bat
ECO_POWER_PROFILE=power-saver
ECO_WIFI_MODE=balanced
ECO_DISK_MODE=balanced
ECO_DESCRIPTION="Good power savings with reasonable performance"
ECO_BATTERY_TARGET="6-8 hours"
ECO_PERFORMANCE_LEVEL="3/10"

# Balanced - Default balanced mode
BALANCED_TLP_MODE=auto
BALANCED_POWER_PROFILE=balanced
BALANCED_WIFI_MODE=balanced
BALANCED_DISK_MODE=balanced
BALANCED_DESCRIPTION="Balanced power and performance"
BALANCED_BATTERY_TARGET="4-6 hours"
BALANCED_PERFORMANCE_LEVEL="5/10"

# Performance - High performance
PERFORMANCE_TLP_MODE=ac
PERFORMANCE_POWER_PROFILE=performance
PERFORMANCE_WIFI_MODE=performance
PERFORMANCE_DISK_MODE=performance
PERFORMANCE_DESCRIPTION="High performance for demanding tasks"
PERFORMANCE_BATTERY_TARGET="2-4 hours"
PERFORMANCE_PERFORMANCE_LEVEL="8/10"

# Gaming - Optimized for gaming
GAMING_TLP_MODE=ac
GAMING_POWER_PROFILE=performance
GAMING_WIFI_MODE=performance
GAMING_DISK_MODE=performance
GAMING_DESCRIPTION="Optimized for gaming and intensive workloads"
GAMING_BATTERY_TARGET="1-3 hours"
GAMING_PERFORMANCE_LEVEL="9/10"

# Work - Optimized for productivity
WORK_TLP_MODE=balanced
WORK_POWER_PROFILE=balanced
WORK_WIFI_MODE=balanced
WORK_DISK_MODE=balanced
WORK_DESCRIPTION="Optimized for office work and productivity"
WORK_BATTERY_TARGET="5-7 hours"
WORK_PERFORMANCE_LEVEL="4/10"

# Developer - Optimized for development
DEVELOPER_TLP_MODE=ac
DEVELOPER_POWER_PROFILE=performance
DEVELOPER_WIFI_MODE=performance
DEVELOPER_DISK_MODE=performance
DEVELOPER_DESCRIPTION="Optimized for development with compilation and testing"
DEVELOPER_BATTERY_TARGET="2-4 hours"
DEVELOPER_PERFORMANCE_LEVEL="7/10"
SYSTEM_PRESETS_EOF
    
    # Create GPU presets configuration
    cat > "$HOME/.config/gpu-presets.conf" << GPU_PRESETS_EOF
# GPU Power Presets Configuration
# Format: PRESET_NAME_SETTING=value
# These presets control only GPU switching and GPU-specific settings

# Integrated - Intel GPU only
INTEGRATED_GPU_MODE=integrated
INTEGRATED_GPU_DESCRIPTION="Use integrated Intel GPU only"
INTEGRATED_GPU_POWER_USAGE="Low"
INTEGRATED_GPU_PERFORMANCE="Low"
INTEGRATED_GPU_BATTERY_IMPACT="Minimal"

# Hybrid - Dynamic switching
HYBRID_GPU_MODE=hybrid
HYBRID_GPU_DESCRIPTION="Dynamic switching between integrated and discrete GPU"
HYBRID_GPU_POWER_USAGE="Medium"
HYBRID_GPU_PERFORMANCE="Medium"
HYBRID_GPU_BATTERY_IMPACT="Moderate"

# Discrete - NVIDIA GPU only
DISCRETE_GPU_MODE=nvidia
DISCRETE_GPU_DESCRIPTION="Use discrete NVIDIA GPU only"
DISCRETE_GPU_POWER_USAGE="High"
DISCRETE_GPU_PERFORMANCE="High"
DISCRETE_GPU_BATTERY_IMPACT="Significant"

# Gaming - Optimized for gaming
GAMING_GPU_MODE=nvidia
GAMING_GPU_DESCRIPTION="Discrete GPU optimized for gaming"
GAMING_GPU_POWER_USAGE="High"
GAMING_GPU_PERFORMANCE="Maximum"
GAMING_GPU_BATTERY_IMPACT="Maximum"

# Eco - Power saving GPU
ECO_GPU_MODE=integrated
ECO_GPU_DESCRIPTION="Integrated GPU for maximum battery life"
ECO_GPU_POWER_USAGE="Minimal"
ECO_GPU_PERFORMANCE="Basic"
ECO_GPU_BATTERY_IMPACT="Minimal"
GPU_PRESETS_EOF
    
    # Create composite presets configuration
    cat > "$HOME/.config/composite-presets.conf" << COMPOSITE_PRESETS_EOF
# Composite Power Presets Configuration
# Format: PRESET_NAME_SYSTEM_PRESET=value, PRESET_NAME_GPU_PRESET=value
# These are convenient combinations of system and GPU presets

# Ultra Eco - Maximum battery life
ULTRA_ECO_COMPOSITE_SYSTEM_PRESET=ultra-eco
ULTRA_ECO_COMPOSITE_GPU_PRESET=eco
ULTRA_ECO_COMPOSITE_DESCRIPTION="Maximum battery life with integrated GPU"
ULTRA_ECO_COMPOSITE_BATTERY_TARGET="10-12+ hours"

# Eco Gaming - Light gaming with good battery
ECO_GAMING_COMPOSITE_SYSTEM_PRESET=eco
ECO_GAMING_COMPOSITE_GPU_PRESET=hybrid
ECO_GAMING_COMPOSITE_DESCRIPTION="Light gaming with good battery life"
ECO_GAMING_COMPOSITE_BATTERY_TARGET="4-6 hours"

# Balanced - Default balanced mode
BALANCED_COMPOSITE_SYSTEM_PRESET=balanced
BALANCED_COMPOSITE_GPU_PRESET=hybrid
BALANCED_COMPOSITE_DESCRIPTION="Balanced performance and efficiency"
BALANCED_COMPOSITE_BATTERY_TARGET="4-6 hours"

# Balanced dGPU - Balanced with discrete GPU
BALANCED_DGPU_COMPOSITE_SYSTEM_PRESET=balanced
BALANCED_DGPU_COMPOSITE_GPU_PRESET=discrete
BALANCED_DGPU_COMPOSITE_DESCRIPTION="Balanced mode with discrete GPU"
BALANCED_DGPU_COMPOSITE_BATTERY_TARGET="2-4 hours"

# Performance - High performance
PERFORMANCE_COMPOSITE_SYSTEM_PRESET=performance
PERFORMANCE_COMPOSITE_GPU_PRESET=hybrid
PERFORMANCE_COMPOSITE_DESCRIPTION="High performance for demanding tasks"
PERFORMANCE_COMPOSITE_BATTERY_TARGET="2-4 hours"

# Performance dGPU - High performance with discrete GPU
PERFORMANCE_DGPU_COMPOSITE_SYSTEM_PRESET=performance
PERFORMANCE_DGPU_COMPOSITE_GPU_PRESET=discrete
PERFORMANCE_DGPU_COMPOSITE_DESCRIPTION="High performance with discrete GPU"
PERFORMANCE_DGPU_COMPOSITE_BATTERY_TARGET="1-3 hours"

# Gaming Max - Maximum gaming performance
GAMING_MAX_COMPOSITE_SYSTEM_PRESET=gaming
GAMING_MAX_COMPOSITE_GPU_PRESET=gaming
GAMING_MAX_COMPOSITE_DESCRIPTION="Maximum performance for gaming"
GAMING_MAX_COMPOSITE_BATTERY_TARGET="1-2 hours"

# Work Mode - Optimized for productivity
WORK_MODE_COMPOSITE_SYSTEM_PRESET=work
WORK_MODE_COMPOSITE_GPU_PRESET=integrated
WORK_MODE_COMPOSITE_DESCRIPTION="Optimized for office work and productivity"
WORK_MODE_COMPOSITE_BATTERY_TARGET="6-8 hours"

# Developer Mode - For development workloads
DEVELOPER_MODE_COMPOSITE_SYSTEM_PRESET=developer
DEVELOPER_MODE_COMPOSITE_GPU_PRESET=hybrid
DEVELOPER_MODE_COMPOSITE_DESCRIPTION="Optimized for development workloads"
DEVELOPER_MODE_COMPOSITE_BATTERY_TARGET="3-5 hours"
COMPOSITE_PRESETS_EOF
    
    success "Modular configuration files created"
}

# Migrate existing presets
migrate_existing_presets() {
    local old_presets_file="$1"
    
    if [ ! -f "$old_presets_file" ]; then
        log "No existing presets file found, skipping migration"
        return 0
    fi
    
    log "Migrating existing presets from: $old_presets_file"
    
    # Extract system and GPU settings from old presets
    local system_presets="$HOME/.config/system-presets.conf"
    local gpu_presets="$HOME/.config/gpu-presets.conf"
    local composite_presets="$HOME/.config/composite-presets.conf"
    
    # Add custom presets if they exist
    while IFS= read -r line; do
        if [[ "$line" =~ ^[A-Z_]+_TLP_MODE= ]]; then
            local preset_name=$(echo "$line" | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]')
            local tlp_mode=$(echo "$line" | cut -d'=' -f2)
            
            # Add to system presets if not already present
            if ! grep -q "^${preset_name^^}_TLP_MODE=" "$system_presets"; then
                echo "" >> "$system_presets"
                echo "# Custom preset: $preset_name" >> "$system_presets"
                echo "${preset_name^^}_TLP_MODE=$tlp_mode" >> "$system_presets"
                echo "${preset_name^^}_DESCRIPTION=\"Custom system preset: $preset_name\"" >> "$system_presets"
            fi
        fi
        
        if [[ "$line" =~ ^[A-Z_]+_GPU_MODE= ]]; then
            local preset_name=$(echo "$line" | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]')
            local gpu_mode=$(echo "$line" | cut -d'=' -f2)
            
            # Add to GPU presets if not already present
            if ! grep -q "^${preset_name^^}_GPU_MODE=" "$gpu_presets"; then
                echo "" >> "$gpu_presets"
                echo "# Custom preset: $preset_name" >> "$gpu_presets"
                echo "${preset_name^^}_GPU_MODE=$gpu_mode" >> "$gpu_presets"
                echo "${preset_name^^}_DESCRIPTION=\"Custom GPU preset: $preset_name\"" >> "$gpu_presets"
            fi
        fi
    done < "$old_presets_file"
    
    success "Existing presets migrated to modular system"
}

# Create migration summary
create_migration_summary() {
    log "Creating migration summary..."
    
    local summary_file="$SCRIPT_DIR/MIGRATION_SUMMARY.md"
    
    cat > "$summary_file" << EOF
# Migration Summary: Fixed Presets → Modular System

## Migration Date: $(date)

## What Was Migrated

### Configuration Files
- ✅ \`~/.config/power-presets.conf\` → Modular system
- ✅ \`~/.config/modular-power.conf\` - Main modular configuration
- ✅ \`~/.config/system-presets.conf\` - System presets (TLP, power, WiFi, disk)
- ✅ \`~/.config/gpu-presets.conf\` - GPU presets (GPU switching only)
- ✅ \`~/.config/composite-presets.conf\` - Convenient combinations

### Scripts
- ✅ \`scripts/power-control-modular.sh\` - New modular power control script
- ✅ \`lib/modular-power-system.sh\` - Modular system library

## New Usage Patterns

### System Presets (Hardware Only)
\`\`\`bash
# Apply system preset only
power-control-modular.sh system-preset balanced
power-control-modular.sh system-preset ultra-eco
power-control-modular.sh system-preset gaming
\`\`\`

### GPU Presets (GPU Switching Only)
\`\`\`bash
# Apply GPU preset only
power-control-modular.sh gpu-preset hybrid
power-control-modular.sh gpu-preset integrated
power-control-modular.sh gpu-preset discrete
\`\`\`

### Composite Presets (System + GPU)
\`\`\`bash
# Apply composite preset (backward compatible)
power-control-modular.sh composite-preset gaming-max
power-control-modular.sh composite-preset ultra-eco
power-control-modular.sh composite-preset balanced
\`\`\`

### Quick Commands (Backward Compatible)
\`\`\`bash
# These still work as before
power-control-modular.sh ultra-eco
power-control-modular.sh gaming-max
power-control-modular.sh balanced
\`\`\`

## Benefits of Migration

### 1. Flexibility
- Mix and match any system preset with any GPU preset
- Create custom combinations on the fly
- Easy to test individual components

### 2. Maintainability
- Clear separation of concerns
- Easy to update system presets without affecting GPU logic
- Easy to add new presets

### 3. Extensibility
- Add new system presets without touching GPU code
- Add new GPU presets without touching system code
- Create new composite presets easily

### 4. Debugging
- Test system components separately
- Test GPU components separately
- Isolate issues to specific components

## Migration Backup
- Original files backed up to: \`$BACKUP_DIR\`
- Migration log: \`$MIGRATION_LOG\`

## Next Steps
1. Test the new modular system
2. Try mixing and matching presets
3. Create custom combinations
4. Review migration log for any issues

## Support
- Documentation: \`MODULAR_APPROACH.md\`
- Migration Summary: \`MIGRATION_SUMMARY.md\`
- Modular System: \`lib/modular-power-system.sh\`
EOF
    
    success "Migration summary created: $summary_file"
}

# ============================================================================
# MAIN MIGRATION FUNCTION
# ============================================================================

main() {
    echo "Migration: Fixed Presets → Modular System"
    echo "========================================"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        error "Do not run this script as root. It will use sudo when needed."
        exit 1
    fi
    
    # Initialize migration
    log "Starting migration process..."
    mkdir -p "$BACKUP_DIR"
    
    local errors=0
    
    # Perform migration
    migrate_preset_system || ((errors++))
    
    # Create summary
    create_migration_summary
    
    # Final status
    echo ""
    if [ $errors -eq 0 ]; then
        success "Migration completed successfully!"
        echo ""
        echo "Next steps:"
        echo "1. Test the new modular system:"
        echo "   $SCRIPT_DIR/scripts/power-control-modular.sh status"
        echo ""
        echo "2. Try mixing and matching presets:"
        echo "   $SCRIPT_DIR/scripts/power-control-modular.sh system-preset balanced"
        echo "   $SCRIPT_DIR/scripts/power-control-modular.sh gpu-preset hybrid"
        echo ""
        echo "3. Test composite presets:"
        echo "   $SCRIPT_DIR/scripts/power-control-modular.sh gaming-max"
        echo ""
        echo "4. Review migration summary:"
        echo "   cat $SCRIPT_DIR/MIGRATION_SUMMARY.md"
        echo ""
        echo "5. Read about the modular approach:"
        echo "   cat $SCRIPT_DIR/MODULAR_APPROACH.md"
    else
        error "Migration completed with $errors errors"
        echo ""
        echo "Please review the migration log for details:"
        echo "cat $MIGRATION_LOG"
        exit 1
    fi
}

# Run main function
main "$@"
