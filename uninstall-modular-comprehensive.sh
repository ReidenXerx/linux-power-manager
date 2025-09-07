#!/bin/bash

# Linux Power Manager - Comprehensive Modular Uninstaller
# Safely removes all components of the modular power management system
# Version: 2.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_PREFIX="/usr/local/bin"
LIB_PREFIX="/usr/local/share/power-manager"
CONFIG_DIR="$HOME/.config"
SERVICE_DIR="/etc/systemd/system"
PRESETS_DIR="/usr/local/share/power-manager/presets"

# Uninstall options
REMOVE_CONFIGS=false
REMOVE_ALIASES=true
REMOVE_DESKTOP_SHORTCUTS=true
REMOVE_MAN_PAGES=true
REMOVE_SHELL_COMPLETION=true
STOP_SERVICES=true
DISABLE_TLP=false

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

# Confirm uninstallation
confirm_uninstall() {
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    ⚠️  UNINSTALL CONFIRMATION ⚠️                         ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}This will remove the Linux Power Manager modular system:${NC}"
    echo ""
    echo -e "${CYAN}Components to be removed:${NC}"
    echo -e "  • Main scripts (power-control, disk-manager, wifi-intel-optimizer)"
    echo -e "  • Libraries and enterprise features"
    echo -e "  • Systemd services and timers"
    echo -e "  • Presets and configurations"
    echo -e "  • Aliases and shortcuts"
    echo -e "  • Man pages and shell completion"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  • Remove configs: $REMOVE_CONFIGS"
    echo -e "  • Remove aliases: $REMOVE_ALIASES"
    echo -e "  • Remove shortcuts: $REMOVE_DESKTOP_SHORTCUTS"
    echo -e "  • Remove man pages: $REMOVE_MAN_PAGES"
    echo -e "  • Remove completion: $REMOVE_SHELL_COMPLETION"
    echo -e "  • Stop services: $STOP_SERVICES"
    echo -e "  • Disable TLP: $DISABLE_TLP"
    echo ""
    
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        info "Uninstallation cancelled"
        exit 0
    fi
}

# Stop and disable services
stop_services() {
    if [ "$STOP_SERVICES" != "true" ]; then
        info "Skipping service stopping"
        return 0
    fi
    
    log "Stopping and disabling services..."
    
    # Stop services
    sudo systemctl stop power-control-startup.service 2>/dev/null || true
    sudo systemctl stop power-control-wake.service 2>/dev/null || true
    sudo systemctl stop power-control-monitor.service 2>/dev/null || true
    sudo systemctl stop power-control-monitor.timer 2>/dev/null || true
    sudo systemctl stop disk-monitor.service 2>/dev/null || true
    sudo systemctl stop disk-monitor.timer 2>/dev/null || true
    sudo systemctl stop wifi-power-monitor.service 2>/dev/null || true
    sudo systemctl stop wifi-power-monitor.timer 2>/dev/null || true
    sudo systemctl stop wifi-power-optimizer.service 2>/dev/null || true
    
    # Disable services
    sudo systemctl disable power-control-startup.service 2>/dev/null || true
    sudo systemctl disable power-control-wake.service 2>/dev/null || true
    sudo systemctl disable power-control-monitor.service 2>/dev/null || true
    sudo systemctl disable power-control-monitor.timer 2>/dev/null || true
    sudo systemctl disable disk-monitor.service 2>/dev/null || true
    sudo systemctl disable disk-monitor.timer 2>/dev/null || true
    sudo systemctl disable wifi-power-monitor.service 2>/dev/null || true
    sudo systemctl disable wifi-power-monitor.timer 2>/dev/null || true
    sudo systemctl disable wifi-power-optimizer.service 2>/dev/null || true
    
    success "Services stopped and disabled"
}

