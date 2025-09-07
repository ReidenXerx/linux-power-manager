#!/bin/bash

# Linux Power Manager - Comprehensive Modular Installer
# Installs the complete modular power management system with all components
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

# Script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="/usr/local/bin"
LIB_PREFIX="/usr/local/share/power-manager"
CONFIG_DIR="$HOME/.config"
SERVICE_DIR="/etc/systemd/system"
PRESETS_DIR="/usr/local/share/power-manager/presets"

# Installation settings
INSTALL_SERVICES=true
INSTALL_TLP=true
INSTALL_DEPENDENCIES=true
INSTALL_ALIASES=true
INSTALL_DESKTOP_SHORTCUTS=true
INSTALL_MAN_PAGES=true
INSTALL_SHELL_COMPLETION=true
ENABLE_GPU_SWITCHING=true
ENABLE_INTEL_OPTIMIZATIONS=true

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

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    else
        error "Cannot detect Linux distribution"
        exit 1
    fi
    
    info "Detected distribution: $DISTRO $DISTRO_VERSION"
}

# Install dependencies
install_dependencies() {
    if [ "$INSTALL_DEPENDENCIES" != "true" ]; then
        info "Skipping dependency installation"
        return 0
    fi
    
    log "Installing dependencies for $DISTRO..."
    
    case $DISTRO in
        ubuntu|debian|pop|elementary)
            sudo apt update
            sudo apt install -y \
                tlp tlp-rdw \
                smartmontools \
                hdparm \
                lsof \
                curl \
                wget \
                jq \
                systemd \
                bash-completion
            ;;
        fedora|rhel|centos|rocky|alma)
            sudo dnf install -y \
                tlp tlp-rdw \
                smartmontools \
                hdparm \
                lsof \
                curl \
                wget \
                jq \
                systemd \
                bash-completion
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm \
                tlp \
                smartmontools \
                hdparm \
                lsof \
                curl \
                wget \
                jq \
                systemd \
                bash-completion
            ;;
        opensuse*|sles)
            sudo zypper install -y \
                tlp \
                smartmontools \
                hdparm \
                lsof \
                curl \
                wget \
                jq \
                systemd \
                bash-completion
            ;;
        alpine)
            sudo apk add \
                tlp \
                smartmontools \
                hdparm \
                lsof \
                curl \
                wget \
                jq \
                bash-completion
            ;;
        *)
            warning "Unsupported distribution: $DISTRO"
            warning "Please install dependencies manually: tlp, smartmontools, hdparm, lsof"
            ;;
    esac
    
    success "Dependencies installed successfully"
}

# Install GPU switching tools
install_gpu_tools() {
    if [ "$ENABLE_GPU_SWITCHING" != "true" ]; then
        info "Skipping GPU switching tools installation"
        return 0
    fi
    
    log "Installing GPU switching tools..."
    
    # Install envycontrol
    if ! command -v envycontrol >/dev/null 2>&1; then
        log "Installing envycontrol..."
        case $DISTRO in
            ubuntu|debian|pop|elementary)
                sudo apt install -y python3-pip
                pip3 install --user envycontrol
                ;;
            fedora|rhel|centos|rocky|alma)
                sudo dnf install -y python3-pip
                pip3 install --user envycontrol
                ;;
            arch|manjaro)
                sudo pacman -S --noconfirm python-pip
                pip install --user envycontrol
                ;;
            *)
                warning "Please install envycontrol manually: pip install envycontrol"
                ;;
        esac
    fi
    
    # Install supergfxctl
    if ! command -v supergfxctl >/dev/null 2>&1; then
        log "Installing supergfxctl..."
        case $DISTRO in
            ubuntu|debian|pop|elementary)
                sudo apt install -y supergfxctl
                ;;
            fedora|rhel|centos|rocky|alma)
                sudo dnf install -y supergfxctl
                ;;
            arch|manjaro)
                sudo pacman -S --noconfirm supergfxctl
                ;;
            *)
                warning "Please install supergfxctl manually"
                ;;
        esac
    fi
    
    success "GPU switching tools installed successfully"
}

