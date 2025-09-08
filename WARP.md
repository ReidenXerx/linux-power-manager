# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Linux Power Manager is a comprehensive, cross-distribution power management system designed specifically for Linux laptops and desktops. It provides intelligent power presets, TLP integration, GPU switching, disk management, hibernation support, and WiFi optimization with special focus on Intel hardware.

## Architecture

### Modular Design Philosophy
The system follows a modular architecture with clear separation of concerns:

- **Core Module**: `scripts/power-control-modular.sh` - Main unified interface (`pc` command)
- **Enterprise Libraries**: Professional-grade logging, validation, monitoring, and desktop detection (`lib/`)
- **Specialized Scripts**: Standalone tools for advanced operations (`scripts/`)
- **Configuration System**: Flexible, hierarchical configuration management (`configs/`)
- **Systemd Integration**: Services and timers for system-level integration (`services/`)

### Key Components

#### 1. Main Power Control System
- **Entry Point**: `scripts/power-control-modular.sh` - The unified `pc` command
- **Library System**: `lib/modular-power-system.sh` - Core modular functionality
- **Enterprise Features**: RFC 5424 logging, input validation, system monitoring

#### 2. Configuration Hierarchy
- **Main Config**: `configs/power-control.conf` - Primary system settings
- **Power Presets**: `configs/power-presets.conf` - Predefined power profiles
- **Disk Management**: `configs/disk-manager.conf` - Disk suspension settings
- **WiFi Optimization**: `configs/wifi-intel-optimizations.conf` - Intel WiFi tuning

#### 3. Systemd Services
- **Startup Service**: `power-control-startup.service` - Boot-time power application
- **Wake Service**: `power-control-wake.service` - Post-suspend/hibernate restoration
- **Monitor Services**: Continuous monitoring with timers for power, disk, and WiFi

#### 4. Specialized Tools
- **Disk Manager**: `scripts/disk-manager.sh` - Advanced disk suspension management
- **WiFi Optimizer**: `scripts/wifi-intel-optimizer.sh` - Intel WiFi power optimization

### Power Preset System

The system includes 9+ built-in power presets optimized for different use cases:

- **Ultra Eco**: Maximum battery life with integrated GPU only
- **Eco Gaming**: Light gaming with good battery life
- **Balanced**: Default balanced mode with hybrid GPU
- **Balanced dGPU**: Balanced mode with discrete GPU capabilities
- **Performance**: High performance for demanding tasks
- **Performance dGPU**: Performance mode with discrete GPU
- **Gaming Max**: Maximum performance for gaming
- **Work Mode**: Optimized for productivity
- **Developer Mode**: Optimized for development workloads

Each preset controls:
- TLP power management mode (battery/AC/balanced)
- GPU switching (integrated/hybrid/discrete)
- Power profiles (power-saver/balanced/performance)
- Disk suspension behavior
- WiFi power optimization levels

## Common Commands

### Power Management
```bash
# Main power control interface
pc status                    # Complete system status
pc list-presets             # Show available power presets
pc <preset-name>            # Apply a power preset
pc config                   # Configure system settings

# Power preset shortcuts
pbalanced                   # Apply balanced preset
pultra                      # Apply ultra eco preset
peco                        # Apply eco preset
pperformance               # Apply performance preset
pgaming                     # Apply gaming preset

# GPU switching shortcuts
gintegrated                 # Switch to integrated GPU
ghybrid                     # Switch to hybrid GPU mode
gdiscrete                   # Switch to discrete GPU
```

### Specialized Operations
```bash
# WiFi power optimization
pc wifi-status              # Check WiFi power status
pc wifi-optimize            # Apply WiFi optimizations
wifi-intel-optimizer.sh optimize  # Standalone WiFi optimization

# Disk management
pc disk-status              # Check disk management status
pc disk-monitor             # Monitor disk activity
disk-manager.sh config      # Advanced disk configuration
disk-manager.sh list        # List all available disks
disk-manager.sh suspend <disk>  # Manually suspend a disk
```

### System Services
```bash
# Service management
sudo systemctl enable power-control-startup.service
sudo systemctl enable power-control-wake.service
sudo systemctl status power-control-monitor.service

# View service logs
journalctl -u power-control-startup.service -n 50
```

## Installation & Setup

