# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Core System Commands

### Installation and Management
```bash
# Install the complete system
./install.sh

# Interactive installation with custom options
./install.sh --interactive

# Uninstall all components
./uninstall.sh

# Test installation (useful during development)
./install.sh && power-control.sh status
```

### Development Testing
```bash
# Test the main power control script directly
./scripts/power-control.sh status

# Test power status script
./scripts/power-status.sh status

# Apply a preset for testing
./scripts/power-control.sh ultra-eco

# List all available presets
./scripts/power-control.sh list-presets

# Test GPU switching (if envycontrol available)
./scripts/power-control.sh gpu-status

# Test disk management
./scripts/disk-manager.sh status
./scripts/power-control.sh disk-status
```

### Systemd Service Testing
```bash
# Check service status
systemctl status power-control-startup.service
systemctl status power-control-wake.service

# View service logs
journalctl -u power-control-startup.service
journalctl -u power-control-monitor.timer

# Test service execution manually
sudo systemctl start power-control-startup.service
```

## Recent Updates (v2.2.1)

### 🔧 **Major Fixes Applied**
- **Fixed Default Preset**: Changed from `ultra-eco` to `balanced` for better general usage
- **Fixed Preset Switching**: `balanced` command now correctly uses `apply_preset` instead of legacy `set_power_profile`
- **Enhanced TLP Compatibility**: Disabled `TLP_ONLY_ON_GNOME` restriction for broader desktop environment support
- **GPU Switching Enabled**: Default configuration now enables GPU switching to support `supergfxctl`
- **Improved Status Tracking**: Fixed preset tracking and status display to show correct active preset
- **SupergfxCtl Integration**: Added support for modern GPU switching with supergfxctl daemon

### 🎯 **Verification Commands**
```bash
# Test preset switching
power-control.sh balanced
power-control.sh status | grep "Active Preset"  # Should show "balanced"

# Test GPU status (with supergfxctl)
gpu-status
supergfxctl --get

# Test TLP integration
power-control.sh tlp-status
```

## Architecture Overview

### Core Components Structure

**Main Scripts** (`scripts/`):
- `power-control.sh` - Central power management engine with preset system, GPU switching, TLP integration, hibernation support, and disk management integration
- `power-status.sh` - Universal status display and interactive preset selection interface
- `disk-manager.sh` - Dedicated disk management module with automatic and on-demand suspension capabilities

**Configuration System** (`configs/`):
- `power-control.conf` - Main system configuration (auto-modes, integrations, GPU switching)
- `power-presets.conf` - Comprehensive preset definitions with TLP, GPU, and power profile settings
- `power-manager.conf` - Additional power manager configuration

**Service Integration** (`services/`):
- `power-control-startup.service` - Auto-applies power settings on system startup
- `power-control-wake.service` - Handles power restoration after sleep/hibernation
- `power-control-monitor.timer` - Periodic system monitoring

### Power Management Architecture

**Layered Control System**:
1. **Preset Layer** - High-level user-friendly presets (ultra-eco, gaming-max, etc.)
2. **Integration Layer** - TLP integration, GPU switching (envycontrol), desktop environment detection
3. **System Layer** - Direct power profile control via powerprofilesctl or desktop-specific APIs
4. **Hardware Layer** - CPU frequency, GPU modes, hibernation swap management

**Desktop Environment Detection**:
- Automatically detects GNOME, KDE, or unknown environments
- Uses appropriate power management APIs (powerprofilesctl, gsettings, kreadconfig5)
- TLP integration can be limited to GNOME to avoid conflicts

**Preset System Design**:
- Configuration-driven presets defined in `power-presets.conf`
- Each preset combines: TLP_MODE, GPU_MODE, POWER_PROFILE, DESCRIPTION
- Supports 9 built-in presets from ultra-eco to gaming-max
- Preset application coordinates all subsystems (TLP → GPU → Power Profile)

### Multi-Distribution Support Architecture

**Package Manager Abstraction**:
- Automatic distribution detection via `/etc/os-release`
- Unified package installation interface supporting apt, dnf, pacman, zypper, apk
- Distribution-specific dependency mapping

**Service Integration**:
- Systemd-based service management
- Automatic conflict resolution (masks power-profiles-daemon when using TLP)
- Cross-desktop compatibility (GNOME, KDE, others)

## Key Development Patterns

### Configuration Management Pattern
```bash
# Configuration files are initialized with defaults if missing
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << CONF_EOF
# Configuration content here
CONF_EOF
fi
```