# Create directory structure
create_directories() {
    log "Creating directory structure..."
    
    sudo mkdir -p "$LIB_PREFIX/lib"
    sudo mkdir -p "$LIB_PREFIX/presets/system-presets"
    sudo mkdir -p "$LIB_PREFIX/presets/gpu-presets"
    sudo mkdir -p "$LIB_PREFIX/presets/composite-presets"
    sudo mkdir -p "$CONFIG_DIR"
    
    success "Directory structure created"
}

# Install main scripts
install_scripts() {
    log "Installing main scripts..."
    
    # Install power-control-modular.sh
    sudo cp "$SCRIPT_DIR/scripts/power-control-modular.sh" "$INSTALL_PREFIX/"
    sudo chmod +x "$INSTALL_PREFIX/power-control-modular.sh"
    
    # Create symlink for easy access
    sudo ln -sf "$INSTALL_PREFIX/power-control-modular.sh" "$INSTALL_PREFIX/power-control"
    
    # Install disk-manager.sh
    sudo cp "$SCRIPT_DIR/scripts/disk-manager.sh" "$INSTALL_PREFIX/"
    sudo chmod +x "$INSTALL_PREFIX/disk-manager.sh"
    
    # Install wifi-intel-optimizer.sh
    sudo cp "$SCRIPT_DIR/scripts/wifi-intel-optimizer.sh" "$INSTALL_PREFIX/"
    sudo chmod +x "$INSTALL_PREFIX/wifi-intel-optimizer.sh"
    
    success "Main scripts installed"
}

# Install libraries
install_libraries() {
    log "Installing libraries..."
    
    # Install all library files
    sudo cp "$SCRIPT_DIR/lib/"*.sh "$LIB_PREFIX/lib/"
    sudo chmod +x "$LIB_PREFIX/lib/"*.sh
    
    success "Libraries installed"
}

# Install presets
install_presets() {
    log "Installing presets..."
    
    # Install system presets
    if [ -d "$SCRIPT_DIR/presets/system-presets" ]; then
        sudo cp "$SCRIPT_DIR/presets/system-presets/"*.conf "$LIB_PREFIX/presets/system-presets/"
    fi
    
    # Install GPU presets
    if [ -d "$SCRIPT_DIR/presets/gpu-presets" ]; then
        sudo cp "$SCRIPT_DIR/presets/gpu-presets/"*.conf "$LIB_PREFIX/presets/gpu-presets/"
    fi
    
    # Install composite presets
    if [ -d "$SCRIPT_DIR/presets/composite-presets" ]; then
        sudo cp "$SCRIPT_DIR/presets/composite-presets/"*.conf "$LIB_PREFIX/presets/composite-presets/"
    fi
    
    success "Presets installed"
}

# Install systemd services
install_services() {
    if [ "$INSTALL_SERVICES" != "true" ]; then
        info "Skipping systemd services installation"
        return 0
    fi
    
    log "Installing systemd services..."
    
    # Install all service files
    sudo cp "$SCRIPT_DIR/services/"*.service "$SERVICE_DIR/"
    sudo cp "$SCRIPT_DIR/services/"*.timer "$SERVICE_DIR/"
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    # Enable services
    sudo systemctl enable power-control-startup.service
    sudo systemctl enable power-control-wake.service
    sudo systemctl enable power-control-monitor.service
    sudo systemctl enable power-control-monitor.timer
    sudo systemctl enable disk-monitor.service
    sudo systemctl enable disk-monitor.timer
    sudo systemctl enable wifi-power-monitor.service
    sudo systemctl enable wifi-power-monitor.timer
    sudo systemctl enable wifi-power-optimizer.service
    
    # Start services
    sudo systemctl start power-control-startup.service
    sudo systemctl start power-control-monitor.timer
    sudo systemctl start disk-monitor.timer
    sudo systemctl start wifi-power-monitor.timer
    sudo systemctl start wifi-power-optimizer.service
    
    success "Systemd services installed and enabled"
}

# Configure TLP
configure_tlp() {
    if [ "$INSTALL_TLP" != "true" ]; then
        info "Skipping TLP configuration"
        return 0
    fi
    
    log "Configuring TLP..."
    
    # Enable TLP
    sudo systemctl enable tlp
    sudo systemctl start tlp
    
    # Mask power-profiles-daemon to prevent conflicts
    sudo systemctl mask power-profiles-daemon 2>/dev/null || true
    
    success "TLP configured and enabled"
}