### Installation
```bash
# Standard installation
./install.sh

# Interactive installation with customization
./install.sh --interactive

# Modular comprehensive installation
./install-modular-comprehensive.sh
```

### Post-Installation Setup
1. **Configure Power Settings**: Run `pc config` to customize system behavior
2. **Enable Services**: Services are automatically enabled during installation
3. **Test Presets**: Try different power presets with `pc <preset-name>`
4. **GPU Setup** (NVIDIA laptops): Enable GPU switching in configuration
5. **WiFi Optimization** (Intel adapters): Run `pc wifi-optimize` for Intel WiFi tuning

### Uninstallation
```bash
# Standard uninstall
./uninstall.sh

# Comprehensive uninstall with cleanup
./uninstall-modular-comprehensive.sh
```

## Development

### Project Structure
```
├── scripts/                    # Main executable scripts
│   ├── power-control-modular.sh    # Main unified interface
│   ├── disk-manager.sh            # Disk management tool
│   └── wifi-intel-optimizer.sh    # WiFi optimization tool
├── lib/                       # Enterprise libraries
│   ├── modular-power-system.sh    # Core modular system
│   ├── enterprise-logging.sh      # RFC 5424 logging
│   ├── enterprise-validation.sh   # Input validation
│   ├── enterprise-monitoring.sh   # System monitoring
│   └── desktop-detection.sh       # Desktop environment detection
├── configs/                   # Configuration templates
├── services/                  # Systemd service definitions
├── presets/                   # TLP preset configurations
└── install.sh / uninstall.sh # Installation scripts
```

### Key Libraries

#### Enterprise Logging (`lib/enterprise-logging.sh`)
- RFC 5424 compliant logging system
- Multiple log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Structured logging with context and metadata
- Functions: `log_info()`, `log_error()`, `log_warning()`, `log_success()`, `log_debug()`

#### Validation System (`lib/enterprise-validation.sh`)
- Input sanitization and validation
- Security checks for command parameters
- Configuration file validation
- Functions: `validate_preset_name()`, `validate_config_value()`, `sanitize_input()`

#### System Monitoring (`lib/enterprise-monitoring.sh`)
- System metrics collection
- Performance monitoring
- Health checks and status reporting
- Functions: `collect_system_metrics()`, `monitor_power_status()`, `health_check()`

#### Desktop Detection (`lib/desktop-detection.sh`)
- Comprehensive desktop environment detection
- Supports 15+ desktop environments (GNOME, KDE, XFCE, etc.)
- Desktop-specific power management integration

### Testing and Validation

The project includes built-in validation systems:

#### Testing WiFi Optimizations
```bash
# Test WiFi power levels
wifi-intel-optimizer.sh test

# Check optimization status  
wifi-intel-optimizer.sh status
```

#### Testing Power Presets
```bash
# Validate preset configuration
pc validate-preset <preset-name>

# Test preset application
pc <preset-name> --dry-run
```

#### System Health Checks
```bash
# Run system diagnostics
pc diagnostic

# Check service status
pc service-status

# Monitor system metrics
pc monitor
```

### Configuration Management

#### Hierarchical Configuration System
1. **System Defaults**: Built-in defaults in the scripts
2. **Global Config**: `/usr/local/share/power-manager/*.conf.default`
3. **User Config**: `~/.config/*.conf` (user customizations)
4. **Runtime Config**: Temporary overrides via environment variables

#### Key Configuration Files
- `power-control.conf`: Main system configuration
- `power-presets.conf`: Power preset definitions
- `disk-manager.conf`: Disk management settings
- `wifi-intel-optimizations.conf`: WiFi optimization parameters
- `modular-power.conf`: Modular system configuration

### GPU Switching Support

#### Supported GPU Switching Tools
- **envycontrol**: Primary tool for NVIDIA Optimus laptops
- **supergfxctl**: ASUS ROG laptops with supergfxd
- **Manual switching**: Direct GPU control via kernel parameters

#### GPU Modes
- **Integrated**: Intel iGPU only (maximum battery life)
- **Hybrid**: Both GPUs available with automatic switching
- **Discrete**: NVIDIA dGPU only (maximum performance)

### Intel Hardware Optimizations

The system includes specific optimizations for Intel hardware:

