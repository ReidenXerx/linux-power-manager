#!/bin/bash

# Linux Power Manager - Universal Installer
# Supports multiple Linux distributions with automatic detection
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="/usr/local/bin"
CONFIG_DIR="$HOME/.config"
SERVICE_DIR="/etc/systemd/system"

# Installation settings
INSTALL_SERVICES=true
INSTALL_TLP=true
INSTALL_ENVYCONTROL=false
ENABLE_GPU_SWITCHING=false

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
        DISTRO_NAME=$PRETTY_NAME
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
        DISTRO_NAME=$(cat /etc/redhat-release)
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        DISTRO_NAME="Debian $(cat /etc/debian_version)"
    else
        DISTRO="unknown"
        DISTRO_NAME="Unknown Linux"
    fi
    
    log "Detected: $DISTRO_NAME"
}

# Get package manager for the distribution
get_package_manager() {
    case "$DISTRO" in
        "ubuntu"|"debian"|"pop"|"mint"|"elementary")
            PKG_MANAGER="apt"
            PKG_INSTALL="sudo apt update && sudo apt install -y"
            PKG_CHECK="dpkg -l | grep -q"
            ;;
        "fedora"|"rhel"|"centos"|"rocky"|"almalinux")
            PKG_MANAGER="dnf"
            PKG_INSTALL="sudo dnf install -y"
            PKG_CHECK="rpm -q"
            ;;
        "opensuse"|"opensuse-leap"|"opensuse-tumbleweed")
            PKG_MANAGER="zypper"
            PKG_INSTALL="sudo zypper install -y"
            PKG_CHECK="rpm -q"
            ;;
        "arch"|"manjaro"|"endeavouros")
            PKG_MANAGER="pacman"
            PKG_INSTALL="sudo pacman -S --noconfirm"
            PKG_CHECK="pacman -Q"
            ;;
        "alpine")
            PKG_MANAGER="apk"
            PKG_INSTALL="sudo apk add"
            PKG_CHECK="apk info | grep -q"
            ;;
        *)
            error "Unsupported distribution: $DISTRO"
            echo "Supported distributions: Ubuntu, Debian, Fedora, openSUSE, Arch Linux, Alpine"
            exit 1
            ;;
    esac
    
    info "Using package manager: $PKG_MANAGER"
}

# Install required packages
install_dependencies() {
    log "Installing dependencies..."
    
    case "$DISTRO" in
        "ubuntu"|"debian"|"pop"|"mint"|"elementary")
            DEPS="bc acpi lm-sensors curl wget git"
            if [ "$INSTALL_TLP" = true ]; then
                DEPS="$DEPS tlp tlp-rdw"
            fi
            ;;
        "fedora"|"rhel"|"centos"|"rocky"|"almalinux")
            DEPS="bc acpi lm_sensors curl wget git"
            if [ "$INSTALL_TLP" = true ]; then
                DEPS="$DEPS tlp tlp-rdw"
            fi
            ;;
        "opensuse"|"opensuse-leap"|"opensuse-tumbleweed")
            DEPS="bc acpi sensors curl wget git"
            if [ "$INSTALL_TLP" = true ]; then
                DEPS="$DEPS tlp tlp-rdw"
            fi
            ;;
        "arch"|"manjaro"|"endeavouros")
            DEPS="bc acpi lm_sensors curl wget git"
            if [ "$INSTALL_TLP" = true ]; then
                DEPS="$DEPS tlp tlp-rdw"
            fi
            ;;
        "alpine")
            DEPS="bc acpi lm-sensors curl wget git"
            ;;
    esac
    
    eval "$PKG_INSTALL $DEPS"
    success "Dependencies installed"
}

# Install envycontrol for GPU switching (optional)
install_envycontrol() {
    if [ "$INSTALL_ENVYCONTROL" = true ]; then
        log "Installing envycontrol for GPU switching..."
        
        if command -v pip3 >/dev/null 2>&1; then
            pip3 install --user envycontrol
            success "envycontrol installed via pip3"
        elif command -v pipx >/dev/null 2>&1; then
            pipx install envycontrol
            success "envycontrol installed via pipx"
        else
            warning "pip3/pipx not found. Installing envycontrol manually..."
            git clone https://github.com/bayasdev/envycontrol.git /tmp/envycontrol
            cd /tmp/envycontrol
            sudo python3 setup.py install
            cd "$SCRIPT_DIR"
            rm -rf /tmp/envycontrol
            success "envycontrol installed manually"
        fi
    fi
}