# Install aliases and shortcuts
install_aliases() {
    if [ "$INSTALL_ALIASES" != "true" ]; then
        info "Skipping aliases installation"
        return 0
    fi
    
    log "Installing aliases and shortcuts..."
    
    # Create aliases file
    cat > "$CONFIG_DIR/power-manager-aliases.sh" << 'EOF'
# Power Manager Aliases
alias pc='power-control'
alias pcm='power-control-modular'
alias dm='disk-manager'
alias wifi-opt='wifi-intel-optimizer'

# Power control shortcuts
alias pc-status='power-control status'
alias pc-list='power-control list-system-presets'
alias pc-gpu='power-control list-gpu-presets'
alias pc-composite='power-control list-composite-presets'
alias pc-monitor='power-control monitor'

# Disk management shortcuts
alias dm-status='disk-manager status'
alias dm-monitor='disk-manager monitor'
alias dm-suspend='disk-manager suspend'
alias dm-wake='disk-manager wake'

# WiFi optimization shortcuts
alias wifi-status='wifi-intel-optimizer status'
alias wifi-optimize='wifi-intel-optimizer optimize'
alias wifi-test='wifi-intel-optimizer test'
EOF
    
    # Add to bashrc if not already present
    if ! grep -q "power-manager-aliases.sh" "$HOME/.bashrc"; then
        echo "" >> "$HOME/.bashrc"
        echo "# Power Manager Aliases" >> "$HOME/.bashrc"
        echo "if [ -f ~/.config/power-manager-aliases.sh ]; then" >> "$HOME/.bashrc"
        echo "    source ~/.config/power-manager-aliases.sh" >> "$HOME/.bashrc"
        echo "fi" >> "$HOME/.bashrc"
    fi
    
    success "Aliases installed"
}

# Install desktop shortcuts
install_desktop_shortcuts() {
    if [ "$INSTALL_DESKTOP_SHORTCUTS" != "true" ]; then
        info "Skipping desktop shortcuts installation"
        return 0
    fi
    
    log "Installing desktop shortcuts..."
    
    # Create desktop directory
    mkdir -p "$HOME/.local/share/applications"
    
    # Power Control shortcut
    cat > "$HOME/.local/share/applications/power-control.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Power Control
Comment=Linux Power Manager - Modular System
Exec=gnome-terminal -- bash -c "power-control status; exec bash"
Icon=preferences-system-power
Terminal=false
Categories=System;Settings;
EOF
    
    # Disk Manager shortcut
    cat > "$HOME/.local/share/applications/disk-manager.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Disk Manager
Comment=Disk Power Management
Exec=gnome-terminal -- bash -c "disk-manager status; exec bash"
Icon=drive-harddisk
Terminal=false
Categories=System;Settings;
EOF
    
    # WiFi Optimizer shortcut
    cat > "$HOME/.local/share/applications/wifi-optimizer.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=WiFi Optimizer
Comment=Intel WiFi Power Optimization
Exec=gnome-terminal -- bash -c "wifi-intel-optimizer status; exec bash"
Icon=network-wireless
Terminal=false
Categories=System;Settings;
EOF
    
    # Update desktop database
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    
    success "Desktop shortcuts installed"
}