#### Intel WiFi Adapters (AX200, AX210, AX1650, AX1690, etc.)
- Power spike reduction through iwlwifi parameter tuning
- U-APSD (Unscheduled Automatic Power Save Delivery) support
- Scan optimization to reduce background activity
- Expected savings: 1-5W reduction in WiFi power consumption

#### Intel Arc Graphics Support
- Dedicated presets for Intel Arc Graphics (A350M, A370M, A730M, A770M)
- Intel hybrid CPU architecture optimization (P-Core/E-Core balance)
- Creative workload optimization for content creation

#### Intel CPU Power Management
- Intel Speed Shift technology integration
- Turbo Boost management
- C-state optimization for better idle power consumption

### Disk Management Features

#### Automatic Disk Suspension
- **NVMe Support**: Can save 2-5W per drive when suspended
- **SATA Support**: Can save 3-8W per drive when suspended  
- **Smart Whitelisting**: Protect critical disks from suspension
- **System Disk Protection**: Never suspends boot/system drives
- **Battery-Only Mode**: Only suspend disks when on battery power

#### Disk Management Commands
```bash
# Advanced disk operations
disk-manager.sh list                    # List all available disks
disk-manager.sh whitelist              # Show current whitelist
disk-manager.sh whitelist-add <disk>   # Protect disk from suspension
disk-manager.sh monitor-daemon         # Start monitoring daemon
disk-manager.sh activity <disk>        # Check disk activity
```

## Supported Distributions

### Fully Tested
- Ubuntu 20.04+ / Linux Mint 20+
- Fedora 35+ / CentOS Stream 9+  
- Arch Linux / Manjaro / EndeavourOS
- openSUSE Leap 15.4+ / Tumbleweed

### Package Manager Support
- **APT**: Ubuntu, Debian, Pop!_OS, Linux Mint
- **DNF**: Fedora, RHEL, CentOS Stream, Rocky Linux
- **Pacman**: Arch Linux, Manjaro, EndeavourOS
- **Zypper**: openSUSE Leap, openSUSE Tumbleweed
- **APK**: Alpine Linux

## Dependencies

### Required Dependencies
- `bash` (4.0+) - Shell scripting environment
- `systemd` - Service management
- `bc` - Mathematical calculations
- `acpi` - Battery and power information
- `lm-sensors` - Temperature monitoring

### Optional Dependencies
- `tlp` + `tlp-rdw` - Advanced power management (recommended)
- `envycontrol` - GPU switching for NVIDIA laptops
- `supergfxctl` - GPU switching for ASUS ROG laptops
- `curl`/`wget` - For updates and downloads

## Enterprise Features

### RFC 5424 Compliant Logging
- Structured logging with severity levels
- Contextual logging with component identification
- Log rotation and management
- Integration with system journal (journald)

### Input Validation & Security
- Command parameter sanitization
- Configuration file validation
- Security checks for privileged operations
- Prevention of code injection attacks

### System Monitoring & Metrics
- Real-time power consumption monitoring
- System health checks and diagnostics
- Performance metrics collection
- Automated issue detection and reporting

### Multi-Desktop Support
Supports 15+ desktop environments including:
- GNOME (with native power-profiles-daemon integration)
- KDE Plasma (with PowerDevil integration)
- XFCE, MATE, Cinnamon, LXQt, LXDE
- i3, Sway, bspwm, and other window managers

## Best Practices

### Power Management
1. **Use Default Presets First**: Start with built-in presets before creating custom ones
2. **Test GPU Switching**: Always test GPU mode changes in a safe environment
3. **Monitor Battery Life**: Use `pc status` regularly to monitor power consumption
4. **Enable Auto-Apply**: Let the system automatically apply power settings on startup/wake

### Development
1. **Follow Modular Design**: Keep functionality separated into appropriate modules
2. **Use Enterprise Logging**: Always use the logging functions for consistent output
3. **Validate Inputs**: Use validation functions for all user inputs
4. **Test on Multiple Distros**: Verify compatibility across supported distributions

### Configuration
1. **Use Hierarchical Configs**: Override defaults in user config files, don't modify system files
2. **Document Custom Settings**: Add comments to configuration files for future reference
3. **Backup Configurations**: Keep backups of working configurations before major changes
4. **Test Configuration Changes**: Use dry-run modes when available to test changes

This modular, enterprise-quality power management system provides comprehensive control over Linux laptop and desktop power consumption while maintaining flexibility, security, and ease of use across multiple distributions.