# Remove systemd service files
remove_services() {
    log "Removing systemd service files..."
    
    # Remove service files
    sudo rm -f "$SERVICE_DIR/power-control-startup.service"
    sudo rm -f "$SERVICE_DIR/power-control-wake.service"
    sudo rm -f "$SERVICE_DIR/power-control-monitor.service"
    sudo rm -f "$SERVICE_DIR/power-control-monitor.timer"
    sudo rm -f "$SERVICE_DIR/disk-monitor.service"
    sudo rm -f "$SERVICE_DIR/disk-monitor.timer"
    sudo rm -f "$SERVICE_DIR/wifi-power-monitor.service"
    sudo rm -f "$SERVICE_DIR/wifi-power-monitor.timer"
    sudo rm -f "$SERVICE_DIR/wifi-power-optimizer.service"
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    success "Systemd service files removed"
}

# Remove main scripts
remove_scripts() {
    log "Removing main scripts..."
    
    # Remove main scripts
    sudo rm -f "$INSTALL_PREFIX/power-control-modular.sh"
    sudo rm -f "$INSTALL_PREFIX/power-control"
    sudo rm -f "$INSTALL_PREFIX/disk-manager.sh"
    sudo rm -f "$INSTALL_PREFIX/wifi-intel-optimizer.sh"
    
    success "Main scripts removed"
}

# Remove libraries
remove_libraries() {
    log "Removing libraries..."
    
    # Remove library directory
    sudo rm -rf "$LIB_PREFIX"
    
    success "Libraries removed"
}

# Remove presets
remove_presets() {
    log "Removing presets..."
    
    # Presets are removed with libraries (same directory)
    info "Presets removed with libraries"
    
    success "Presets removed"
}

# Remove configuration files
remove_configs() {
    if [ "$REMOVE_CONFIGS" != "true" ]; then
        info "Keeping configuration files"
        return 0
    fi
    
    log "Removing configuration files..."
    
    # Remove config files
    rm -f "$CONFIG_DIR/power-control.conf"
    rm -f "$CONFIG_DIR/disk-manager.conf"
    rm -f "$CONFIG_DIR/wifi-intel-optimizations.conf"
    rm -f "$CONFIG_DIR/system-presets.conf"
    rm -f "$CONFIG_DIR/gpu-presets.conf"
    rm -f "$CONFIG_DIR/composite-presets.conf"
    
    success "Configuration files removed"
}

# Remove aliases
remove_aliases() {
    if [ "$REMOVE_ALIASES" != "true" ]; then
        info "Keeping aliases"
        return 0
    fi
    
    log "Removing aliases..."
    
    # Remove aliases file
    rm -f "$CONFIG_DIR/power-manager-aliases.sh"
    
    # Remove from bashrc
    if [ -f "$HOME/.bashrc" ]; then
        # Remove power-manager-aliases.sh source
        sed -i '/power-manager-aliases.sh/d' "$HOME/.bashrc"
        
        # Remove Power Manager Aliases section
        sed -i '/# Power Manager Aliases/,/^fi$/d' "$HOME/.bashrc"
    fi
    
    # Remove from bash_aliases if exists
    if [ -f "$HOME/.bash_aliases" ]; then
        # Remove power manager aliases
        sed -i '/alias pc=/d' "$HOME/.bash_aliases"
        sed -i '/alias pcm=/d' "$HOME/.bash_aliases"
        sed -i '/alias dm=/d' "$HOME/.bash_aliases"
        sed -i '/alias wifi-opt=/d' "$HOME/.bash_aliases"
        sed -i '/alias pc-status=/d' "$HOME/.bash_aliases"
        sed -i '/alias pc-list=/d' "$HOME/.bash_aliases"
        sed -i '/alias pc-gpu=/d' "$HOME/.bash_aliases"
        sed -i '/alias pc-composite=/d' "$HOME/.bash_aliases"
        sed -i '/alias pc-monitor=/d' "$HOME/.bash_aliases"
        sed -i '/alias dm-status=/d' "$HOME/.bash_aliases"
        sed -i '/alias dm-monitor=/d' "$HOME/.bash_aliases"
        sed -i '/alias dm-suspend=/d' "$HOME/.bash_aliases"
        sed -i '/alias dm-wake=/d' "$HOME/.bash_aliases"
        sed -i '/alias wifi-status=/d' "$HOME/.bash_aliases"
        sed -i '/alias wifi-optimize=/d' "$HOME/.bash_aliases"
        sed -i '/alias wifi-test=/d' "$HOME/.bash_aliases"
    fi
    
    success "Aliases removed"
}