# Install man pages
install_man_pages() {
    if [ "$INSTALL_MAN_PAGES" != "true" ]; then
        info "Skipping man pages installation"
        return 0
    fi
    
    log "Installing man pages..."
    
    # Create man directory
    sudo mkdir -p "/usr/local/share/man/man1"
    
    # Power Control man page
    sudo tee "/usr/local/share/man/man1/power-control.1" > /dev/null << 'EOF'
.TH POWER-CONTROL 1 "2024-01-01" "Linux Power Manager" "User Commands"
.SH NAME
power-control \- Modular Linux Power Management System
.SH SYNOPSIS
.B power-control
[\fIcommand\fR] [\fIoptions\fR]
.SH DESCRIPTION
Power Control is a comprehensive modular power management system for Linux.
It provides system-wide power presets, GPU switching, disk management, and WiFi optimization.
.SH COMMANDS
.TP
.B status
Show current system status and power settings
.TP
.B list-system-presets
List available system power presets
.TP
.B list-gpu-presets
List available GPU switching presets
.TP
.B list-composite-presets
List available composite presets
.TP
.B apply-system-preset <preset>
Apply a system power preset
.TP
.B apply-gpu-preset <preset>
Apply a GPU switching preset
.TP
.B apply-composite-preset <preset>
Apply a composite preset
.TP
.B monitor
Run comprehensive system monitoring
.SH EXAMPLES
.TP
.B power-control status
Show current system status
.TP
.B power-control apply-system-preset balanced
Apply balanced power preset
.TP
.B power-control apply-gpu-preset hybrid
Switch to hybrid GPU mode
.SH FILES
.TP
.B ~/.config/power-control.conf
User configuration file
.TP
.B /usr/local/share/power-manager/presets/
System preset files
.SH SEE ALSO
.BR disk-manager (1),
.BR wifi-intel-optimizer (1)
.SH AUTHOR
Linux Power Manager Project
EOF
    
    # Disk Manager man page
    sudo tee "/usr/local/share/man/man1/disk-manager.1" > /dev/null << 'EOF'
.TH DISK-MANAGER 1 "2024-01-01" "Linux Power Manager" "User Commands"
.SH NAME
disk-manager \- Disk Power Management System
.SH SYNOPSIS
.B disk-manager
[\fIcommand\fR] [\fIdisk\fR]
.SH DESCRIPTION
Disk Manager provides automatic and manual disk suspension with comprehensive safety checks.
It prevents data loss by checking for mounted filesystems, active processes, and LVM usage.
.SH COMMANDS
.TP
.B status
Show disk management status
.TP
.B monitor
Suspend all safe disks
.TP
.B suspend <disk>
Manually suspend a disk with safety checks
.TP
.B force-suspend <disk>
Force suspend a disk (OVERRIDE SAFETY - RISKY)
.TP
.B auto-suspend <disk>
Automatic suspend (NO OVERRIDE - SAFEST)
.TP
.B wake <disk>
Wake up a suspended disk
.TP
.B optimize <disk>
Apply Intel SSD optimizations
.TP
.B health <disk>
Check disk health using SMART
.SH SAFETY CHECKS
Automatic suspension is blocked if ANY of these are true:
.TP
.B Disk is mounted or has mounted partitions
.TP
.B Disk has active processes
.TP
.B Disk is used by LVM
.TP
.B Disk is system disk (if EXCLUDE_SYSTEM_DISK=true)
.TP
.B Disk health issues (if SMART_MONITORING=true)
.SH EXAMPLES
.TP
.B disk-manager status
Show current disk status
.TP
.B disk-manager suspend nvme0n1
Suspend secondary NVMe drive
.TP
.B disk-manager monitor
Suspend all safe disks
.SH FILES
.TP
.B ~/.config/disk-manager.conf
Configuration file
.SH SEE ALSO
.BR power-control (1),
.BR wifi-intel-optimizer (1)
.SH AUTHOR
Linux Power Manager Project
EOF
    
    # Update man database
    sudo mandb 2>/dev/null || true
    
    success "Man pages installed"
}

# Install shell completion
install_shell_completion() {
    if [ "$INSTALL_SHELL_COMPLETION" != "true" ]; then
        info "Skipping shell completion installation"
        return 0
    fi
    
    log "Installing shell completion..."
    
    # Create completion directory
    mkdir -p "$HOME/.local/share/bash-completion/completions"
    
    # Power Control completion
    cat > "$HOME/.local/share/bash-completion/completions/power-control" << 'EOF'
_power-control() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    opts="status list-system-presets list-gpu-presets list-composite-presets apply-system-preset apply-gpu-preset apply-composite-preset monitor wifi-optimize wifi-status wifi-test disk-status disk-suspend disk-wake disk-monitor disk-config health-check metrics"
    
    case "${prev}" in
        apply-system-preset)
            local presets="balanced gaming-max ultra-eco intel-arc-optimized intel-hybrid-performance intel-arc-creative intel-eco"
            COMPREPLY=( $(compgen -W "${presets}" -- ${cur}) )
            return 0
            ;;
        apply-gpu-preset)
            local presets="integrated hybrid nvidia"
            COMPREPLY=( $(compgen -W "${presets}" -- ${cur}) )
            return 0
            ;;
        apply-composite-preset)
            local presets="balanced gaming eco work creative"
            COMPREPLY=( $(compgen -W "${presets}" -- ${cur}) )
            return 0
            ;;
    esac
    
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}
complete -F _power-control power-control
complete -F _power-control power-control-modular
complete -F _power-control pcm
complete -F _power-control pc
EOF
    
    # Disk Manager completion
    cat > "$HOME/.local/share/bash-completion/completions/disk-manager" << 'EOF'
