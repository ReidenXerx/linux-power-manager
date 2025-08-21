#!/bin/bash

# Linux Power Manager - Uninstaller
# Safely removes all components
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Script paths
INSTALL_PREFIX="/usr/local/bin"
CONFIG_DIR="$HOME/.config"
SERVICE_DIR="/etc/systemd/system"

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
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

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        error "Do not run this script as root. It will use sudo when needed."
        exit 1
    fi
}

# Remove systemd services
remove_services() {
    log "Removing systemd services..."
    
    # Stop and disable services
    for service in power-control-startup power-control-wake power-control-monitor disk-monitor; do
        if systemctl is-enabled "${service}.service" > /dev/null 2>&1; then
            sudo systemctl disable "${service}.service"
            info "Disabled ${service}.service"
        fi
        if systemctl is-enabled "${service}.timer" > /dev/null 2>&1; then
            sudo systemctl disable "${service}.timer"
            info "Disabled ${service}.timer"
        fi
    done
    
    # Remove service files
    for file in power-control-startup.service power-control-wake.service power-control-monitor.service power-control-monitor.timer disk-monitor.service disk-monitor.timer; do
        if [ -f "$SERVICE_DIR/$file" ]; then
            sudo rm "$SERVICE_DIR/$file"
            info "Removed $file"
        fi
    done
    
    sudo systemctl daemon-reload
    success "Systemd services removed"
}

# Remove scripts
remove_scripts() {
    log "Removing power management scripts..."
    
    for script in power-control.sh power-status.sh disk-manager.sh; do
        if [ -f "$INSTALL_PREFIX/$script" ]; then
            sudo rm "$INSTALL_PREFIX/$script"
            info "Removed $script"
        fi
    done
    
    success "Scripts removed"
}

# Remove configurations (with backup option)
remove_configs() {
    log "Removing configuration files..."
    
    read -p "Remove configuration files? This will delete your custom settings (y/N): " remove_configs
    case "$remove_configs" in
        [Yy]*)
            # Create backup before removal
            BACKUP_DIR="$HOME/.config/power-manager-backup-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$BACKUP_DIR"
            
            for config in power-control.conf power-presets.conf power-manager.conf; do
                if [ -f "$CONFIG_DIR/$config" ]; then
                    cp "$CONFIG_DIR/$config" "$BACKUP_DIR/"
                    rm "$CONFIG_DIR/$config"
                    info "Backed up and removed $config"
                fi
            done
            
            info "Configuration backups saved to: $BACKUP_DIR"
            success "Configuration files removed"
            ;;
        *)
            info "Configuration files preserved"
            ;;
    esac
}

# Remove aliases
remove_aliases() {
    log "Removing bash aliases..."
    
    ALIAS_FILE="$HOME/.bash_aliases"
    
    if [ -f "$ALIAS_FILE" ] && grep -q "# Linux Power Manager aliases" "$ALIAS_FILE"; then
        # Remove our aliases section
        sed -i '/# Linux Power Manager aliases/,/^$/d' "$ALIAS_FILE"
        success "Bash aliases removed"
        info "Restart your terminal or run 'source ~/.bashrc' to update"
    else
        info "No aliases found to remove"
    fi
}

# Restore power-profiles-daemon if it was masked
restore_power_profiles() {
    log "Checking power-profiles-daemon..."
    
    if systemctl is-masked power-profiles-daemon.service >/dev/null 2>&1; then
        read -p "Restore power-profiles-daemon service? (Y/n): " restore_ppd
        case "$restore_ppd" in
            [Nn]*)
                info "power-profiles-daemon remains masked"
                ;;
            *)
                sudo systemctl unmask power-profiles-daemon.service
                sudo systemctl enable power-profiles-daemon.service
                sudo systemctl start power-profiles-daemon.service
                success "power-profiles-daemon restored"
                ;;
        esac
    else
        info "power-profiles-daemon was not modified"
    fi
}

# Show removal summary
show_summary() {
    echo ""
    echo -e "${CYAN}Linux Power Manager - Uninstallation Summary${NC}"
    echo "============================================="
    echo -e "${GREEN}✓${NC} Systemd services removed"
    echo -e "${GREEN}✓${NC} Scripts removed from $INSTALL_PREFIX"
    echo -e "${GREEN}✓${NC} Bash aliases removed"
    
    if [ -d "$HOME/.config/power-manager-backup-"* ] 2>/dev/null; then
        echo -e "${YELLOW}ℹ${NC} Configuration files backed up"
    fi
    
    echo ""
    echo -e "${YELLOW}Note:${NC} The following were NOT removed (manual removal required):"
    echo "  - TLP (if installed by this script)"
    echo "  - envycontrol (if installed by this script)"
    echo "  - System packages (bc, acpi, lm-sensors, etc.)"
    echo ""
    echo -e "${CYAN}To completely remove TLP:${NC}"
    echo "  sudo systemctl disable tlp.service"
    echo "  # Then use your package manager to remove tlp"
    echo ""
    echo -e "${CYAN}To remove envycontrol:${NC}"
    echo "  pip3 uninstall envycontrol"
    echo "  # Or pipx uninstall envycontrol"
}

# Interactive confirmation
confirm_removal() {
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║         Linux Power Manager Uninstaller      ║${NC}"
    echo -e "${PURPLE}║              Component Removal                ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}This will remove:${NC}"
    echo "  • Power management scripts"
    echo "  • Disk management scripts"
    echo "  • Systemd services and timers"
    echo "  • Bash aliases"
    echo "  • Configuration files (optional)"
    echo ""
    
    read -p "Are you sure you want to uninstall Linux Power Manager? (y/N): " confirm
    case "$confirm" in
        [Yy]*)
            return 0
            ;;
        *)
            echo "Uninstallation cancelled."
            exit 0
            ;;
    esac
}

# Main uninstallation function
main() {
    check_root
    confirm_removal
    
    echo ""
    log "Starting uninstallation..."
    echo ""
    
    remove_services
    remove_scripts
    remove_configs
    remove_aliases
    restore_power_profiles
    
    echo ""
    success "Uninstallation completed!"
    show_summary
}

# Handle command line arguments
case "$1" in
    "--help"|"-h")
        echo "Linux Power Manager Uninstaller"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h          Show this help"
        echo ""
        echo "This script will safely remove all Linux Power Manager components."
        echo "Configuration files can optionally be preserved or backed up."
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