# Install scripts
install_scripts() {
    log "Installing power management scripts..."
    
    # Copy main scripts
    sudo cp "$SCRIPT_DIR/scripts/power-control.sh" "$INSTALL_PREFIX/"
    sudo cp "$SCRIPT_DIR/scripts/power-status.sh" "$INSTALL_PREFIX/"
    sudo chmod +x "$INSTALL_PREFIX/power-control.sh"
    sudo chmod +x "$INSTALL_PREFIX/power-status.sh"
    
    success "Scripts installed to $INSTALL_PREFIX"
}

# Install configurations
install_configs() {
    log "Installing configuration files..."
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Copy config files
    if [ ! -f "$CONFIG_DIR/power-control.conf" ]; then
        cp "$SCRIPT_DIR/configs/power-control.conf" "$CONFIG_DIR/"
    else
        warning "Config file exists, creating backup..."
        cp "$CONFIG_DIR/power-control.conf" "$CONFIG_DIR/power-control.conf.backup"
        cp "$SCRIPT_DIR/configs/power-control.conf" "$CONFIG_DIR/"
    fi
    
    if [ ! -f "$CONFIG_DIR/power-presets.conf" ]; then
        cp "$SCRIPT_DIR/configs/power-presets.conf" "$CONFIG_DIR/"
    else
        warning "Presets file exists, creating backup..."
        cp "$CONFIG_DIR/power-presets.conf" "$CONFIG_DIR/power-presets.conf.backup"
        cp "$SCRIPT_DIR/configs/power-presets.conf" "$CONFIG_DIR/"
    fi
    
    # Copy power-status config if exists
    if [ -f "$SCRIPT_DIR/configs/power-manager.conf" ]; then
        cp "$SCRIPT_DIR/configs/power-manager.conf" "$CONFIG_DIR/"
    fi
    
    # Set GPU switching preference
    if [ "$ENABLE_GPU_SWITCHING" = true ]; then
        sed -i 's/GPU_SWITCHING_ENABLED=false/GPU_SWITCHING_ENABLED=true/' "$CONFIG_DIR/power-control.conf"
    fi
    
    success "Configuration files installed"
}

# Install systemd services
install_services() {
    if [ "$INSTALL_SERVICES" = true ]; then
        log "Installing systemd services..."
        
        sudo cp "$SCRIPT_DIR/services/"*.service "$SERVICE_DIR/"
        sudo cp "$SCRIPT_DIR/services/"*.timer "$SERVICE_DIR/"
        
        sudo systemctl daemon-reload
        
        # Enable services
        sudo systemctl enable power-control-startup.service
        sudo systemctl enable power-control-wake.service
        sudo systemctl enable power-control-monitor.timer
        
        success "Systemd services installed and enabled"
    fi
}

# Configure TLP
configure_tlp() {
    if [ "$INSTALL_TLP" = true ]; then
        log "Configuring TLP..."
        
        # Disable conflicting services
        if systemctl is-enabled power-profiles-daemon >/dev/null 2>&1; then
            sudo systemctl mask power-profiles-daemon.service
            info "Masked power-profiles-daemon to avoid conflicts"
        fi
        
        # Enable and start TLP
        sudo systemctl enable tlp.service
        sudo systemctl start tlp.service
        
        success "TLP configured and started"
    fi
}

# Create bash aliases
install_aliases() {
    log "Installing bash aliases..."
    
    ALIAS_FILE="$HOME/.bash_aliases"
    
    # Create aliases file if it doesn't exist
    if [ ! -f "$ALIAS_FILE" ]; then
        touch "$ALIAS_FILE"
    fi
    
    # Check if our aliases already exist
    if ! grep -q "# Linux Power Manager aliases" "$ALIAS_FILE"; then
        cat >> "$ALIAS_FILE" << 'EOF'

# Linux Power Manager aliases
alias power-status='power-status.sh status'
alias power-presets='power-status.sh presets'
alias power-select='power-status.sh select-preset'
alias power-eco='power-control.sh ultra-eco'
alias power-balanced='power-control.sh balanced'
alias power-performance='power-control.sh performance-dgpu'
alias power-gaming='power-control.sh gaming-max'
alias gpu-status='power-control.sh gpu-status'
alias gpu-integrated='power-control.sh gpu-integrated'
alias gpu-hybrid='power-control.sh gpu-hybrid'
alias gpu-nvidia='power-control.sh gpu-nvidia'
EOF
        success "Bash aliases installed"
        info "Run 'source ~/.bashrc' or restart your terminal to use aliases"
    else
        info "Aliases already installed"
    fi
}