# Remove desktop shortcuts
remove_desktop_shortcuts() {
    if [ "$REMOVE_DESKTOP_SHORTCUTS" != "true" ]; then
        info "Keeping desktop shortcuts"
        return 0
    fi
    
    log "Removing desktop shortcuts..."
    
    # Remove desktop shortcuts
    rm -f "$HOME/.local/share/applications/power-control.desktop"
    rm -f "$HOME/.local/share/applications/disk-manager.desktop"
    rm -f "$HOME/.local/share/applications/wifi-optimizer.desktop"
    
    # Update desktop database
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    
    success "Desktop shortcuts removed"
}

# Remove man pages
remove_man_pages() {
    if [ "$REMOVE_MAN_PAGES" != "true" ]; then
        info "Keeping man pages"
        return 0
    fi
    
    log "Removing man pages..."
    
    # Remove man pages
    sudo rm -f "/usr/local/share/man/man1/power-control.1"
    sudo rm -f "/usr/local/share/man/man1/disk-manager.1"
    
    # Update man database
    sudo mandb 2>/dev/null || true
    
    success "Man pages removed"
}

# Remove shell completion
remove_shell_completion() {
    if [ "$REMOVE_SHELL_COMPLETION" != "true" ]; then
        info "Keeping shell completion"
        return 0
    fi
    
    log "Removing shell completion..."
    
    # Remove completion files
    rm -f "$HOME/.local/share/bash-completion/completions/power-control"
    rm -f "$HOME/.local/share/bash-completion/completions/disk-manager"
    
    # Remove from bashrc
    if [ -f "$HOME/.bashrc" ]; then
        # Remove bash completion section
        sed -i '/# Bash completion/,/^fi$/d' "$HOME/.bashrc"
    fi
    
    success "Shell completion removed"
}

# Disable TLP
disable_tlp() {
    if [ "$DISABLE_TLP" != "true" ]; then
        info "Keeping TLP enabled"
        return 0
    fi
    
    log "Disabling TLP..."
    
    # Stop and disable TLP
    sudo systemctl stop tlp 2>/dev/null || true
    sudo systemctl disable tlp 2>/dev/null || true
    
    # Unmask power-profiles-daemon
    sudo systemctl unmask power-profiles-daemon 2>/dev/null || true
    
    success "TLP disabled"
}

# Remove temporary files
remove_temp_files() {
    log "Removing temporary files..."
    
    # Remove temporary files
    rm -f "/tmp/disk-activity.log"
    rm -f "/tmp/power-control.log"
    rm -f "/tmp/wifi-optimizer.log"
    rm -f "/tmp/disk-manager-whitelist"
    
    # Remove log directories
    rm -rf "$HOME/.local/share/power-manager"
    rm -rf "$HOME/.local/share/disk-manager"
    
    success "Temporary files removed"
}

# Check for remaining files
check_remaining() {
    log "Checking for remaining files..."
    
    local remaining=false
    
    # Check for remaining scripts
    if [ -f "$INSTALL_PREFIX/power-control-modular.sh" ] || \
       [ -f "$INSTALL_PREFIX/disk-manager.sh" ] || \
       [ -f "$INSTALL_PREFIX/wifi-intel-optimizer.sh" ]; then
        warning "Some scripts may still exist"
        remaining=true
    fi
    
    # Check for remaining libraries
    if [ -d "$LIB_PREFIX" ]; then
        warning "Library directory still exists: $LIB_PREFIX"
        remaining=true
    fi
    
    # Check for remaining services
    if [ -f "$SERVICE_DIR/power-control-startup.service" ] || \
       [ -f "$SERVICE_DIR/disk-monitor.service" ]; then
        warning "Some service files may still exist"
        remaining=true
    fi
    
    # Check for remaining configs
    if [ "$REMOVE_CONFIGS" = "true" ]; then
        if [ -f "$CONFIG_DIR/power-control.conf" ] || \
           [ -f "$CONFIG_DIR/disk-manager.conf" ]; then
            warning "Some config files may still exist"
            remaining=true
        fi
    fi
    
    if [ "$remaining" = "false" ]; then
        success "No remaining files found"
    else
        warning "Some files may still exist. Check manually if needed."
    fi
}