_disk-manager() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    opts="status monitor suspend force-suspend auto-suspend wake optimize health"
    
    case "${prev}" in
        suspend|force-suspend|auto-suspend|wake|optimize|health)
            local disks=$(lsblk -nd -o NAME,TYPE | awk '$2=="disk" {print $1}')
            COMPREPLY=( $(compgen -W "${disks}" -- ${cur}) )
            return 0
            ;;
    esac
    
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}
complete -F _disk-manager disk-manager
complete -F _disk-manager dm
EOF
    
    # Source completion in bashrc
    if ! grep -q "bash-completion/completions" "$HOME/.bashrc"; then
        echo "" >> "$HOME/.bashrc"
        echo "# Bash completion" >> "$HOME/.bashrc"
        echo "if [ -d ~/.local/share/bash-completion/completions ]; then" >> "$HOME/.bashrc"
        echo "    for f in ~/.local/share/bash-completion/completions/*; do" >> "$HOME/.bashrc"
        echo "        [ -f \"\$f\" ] && source \"\$f\"" >> "$HOME/.bashrc"
        echo "    done" >> "$HOME/.bashrc"
        echo "fi" >> "$HOME/.bashrc"
    fi
    
    success "Shell completion installed"
}

# Fix script paths
fix_script_paths() {
    log "Fixing script paths..."
    
    # Fix power-control-modular.sh paths
    sudo sed -i "s|LIB_DIR=\"\$SCRIPT_DIR/../lib\"|LIB_DIR=\"$LIB_PREFIX/lib\"|g" "$INSTALL_PREFIX/power-control-modular.sh"
    sudo sed -i "s|PRESETS_DIR=\"\$SCRIPT_DIR/../presets\"|PRESETS_DIR=\"$LIB_PREFIX/presets\"|g" "$INSTALL_PREFIX/power-control-modular.sh"
    
    # Fix modular-power-system.sh paths
    sudo sed -i "s|SYSTEM_PRESETS_DIR=\"\$SCRIPT_DIR/../presets/system-presets\"|SYSTEM_PRESETS_DIR=\"$LIB_PREFIX/presets/system-presets\"|g" "$LIB_PREFIX/lib/modular-power-system.sh"
    sudo sed -i "s|GPU_PRESETS_DIR=\"\$SCRIPT_DIR/../presets/gpu-presets\"|GPU_PRESETS_DIR=\"$LIB_PREFIX/presets/gpu-presets\"|g" "$LIB_PREFIX/lib/modular-power-system.sh"
    sudo sed -i "s|COMPOSITE_PRESETS_DIR=\"\$SCRIPT_DIR/../presets/composite-presets\"|COMPOSITE_PRESETS_DIR=\"$LIB_PREFIX/presets/composite-presets\"|g" "$LIB_PREFIX/lib/modular-power-system.sh"
    
    success "Script paths fixed"
}