### Error Handling and Logging Pattern
```bash
# Consistent logging with timestamps and colors
log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Error counting for complex operations
local errors=0
some_operation || ((errors++))
[ $errors -eq 0 ] && success "All operations completed" || warning "$errors errors occurred"
```

### Capability Detection Pattern
```bash
# Feature availability detection
has_powerprofilesctl() { command -v powerprofilesctl > /dev/null 2>&1; }
has_tlp() { command -v tlp > /dev/null 2>&1; }

# Conditional feature execution
if should_use_tlp; then
    tlp_set_mode "$mode"
fi
```

### Preset Processing Pattern
```bash
# Dynamic preset configuration parsing
local preset_upper=$(echo "$preset" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
local tlp_var="${preset_upper}_TLP_MODE"
local tlp_mode=$(eval echo \$${tlp_var})
```

## Installation System

### Multi-Stage Installation Process
1. **System Detection** - Distribution, desktop environment, available tools
2. **Dependency Installation** - Package manager detection and dependency installation
3. **Script Installation** - Copy scripts to `/usr/local/bin/` with execute permissions
4. **Configuration Setup** - Install configs to `~/.config/` with backup handling
5. **Service Registration** - Install and enable systemd services
6. **TLP Configuration** - Handle TLP setup and conflict resolution
7. **Alias Creation** - Install convenient bash aliases

### Uninstallation Safety
- Interactive confirmation with component preview
- Configuration backup before removal
- Service cleanup with proper systemd daemon reload
- Restoration of masked services (power-profiles-daemon)

## Development and Testing Considerations

### Local Development Setup
- Scripts can be tested directly from the repository without installation
- Configuration files are created in `~/.config/` during first run
- Services can be tested manually using systemctl

### Cross-Distribution Testing Strategy
- Test on Ubuntu/Debian (apt), Fedora (dnf), Arch (pacman), openSUSE (zypper)
- Verify TLP integration and power-profiles-daemon conflict resolution
- Test desktop environment detection and power management APIs

### GPU Switching Testing
- Requires NVIDIA laptop with envycontrol installed
- GPU mode changes require reboot - factor into testing workflow
- Test integrated, hybrid, and discrete GPU modes

### Hibernation System Testing
- Requires encrypted swap partition setup
- Test swap activation/deactivation cycle
- Verify hibernation functionality and wake recovery

### Disk Management Testing
- Test disk detection and system disk identification
- Verify NVMe power management capabilities
- Test automatic suspension based on inactivity timeout
- Verify battery-only suspension mode works correctly
- Test manual suspend/wake operations on specific disks

## Common Debugging Commands

```bash
# System state inspection
power-control.sh status                    # Comprehensive system status
systemctl list-units | grep power-control # Service status
tlp-stat -s                               # TLP status (if available)
envycontrol --query                       # Current GPU mode

# Configuration debugging
cat ~/.config/power-control.conf          # Main configuration
cat ~/.config/power-presets.conf          # Preset definitions
journalctl -u power-control-startup       # Service logs

# Manual testing
power-control.sh list-presets             # Available presets
power-control.sh preset balanced-dgpu     # Apply specific preset
power-control.sh gpu-status               # GPU information

# Disk management debugging
disk-manager.sh status                     # Comprehensive disk status
power-control.sh disk-status               # Integrated disk status
disk-manager.sh list                       # Available disks for management
disk-manager.sh suspend nvme1n1           # Suspend specific disk
disk-manager.sh monitor                    # One-time activity monitoring
```

## Troubleshooting Integration Points

### TLP Conflicts
- power-profiles-daemon must be masked when using TLP
- TLP service status affects preset application
- Desktop environment determines TLP usage (can be GNOME-only)

### GPU Switching Issues
- envycontrol availability determines GPU switching capability
- Reboot requirements after GPU mode changes
- GPU_SWITCHING_ENABLED configuration flag controls feature

### Service Dependencies
- Services wait for graphical session and network targets
- User permissions affect PolicyKit authorization for power changes
- Service execution timing affects startup preset application

### Disk Management Issues
- NVMe power management requires specific kernel support and hardware capabilities
- System disk detection depends on root mount point analysis
- Disk activity monitoring requires read access to `/sys/block/*/stat`
- Automatic suspension respects battery-only mode configuration
- DISK_MANAGEMENT_ENABLED configuration flag controls feature availability

This system provides a comprehensive, distribution-agnostic power management solution with sophisticated preset management, multi-desktop support, disk management, and extensive hardware integration capabilities.