# Test uninstallation
test_uninstallation() {
    log "Testing uninstallation..."
    
    # Test if commands are gone
    if command -v power-control >/dev/null 2>&1; then
        warning "power-control command still available"
    else
        success "power-control command removed"
    fi
    
    if command -v disk-manager >/dev/null 2>&1; then
        warning "disk-manager command still available"
    else
        success "disk-manager command removed"
    fi
    
    if command -v wifi-intel-optimizer >/dev/null 2>&1; then
        warning "wifi-intel-optimizer command still available"
    else
        success "wifi-intel-optimizer command removed"
    fi
    
    # Test if services are gone
    if systemctl is-active power-control-startup.service >/dev/null 2>&1; then
        warning "Some services may still be running"
    else
        success "Services stopped"
    fi
    
    success "Uninstallation test completed"
}

# Main uninstallation function
main() {
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    🗑️  LINUX POWER MANAGER v2.0.0                      ║${NC}"
    echo -e "${RED}║                    Comprehensive Modular Uninstaller                    ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_root
    confirm_uninstall
    
    log "Starting comprehensive uninstallation..."
    
    stop_services
    remove_services
    remove_scripts
    remove_libraries
    remove_presets
    remove_configs
    remove_aliases
    remove_desktop_shortcuts
    remove_man_pages
    remove_shell_completion
    disable_tlp
    remove_temp_files
    check_remaining
    test_uninstallation
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        🎉 UNINSTALLATION COMPLETE!                       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}The Linux Power Manager modular system has been removed.${NC}"
    echo ""
    echo -e "${YELLOW}Note:${NC}"
    echo -e "  • Configuration files were ${REMOVE_CONFIGS:+removed}${REMOVE_CONFIGS:-kept}"
    echo -e "  • Aliases were ${REMOVE_ALIASES:+removed}${REMOVE_ALIASES:-kept}"
    echo -e "  • Desktop shortcuts were ${REMOVE_DESKTOP_SHORTCUTS:+removed}${REMOVE_DESKTOP_SHORTCUTS:-kept}"
    echo -e "  • Man pages were ${REMOVE_MAN_PAGES:+removed}${REMOVE_MAN_PAGES:-kept}"
    echo -e "  • Shell completion was ${REMOVE_SHELL_COMPLETION:+removed}${REMOVE_SHELL_COMPLETION:-kept}"
    echo -e "  • TLP was ${DISABLE_TLP:+disabled}${DISABLE_TLP:-kept enabled}"
    echo ""
    echo -e "${CYAN}If you want to reinstall, run:${NC}"
    echo -e "  ${YELLOW}./install-modular-comprehensive.sh${NC}"
    echo ""
    echo -e "${GREEN}Uninstallation completed successfully! 🗑️${NC}"
}

# Show help
show_help() {
    echo "Linux Power Manager - Comprehensive Modular Uninstaller"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --remove-configs          Remove configuration files"
    echo "  --keep-aliases            Keep aliases (default: remove)"
    echo "  --keep-shortcuts          Keep desktop shortcuts (default: remove)"
    echo "  --keep-man-pages          Keep man pages (default: remove)"
    echo "  --keep-completion         Keep shell completion (default: remove)"
    echo "  --keep-services           Keep services running (default: stop)"
    echo "  --disable-tlp              Disable TLP (default: keep enabled)"
    echo "  --help                    Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                        # Standard uninstallation"
    echo "  $0 --remove-configs       # Remove everything including configs"
    echo "  $0 --keep-aliases          # Keep aliases, remove everything else"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --remove-configs)
            REMOVE_CONFIGS=true
            shift
            ;;
        --keep-aliases)
            REMOVE_ALIASES=false
            shift
            ;;
        --keep-shortcuts)
            REMOVE_DESKTOP_SHORTCUTS=false
            shift
            ;;
        --keep-man-pages)
            REMOVE_MAN_PAGES=false
            shift
            ;;
        --keep-completion)
            REMOVE_SHELL_COMPLETION=false
            shift
            ;;
        --keep-services)
            STOP_SERVICES=false
            shift
            ;;
        --disable-tlp)
            DISABLE_TLP=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