# Create configuration files
create_configurations() {
    log "Creating configuration files..."
    
    # Create power-control.conf if it doesn't exist
    if [ ! -f "$CONFIG_DIR/power-control.conf" ]; then
        cat > "$CONFIG_DIR/power-control.conf" << 'EOF'
# Power Control Configuration
# Modular Power Management System

# System Settings
DEFAULT_SYSTEM_PRESET="balanced"
DEFAULT_GPU_PRESET="hybrid"
AUTO_APPLY_PRESETS=true

# Intel Optimizations
ENABLE_INTEL_OPTIMIZATIONS=true
INTEL_ARC_OPTIMIZATION=true
INTEL_HYBRID_CPU_OPTIMIZATION=true

# Monitoring
ENABLE_MONITORING=true
MONITORING_INTERVAL=300

# Logging
LOG_LEVEL="INFO"
LOG_FILE="$HOME/.local/share/power-manager/power-control.log"
EOF
    fi
    
    # Create disk-manager.conf if it doesn't exist
    if [ ! -f "$CONFIG_DIR/disk-manager.conf" ]; then
        cat > "$CONFIG_DIR/disk-manager.conf" << 'EOF'
# Disk Manager Configuration
# Simple Disk Power Management

# Core Settings
DISK_MANAGEMENT_ENABLED=true
AUTO_SUSPEND_ENABLED=true
SUSPEND_ON_BATTERY_ONLY=false
EXCLUDE_SYSTEM_DISK=true
MONITORED_DISKS="auto"

# Intel Optimizations
INTEL_SSD_OPTIMIZATION=true
SMART_MONITORING=true
HEALTH_THRESHOLD=80

# Power Management
NVME_POWER_MANAGEMENT=true
ENABLE_DEEP_SLEEP=false
ADAPTIVE_TIMEOUT=true
EOF
    fi
    
    success "Configuration files created"
}

# Test installation
test_installation() {
    log "Testing installation..."
    
    # Test power-control
    if "$INSTALL_PREFIX/power-control" status >/dev/null 2>&1; then
        success "Power Control: OK"
    else
        error "Power Control: FAILED"
    fi
    
    # Test disk-manager
    if "$INSTALL_PREFIX/disk-manager" status >/dev/null 2>&1; then
        success "Disk Manager: OK"
    else
        error "Disk Manager: FAILED"
    fi
    
    # Test wifi-optimizer
    if "$INSTALL_PREFIX/wifi-intel-optimizer" status >/dev/null 2>&1; then
        success "WiFi Optimizer: OK"
    else
        error "WiFi Optimizer: FAILED"
    fi
    
    # Test services
    if systemctl is-active power-control-startup.service >/dev/null 2>&1; then
        success "Power Control Services: OK"
    else
        warning "Power Control Services: Some services may not be running"
    fi
    
    success "Installation test completed"
}

# Main installation function
main() {
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    🚀 LINUX POWER MANAGER v2.0.0                          ║${NC}"
    echo -e "${PURPLE}║                    Comprehensive Modular Installer                        ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_root
    detect_distro
    
    log "Starting comprehensive installation..."
    
    install_dependencies
    install_gpu_tools
    create_directories
    install_scripts
    install_libraries
    install_presets
    install_services
    configure_tlp
    install_aliases
    install_desktop_shortcuts
    install_man_pages
    install_shell_completion
    fix_script_paths
    create_configurations
    test_installation
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        🎉 INSTALLATION COMPLETE!                        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Available commands:${NC}"
    echo -e "  ${YELLOW}power-control${NC}     - Main power management system"
    echo -e "  ${YELLOW}disk-manager${NC}       - Disk power management"
    echo -e "  ${YELLOW}wifi-intel-optimizer${NC} - WiFi power optimization"
    echo ""
    echo -e "${CYAN}Quick start:${NC}"
    echo -e "  ${YELLOW}power-control status${NC}     - Show system status"
    echo -e "  ${YELLOW}power-control list-system-presets${NC} - List power presets"
    echo -e "  ${YELLOW}disk-manager status${NC}      - Show disk status"
    echo ""
    echo -e "${CYAN}Configuration:${NC}"
    echo -e "  ${YELLOW}~/.config/power-control.conf${NC} - Power control settings"
    echo -e "  ${YELLOW}~/.config/disk-manager.conf${NC}   - Disk management settings"
    echo ""
    echo -e "${CYAN}Services:${NC}"
    echo -e "  ${YELLOW}systemctl status power-control-*${NC} - Check service status"
    echo ""
    echo -e "${GREEN}Installation completed successfully! 🚀${NC}"
}

# Run main function
main "$@"
