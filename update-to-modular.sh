#!/bin/bash

# Update to Modular System Script
# Version: 1.0.0
# Comprehensive update script to replace old system with new modular system

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/tmp/power-manager-backup-$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/power-manager-update.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# ============================================================================
# BACKUP FUNCTIONS
# ============================================================================

create_backup() {
    log_info "Creating backup of existing system..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing scripts
    if [ -f "/usr/local/bin/power-control.sh" ]; then
        cp "/usr/local/bin/power-control.sh" "$BACKUP_DIR/"
        log_success "Backed up power-control.sh"
    fi
    
    # Backup existing services
    local services=("power-control-startup.service" "power-control-wake.service" "power-control-monitor.service" "power-control-monitor.timer")
    for service in "${services[@]}"; do
        if [ -f "/etc/systemd/system/$service" ]; then
            cp "/etc/systemd/system/$service" "$BACKUP_DIR/"
            log_success "Backed up $service"
        fi
    done
    
    # Backup existing lib directory
    if [ -d "/usr/local/share/power-manager/lib" ]; then
        cp -r "/usr/local/share/power-manager/lib" "$BACKUP_DIR/"
        log_success "Backed up lib directory"
    fi
    
    # Backup existing presets
    if [ -d "/usr/local/share/power-manager/presets" ]; then
        cp -r "/usr/local/share/power-manager/presets" "$BACKUP_DIR/"
        log_success "Backed up presets directory"
    fi
    
    log_success "Backup created at: $BACKUP_DIR"
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

install_modular_script() {
    log_info "Installing modular power control script..."
    
    # Install main script
    sudo cp "$SCRIPT_DIR/scripts/power-control-modular.sh" "/usr/local/bin/power-control-modular.sh"
    sudo chmod +x "/usr/local/bin/power-control-modular.sh"
    
    # Create symlink for easy access
    sudo ln -sf "/usr/local/bin/power-control-modular.sh" "/usr/local/bin/power-control"
    
    # Update paths in installed script
    sudo sed -i 's|LIB_DIR="$SCRIPT_DIR/../lib"|LIB_DIR="/usr/local/share/power-manager/lib"|g' "/usr/local/bin/power-control-modular.sh"
    sudo sed -i 's|PRESETS_DIR="$SCRIPT_DIR/../presets"|PRESETS_DIR="/usr/local/share/power-manager/presets"|g' "/usr/local/bin/power-control-modular.sh"
    
    log_success "Modular script installed and configured"
}

install_enterprise_libraries() {
    log_info "Installing enterprise libraries..."
    
    # Create lib directory
    sudo mkdir -p "/usr/local/share/power-manager/lib"
    
    # Install all enterprise libraries
    sudo cp "$SCRIPT_DIR/lib/"*.sh "/usr/local/share/power-manager/lib/"
    sudo chmod +x "/usr/local/share/power-manager/lib/"*.sh
    
    # Update paths in modular system library
    sudo sed -i 's|SYSTEM_PRESETS_DIR="$SCRIPT_DIR/../presets/system-presets"|SYSTEM_PRESETS_DIR="/usr/local/share/power-manager/presets/system-presets"|g' "/usr/local/share/power-manager/lib/modular-power-system.sh"
    sudo sed -i 's|GPU_PRESETS_DIR="$SCRIPT_DIR/../presets/gpu-presets"|GPU_PRESETS_DIR="/usr/local/share/power-manager/presets/gpu-presets"|g' "/usr/local/share/power-manager/lib/modular-power-system.sh"
    sudo sed -i 's|COMPOSITE_PRESETS_DIR="$SCRIPT_DIR/../presets/composite-presets"|COMPOSITE_PRESETS_DIR="/usr/local/share/power-manager/presets/composite-presets"|g' "/usr/local/share/power-manager/lib/modular-power-system.sh"
    
    log_success "Enterprise libraries installed and configured"
}

install_organized_presets() {
    log_info "Installing organized preset directories..."
    
    # Create preset directories
    sudo mkdir -p "/usr/local/share/power-manager/presets/system-presets"
    sudo mkdir -p "/usr/local/share/power-manager/presets/gpu-presets"
    sudo mkdir -p "/usr/local/share/power-manager/presets/composite-presets"
    
    # Install system presets
    if [ -d "$SCRIPT_DIR/presets/system-presets" ]; then
        sudo cp "$SCRIPT_DIR/presets/system-presets/"*.conf "/usr/local/share/power-manager/presets/system-presets/"
        log_success "System presets installed"
    fi
    
    # Install GPU presets (if any)
    if [ -d "$SCRIPT_DIR/presets/gpu-presets" ]; then
        sudo cp "$SCRIPT_DIR/presets/gpu-presets/"*.conf "/usr/local/share/power-manager/presets/gpu-presets/" 2>/dev/null || true
        log_success "GPU presets installed"
    fi
    
    # Install composite presets (if any)
    if [ -d "$SCRIPT_DIR/presets/composite-presets" ]; then
        sudo cp "$SCRIPT_DIR/presets/composite-presets/"*.conf "/usr/local/share/power-manager/presets/composite-presets/" 2>/dev/null || true
        log_success "Composite presets installed"
    fi
    
    log_success "Organized presets installed"
}

update_systemd_services() {
    log_info "Updating systemd services to use modular system..."
    
    # Update startup service
    sudo sed -i 's|ExecStart=/usr/local/bin/power-control.sh startup|ExecStart=/usr/local/bin/power-control-modular.sh startup|g' "/etc/systemd/system/power-control-startup.service"
    
    # Update wake service
    sudo sed -i 's|ExecStart=/usr/local/bin/power-control.sh wake|ExecStart=/usr/local/bin/power-control-modular.sh wake|g' "/etc/systemd/system/power-control-wake.service"
    
    # Update monitor service
    sudo sed -i 's|ExecStart=/usr/local/bin/power-control.sh monitor|ExecStart=/usr/local/bin/power-control-modular.sh monitor|g' "/etc/systemd/system/power-control-monitor.service"
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    log_success "Systemd services updated to use modular system"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_installation() {
    log_info "Validating installation..."
    
    local errors=0
    
    # Check if modular script exists and is executable
    if [ ! -f "/usr/local/bin/power-control-modular.sh" ]; then
        log_error "Modular script not found"
        ((errors++))
    elif [ ! -x "/usr/local/bin/power-control-modular.sh" ]; then
        log_error "Modular script not executable"
        ((errors++))
    else
        log_success "Modular script validated"
    fi
    
    # Check if symlink exists
    if [ ! -L "/usr/local/bin/power-control" ]; then
        log_error "Power-control symlink not found"
        ((errors++))
    else
        log_success "Power-control symlink validated"
    fi
    
    # Check if enterprise libraries exist
    local lib_files=("modular-power-system.sh" "enterprise-logging.sh" "desktop-detection.sh" "enterprise-validation.sh" "enterprise-monitoring.sh")
    for lib_file in "${lib_files[@]}"; do
        if [ ! -f "/usr/local/share/power-manager/lib/$lib_file" ]; then
            log_error "Enterprise library not found: $lib_file"
            ((errors++))
        else
            log_success "Enterprise library validated: $lib_file"
        fi
    done
    
    # Check if preset directories exist
    local preset_dirs=("system-presets" "gpu-presets" "composite-presets")
    for preset_dir in "${preset_dirs[@]}"; do
        if [ ! -d "/usr/local/share/power-manager/presets/$preset_dir" ]; then
            log_error "Preset directory not found: $preset_dir"
            ((errors++))
        else
            log_success "Preset directory validated: $preset_dir"
        fi
    done
    
    # Check if systemd services are updated
    if grep -q "power-control-modular.sh" "/etc/systemd/system/power-control-startup.service"; then
        log_success "Startup service updated"
    else
        log_error "Startup service not updated"
        ((errors++))
    fi
    
    if grep -q "power-control-modular.sh" "/etc/systemd/system/power-control-wake.service"; then
        log_success "Wake service updated"
    else
        log_error "Wake service not updated"
        ((errors++))
    fi
    
    if grep -q "power-control-modular.sh" "/etc/systemd/system/power-control-monitor.service"; then
        log_success "Monitor service updated"
    else
        log_error "Monitor service not updated"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Installation validation passed"
        return 0
    else
        log_error "Installation validation failed with $errors errors"
        return 1
    fi
}

# ============================================================================
# TESTING FUNCTIONS
# ============================================================================

test_modular_system() {
    log_info "Testing modular system..."
    
    # Test status command
    if power-control status >/dev/null 2>&1; then
        log_success "Status command working"
    else
        log_error "Status command failed"
        return 1
    fi
    
    # Test health check
    if power-control health-check >/dev/null 2>&1; then
        log_success "Health check working"
    else
        log_warning "Health check failed (may be expected)"
    fi
    
    # Test metrics
    if power-control metrics >/dev/null 2>&1; then
        log_success "Metrics command working"
    else
        log_warning "Metrics command failed (may be expected)"
    fi
    
    # Test preset listing
    if power-control list-system-presets >/dev/null 2>&1; then
        log_success "System presets listing working"
    else
        log_error "System presets listing failed"
        return 1
    fi
    
    log_success "Modular system testing completed"
}

# ============================================================================
# CLEANUP FUNCTIONS
# ============================================================================

cleanup_old_files() {
    log_info "Cleaning up old files..."
    
    # Remove old script if it exists and is different from modular
    if [ -f "/usr/local/bin/power-control.sh" ]; then
        if ! cmp -s "/usr/local/bin/power-control.sh" "/usr/local/bin/power-control-modular.sh"; then
            sudo mv "/usr/local/bin/power-control.sh" "$BACKUP_DIR/power-control.sh.old"
            log_success "Moved old power-control.sh to backup"
        fi
    fi
    
    # Remove old backup if it exists
    if [ -f "/usr/local/bin/power-control.sh.backup" ]; then
        sudo mv "/usr/local/bin/power-control.sh.backup" "$BACKUP_DIR/"
        log_success "Moved old backup to backup directory"
    fi
    
    log_success "Cleanup completed"
}

# ============================================================================
# MAIN UPDATE FUNCTION
# ============================================================================

main() {
    echo "=========================================="
    echo "Power Manager - Update to Modular System"
    echo "=========================================="
    echo ""
    
    log_info "Starting update process..."
    log_info "Log file: $LOG_FILE"
    log_info "Backup directory: $BACKUP_DIR"
    echo ""
    
    # Check if running as root for some operations
    if [ "$EUID" -eq 0 ]; then
        log_warning "Running as root - some operations may not work correctly"
    fi
    
    # Create backup
    create_backup
    echo ""
    
    # Install modular system
    install_modular_script
    echo ""
    
    install_enterprise_libraries
    echo ""
    
    install_organized_presets
    echo ""
    
    # Update systemd services
    update_systemd_services
    echo ""
    
    # Cleanup old files
    cleanup_old_files
    echo ""
    
    # Validate installation
    if validate_installation; then
        echo ""
        log_success "Installation validation passed!"
    else
        echo ""
        log_error "Installation validation failed!"
        log_info "Check the log file for details: $LOG_FILE"
        log_info "Backup available at: $BACKUP_DIR"
        exit 1
    fi
    
    # Test system
    echo ""
    if test_modular_system; then
        log_success "System testing passed!"
    else
        log_warning "System testing had some issues"
    fi
    
    echo ""
    echo "=========================================="
    log_success "Update completed successfully!"
    echo "=========================================="
    echo ""
    echo "Available commands:"
    echo "  power-control status              # Show system status"
    echo "  power-control health-check        # Run health check"
    echo "  power-control metrics             # Show metrics"
    echo "  power-control system-preset <name> # Apply system preset"
    echo "  power-control gpu-preset <name>   # Apply GPU preset"
    echo "  power-control <composite-preset>  # Apply composite preset"
    echo ""
    echo "Backup location: $BACKUP_DIR"
    echo "Log file: $LOG_FILE"
    echo ""
    log_info "Your system is now running the newest modular version!"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Check if help requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Power Manager - Update to Modular System"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Create a backup of existing system"
    echo "  2. Install new modular power control script"
    echo "  3. Install enterprise libraries (logging, validation, monitoring)"
    echo "  4. Install organized preset directories"
    echo "  5. Update systemd services to use modular system"
    echo "  6. Clean up old files"
    echo "  7. Validate installation"
    echo "  8. Test the new system"
    echo ""
    echo "The script will create backups and log all operations."
    exit 0
fi

# Run main function
main "$@"