# Show usage instructions
show_usage() {
    echo -e "${CYAN}Linux Power Manager - Installation Complete!${NC}"
    echo ""
    echo -e "${YELLOW}Available Commands:${NC}"
    echo "  power-control.sh status       - Show power status"
    echo "  power-control.sh list-presets - List available presets"
    echo "  power-control.sh ultra-eco    - Ultra power saving mode"
    echo "  power-control.sh performance-dgpu - High performance mode"
    echo "  power-status.sh select-preset - Interactive preset selection"
    echo ""
    echo -e "${YELLOW}Aliases (after restart/source):${NC}"
    echo "  power-status      - Show power status"
    echo "  power-presets     - List presets"
    echo "  power-select      - Interactive preset menu"
    echo "  power-eco         - Ultra eco mode"
    echo "  power-performance - High performance mode"
    echo "  gpu-status        - Show GPU status"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  power-control.sh config - Configure settings"
    echo "  Config files: ~/.config/power-*.conf"
    echo ""
    if [ "$INSTALL_TLP" = true ]; then
        echo -e "${GREEN}TLP power management is enabled${NC}"
    fi
    if [ "$INSTALL_ENVYCONTROL" = true ]; then
        echo -e "${GREEN}GPU switching with envycontrol is available${NC}"
    fi
}

# Interactive configuration
interactive_config() {
    echo -e "${CYAN}Linux Power Manager - Interactive Installation${NC}"
    echo ""
    
    read -p "Install TLP for advanced power management? (Y/n): " tlp_choice
    case "$tlp_choice" in
        [Nn]* ) INSTALL_TLP=false ;;
        * ) INSTALL_TLP=true ;;
    esac
    
    read -p "Install envycontrol for GPU switching (NVIDIA laptops)? (y/N): " gpu_choice
    case "$gpu_choice" in
        [Yy]* ) INSTALL_ENVYCONTROL=true ;;
        * ) INSTALL_ENVYCONTROL=false ;;
    esac
    
    if [ "$INSTALL_ENVYCONTROL" = true ]; then
        read -p "Enable GPU switching by default? (y/N): " gpu_enable
        case "$gpu_enable" in
            [Yy]* ) ENABLE_GPU_SWITCHING=true ;;
            * ) ENABLE_GPU_SWITCHING=false ;;
        esac
    fi
    
    read -p "Install systemd services for auto-startup? (Y/n): " service_choice
    case "$service_choice" in
        [Nn]* ) INSTALL_SERVICES=false ;;
        * ) INSTALL_SERVICES=true ;;
    esac
}

# Main installation function
main() {
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║         Linux Power Manager Installer        ║${NC}"
    echo -e "${PURPLE}║            Universal Installation             ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_root
    detect_distro
    get_package_manager
    
    # Check for interactive mode
    if [ "$1" = "--interactive" ] || [ "$1" = "-i" ]; then
        interactive_config
    fi
    
    echo ""
    log "Starting installation..."
    echo ""
    
    install_dependencies
    install_envycontrol
    install_scripts
    install_configs
    install_services
    configure_tlp
    install_aliases
    
    echo ""
    success "Installation completed successfully!"
    echo ""
    show_usage
}

# Handle command line arguments
case "$1" in
    "--help"|"-h")
        echo "Linux Power Manager Installer"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --interactive, -i    Interactive installation"
        echo "  --help, -h          Show this help"
        echo ""
        echo "Environment variables:"
        echo "  INSTALL_TLP=false   Skip TLP installation"
        echo "  INSTALL_ENVYCONTROL=true   Install envycontrol"
        echo "  ENABLE_GPU_SWITCHING=true   Enable GPU switching"
        echo "  INSTALL_SERVICES=false   Skip systemd services"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
