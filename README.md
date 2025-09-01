# Linux Power Manager

🔋 **Universal Power Management System for Linux**

A comprehensive, cross-distribution power management solution that provides intelligent power presets, TLP integration, GPU switching, disk management, and hibernation support for Linux laptops and desktops.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Supported Distributions](https://img.shields.io/badge/Distros-Ubuntu%20%7C%20Fedora%20%7C%20Arch%20%7C%20openSUSE-blue.svg)](#supported-distributions)

## 📖 Table of Contents

**Quick Navigation:**
- [✨ Features](#-features) - What this tool can do
- [🚀 Quick Start](#-quick-start) - Get up and running fast
- [📖 Core Modules](#-core-modules) - Detailed module documentation
  - [⚡ Power Presets](#-power-presets) - Smart power management
  - [🎮 GPU Switching](#-gpu-switching-nvidia-laptops) - NVIDIA GPU control
  - [💾 Disk Management](#-disk-management) - Automatic disk suspension
  - [🌙 Hibernation](#-hibernation-support) - Secure hibernation
- [🎯 Usage Examples](#-usage-examples) - Real-world examples
- [⚙️ Configuration](#️-configuration) - Customize your setup
- [🛠️ Troubleshooting](#️-troubleshooting) - Fix common issues
- [🤝 Contributing](#-contributing) - Help improve the project

## ✨ Features

### 🎯 **Smart Power Presets**
- **9 Built-in Presets**: From ultra-eco to gaming-max performance
- **Custom Configurations**: Easily create your own power profiles
- **Interactive Selection**: Menu-driven preset switching
- **Automatic Application**: Apply presets on startup, wake, or manually

### ⚡ **Advanced Power Management**
- **TLP Integration**: Deep integration with TLP for optimal power savings
- **Multi-Desktop Support**: Works with GNOME, KDE, and other environments  
- **Conflict Resolution**: Automatically handles power-profiles-daemon conflicts
- **Real-time Monitoring**: Live power status and system information

### 🎮 **GPU Switching (NVIDIA Laptops)**
- **envycontrol Integration**: Seamless switching between Intel iGPU and NVIDIA dGPU
- **Three GPU Modes**: Integrated, Hybrid, and Discrete modes
- **Power-Aware**: Automatic GPU selection based on power preset
- **Safe Operations**: Prevents accidental switches with confirmation prompts

### 💾 **Disk Management**
- **Automatic Suspension**: Suspend inactive disks to save 2-8W per drive
- **Smart Whitelisting**: Temporarily or permanently protect disks from suspension
- **System Disk Protection**: Never suspends critical system/boot drives
- **Battery-Aware**: Only suspend disks when on battery power for maximum savings
- **NVMe + SATA Support**: Works with modern NVMe and traditional SATA drives
- **Monitoring Daemon**: Continuous background monitoring with safety limits

### 🌙 **Hibernation Support**
- **Encrypted Swap**: Secure hibernation with LUKS encryption
- **Automatic Management**: Dynamic swap activation/deactivation
- **Energy Savings**: Swap disabled during battery mode for power savings
- **Resume Support**: Reliable wake-from-hibernation

### 🔧 **System Integration**
- **Systemd Services**: Auto-startup and wake handling
- **Universal Installation**: One-click setup across multiple distributions
- **Bash Aliases**: Convenient shortcuts for common operations
- **Configuration Management**: Centralized settings with backup support

## 🚀 Quick Start

### One-Line Installation

```bash
# Download and run installer
curl -sSL https://raw.githubusercontent.com/username/linux-power-manager/main/install.sh | bash

# Or for interactive installation
curl -sSL https://raw.githubusercontent.com/username/linux-power-manager/main/install.sh | bash -s -- --interactive
```

### Manual Installation

```bash
# Clone repository
git clone https://github.com/username/linux-power-manager.git
cd linux-power-manager

# Run installer
./install.sh

# Or interactive mode
./install.sh --interactive
```

## 📋 Available Power Presets

| Preset | TLP Mode | GPU Mode | Power Profile | Use Case |
|--------|----------|----------|---------------|-----------|
| `ultra-eco` | Battery | Integrated | Power-saver | Maximum battery life |
| `eco-gaming` | Balanced | Hybrid | Balanced | Light gaming with good battery |
| `work-mode` | Balanced | Integrated | Balanced | Office productivity |
| `balanced` | Auto | Hybrid | Balanced | General purpose (default) |
| `balanced-dgpu` | Balanced | Hybrid | Balanced | Balanced with dGPU capabilities |
| `developer-mode` | AC | Hybrid | Performance | Development workloads |
| `performance` | AC | Hybrid | Performance | High performance tasks |
| `performance-dgpu` | AC | Discrete | Performance | Maximum performance with dGPU |
| `gaming-max` | AC | Discrete | Performance | Maximum gaming performance |

## 🎮 Usage Examples

### Basic Power Management

```bash
# Show current power status
power-control.sh status

# List available presets
power-control.sh list-presets

# Apply a preset
power-control.sh ultra-eco
power-control.sh gaming-max

# Interactive preset selection
power-status.sh select-preset
```

### GPU Management (NVIDIA Laptops)

```bash
# Check current GPU mode
power-control.sh gpu-status

# Switch GPU modes
power-control.sh gpu-integrated    # Intel iGPU only (best battery)
power-control.sh gpu-hybrid        # Both GPUs (automatic switching)
power-control.sh gpu-nvidia        # NVIDIA dGPU only (max performance)
```

### Using Aliases (after installation)

```bash
# Quick status check
power-status

# Preset shortcuts
power-eco           # Ultra eco mode
power-balanced      # Balanced mode  
power-performance   # High performance
power-gaming        # Gaming mode

# Interactive menu
power-select
```

### Configuration

```bash
# Configure power management settings
power-control.sh config

# Edit configurations manually
nano ~/.config/power-control.conf
nano ~/.config/power-presets.conf
```

## 🐧 Supported Distributions

### Fully Tested
- **Ubuntu** 20.04+ / **Linux Mint** 20+
- **Fedora** 35+ / **CentOS Stream** 9+
- **Arch Linux** / **Manjaro** / **EndeavourOS**
- **openSUSE Leap** 15.4+ / **Tumbleweed**

### Should Work
- **Debian** 11+ / **Pop!_OS** 21.04+
- **Rocky Linux** / **AlmaLinux** 9+
- **Elementary OS** 6+
- **Alpine Linux** 3.15+

The installer automatically detects your distribution and uses the appropriate package manager (`apt`, `dnf`, `pacman`, `zypper`, or `apk`).

## 📦 Dependencies

### Required
- `bash` (4.0+)
- `systemd` (for services)
- `bc` (calculations)
- `acpi` (battery info)
- `lm-sensors` (temperature monitoring)

### Optional
- `tlp` + `tlp-rdw` (advanced power management)
- `envycontrol` (GPU switching for NVIDIA laptops)
- `curl`/`wget` (for updates)

All dependencies are automatically installed by the installer.

## 📖 Core Modules

### ⚡ Power Presets

The heart of Linux Power Manager - intelligent power management with 9 built-in presets.

#### Quick Commands
```bash
# Show current status
power-control.sh status

# List all available presets
power-control.sh list-presets

# Apply specific presets
power-control.sh ultra-eco        # Maximum battery life
power-control.sh balanced         # Default balanced mode
power-control.sh gaming-max       # Maximum performance

# Interactive selection
power-status.sh select-preset
```

#### Preset Details

**Ultra Eco Mode** (`ultra-eco`)
- **Purpose**: Maximum battery life
- **TLP Mode**: Battery optimized
- **GPU**: Integrated only
- **Power Profile**: Power-saver
- **Best for**: Long flights, all-day battery life

**Gaming Max** (`gaming-max`)
- **Purpose**: Maximum gaming performance
- **TLP Mode**: AC power optimized
- **GPU**: Discrete NVIDIA only
- **Power Profile**: Performance
- **Best for**: AAA gaming, GPU-intensive tasks

**Balanced** (`balanced`) - *Default*
- **Purpose**: General daily use
- **TLP Mode**: Automatic switching
- **GPU**: Hybrid (intelligent switching)
- **Power Profile**: Balanced
- **Best for**: Productivity, web browsing, light development

#### TLP Integration
- **Automatic Configuration**: Presets automatically configure TLP settings
- **Conflict Resolution**: Handles power-profiles-daemon conflicts
- **Real-time Updates**: TLP settings applied instantly
- **Custom TLP**: Supports custom TLP configurations

---

### 🎮 GPU Switching (NVIDIA Laptops)

Seamless switching between Intel iGPU and NVIDIA dGPU for optimal power/performance balance.

#### Prerequisites
```bash
# Install envycontrol (handled by installer)
sudo pip install envycontrol

# Enable GPU switching
power-control.sh config
# Set GPU_SWITCHING_ENABLED=true
```

#### GPU Modes

**Integrated Mode** (`gpu-integrated`)
- **GPUs Active**: Intel iGPU only
- **Power Usage**: Lowest (~5-15W)
- **Performance**: Basic graphics, good for productivity
- **Battery Life**: Maximum (8-12+ hours)
- **Reboot**: Required to switch

**Hybrid Mode** (`gpu-hybrid`) - *Recommended*
- **GPUs Active**: Both Intel + NVIDIA
- **Power Usage**: Dynamic (5-40W+ based on load)
- **Performance**: Automatic GPU switching per application
- **Battery Life**: Good (4-8 hours)
- **Reboot**: Not required for most switches

**Discrete Mode** (`gpu-nvidia`)
- **GPUs Active**: NVIDIA dGPU only
- **Power Usage**: Highest (15-50W+ constant)
- **Performance**: Maximum graphics performance
- **Battery Life**: Reduced (2-4 hours)
- **Reboot**: Required to switch

#### Commands
```bash
# Check current GPU status
power-control.sh gpu-status
envycontrol --query

# Switch GPU modes
power-control.sh gpu-integrated    # Intel iGPU only
power-control.sh gpu-hybrid        # Hybrid mode (both GPUs)
power-control.sh gpu-nvidia        # NVIDIA dGPU only

# GPU info and monitoring
nvidia-smi                         # NVIDIA GPU stats
intel_gpu_top                      # Intel iGPU stats (if installed)
```

#### Smart GPU Selection
Presets automatically select optimal GPU modes:
- **Ultra Eco/Work Mode**: Forces Integrated
- **Gaming Max/Performance**: Uses Discrete
- **Balanced Modes**: Uses Hybrid
- **Manual Override**: Can override preset GPU selection

---

### 💾 Disk Management

Automatically suspend inactive storage devices to save power, especially useful for laptops with multiple drives.

#### Features
- **Automatic Suspension**: Suspend inactive disks after configurable timeout
- **Smart Whitelisting**: Temporarily protect disks from suspension
- **Never-Expire Protection**: Permanently protect critical disks
- **System Disk Protection**: Automatically excludes system/boot disks
- **Battery-Only Mode**: Only suspend disks when on battery power
- **NVMe + SATA Support**: Works with modern NVMe and traditional SATA drives

#### Quick Start
```bash
# Check disk management status
disk-manager.sh status

# List all available disks
disk-manager.sh list

# Configure disk management
disk-manager.sh config

# Manually suspend a disk
disk-manager.sh suspend nvme1n1

# Wake up a disk (auto-protects from suspension)
disk-manager.sh wake nvme1n1
```

#### Configuration (`~/.config/disk-manager.conf`)
```bash
# Enable disk management
DISK_MANAGEMENT_ENABLED=true
AUTO_SUSPEND_ENABLED=true

# Suspend after 5 minutes of inactivity
INACTIVITY_TIMEOUT=300

# Only suspend on battery (recommended)
SUSPEND_ON_BATTERY_ONLY=true

# Auto-detect non-system disks
MONITORED_DISKS="auto"
EXCLUDE_SYSTEM_DISK=true

# Whitelist default duration (1 hour)
WHITELIST_DEFAULT_EXPIRY=3600
```

#### Whitelist System
Protect disks from automatic suspension:

```bash
# Show current whitelist
disk-manager.sh whitelist

# Add disk to whitelist (default: 1 hour)
disk-manager.sh whitelist-add nvme1n1

# Add disk with custom duration (2 hours)
disk-manager.sh whitelist-add nvme1n1 7200

# Add disk with never-expire protection
disk-manager.sh whitelist-add nvme1n1 0

# Remove from whitelist
disk-manager.sh whitelist-remove nvme1n1

# Clear entire whitelist
disk-manager.sh whitelist-clear
```

#### Monitoring
```bash
# Run one-time monitoring cycle
disk-manager.sh monitor

# Start continuous monitoring daemon (24h auto-stop)
disk-manager.sh monitor-daemon

# Stop monitoring daemon
disk-manager.sh stop-daemon

# Check if disk is sleeping
disk-manager.sh sleeping nvme1n1

# Check disk activity
disk-manager.sh activity nvme1n1
```

#### Power Savings
- **NVMe Drives**: Can save 2-5W per drive when suspended
- **SATA Drives**: Can save 3-8W per drive when suspended
- **Multiple Drives**: Savings scale with number of drives
- **Battery Impact**: Can extend battery life by 30-60 minutes

#### Safety Features
- **System Disk Protection**: Never suspends system/boot drives
- **Whitelist Override**: Manual wake-up auto-protects disks
- **Never-Expire Support**: Critical disks can be permanently protected
- **Activity Detection**: Only suspends truly inactive drives
- **Graceful Handling**: Proper filesystem sync before suspension

---

### 🌙 Hibernation Support

Secure hibernation with LUKS encryption and intelligent power management.

#### Features
- **Encrypted Hibernation**: LUKS-encrypted swap for security
- **Dynamic Swap**: Automatic swap file creation/management
- **Battery-Aware**: Disable swap on battery to save power
- **Resume Support**: Reliable wake-from-hibernation
- **Space Management**: Automatic swap size calculation

#### Setup
```bash
# Enable hibernation
power-control.sh config
# Set HIBERNATION_ENABLED=true

# Check hibernation status
power-control.sh hibstatus

# Test hibernation (recommended)
sudo systemctl hibernate
```

#### Configuration (`~/.config/power-control.conf`)
```bash
# Enable hibernation support
HIBERNATION_ENABLED=true

# Disable swap on battery (saves ~200-500MB RAM)
DISABLE_SWAP_ON_BATTERY=true

# Custom swap file location (optional)
# HIBERNATION_SWAP_FILE=/swapfile

# Custom swap size (auto-calculated by default)
# HIBERNATION_SWAP_SIZE=8G
```

#### Commands
```bash
# Check hibernation status and configuration
power-control.sh hibstatus

# Manual hibernation
sudo systemctl hibernate

# Check swap status
swapon --show
free -h

# Check hibernation capabilities
cat /sys/power/disk
cat /proc/swaps
```

#### How It Works
1. **Encrypted Swap**: Creates LUKS-encrypted swap file
2. **Kernel Configuration**: Updates GRUB with resume parameters
3. **Dynamic Management**: Enables swap only when needed
4. **Power Savings**: Disables swap on battery to save RAM power
5. **Secure Resume**: Encrypted swap protects hibernated data

#### Power Savings
- **Hibernation vs Sleep**: Uses 0W vs 3-8W in sleep mode
- **Long-term Storage**: Perfect for overnight or multi-day storage
- **Swap Disable**: Saves 200-500MB RAM power on battery
- **Fast Resume**: Typically 10-30 seconds to full resume

---

## ⚙️ Configuration

### Main Configuration (`~/.config/power-control.conf`)
```bash
# Auto-apply eco mode on startup
AUTO_ECO_ON_STARTUP=true

# Auto-apply eco mode after wake from sleep
AUTO_ECO_ON_WAKE=true

# Enable TLP integration
TLP_INTEGRATION_ENABLED=true

# Enable GPU switching (NVIDIA laptops only)
GPU_SWITCHING_ENABLED=false

# Enable hibernation support
HIBERNATION_ENABLED=false

# Default preset to apply on startup
DEFAULT_PRESET=balanced
```

### Custom Presets (`~/.config/power-presets.conf`)
```bash
# Custom preset example
MY_PRESET_TLP_MODE=balanced
MY_PRESET_GPU_MODE=hybrid
MY_PRESET_POWER_PROFILE=balanced
MY_PRESET_DESCRIPTION="My custom power profile"
```

## 🔧 Advanced Features

### TLP Integration
- Automatic TLP mode switching (battery/AC/balanced)
- Conflict resolution with power-profiles-daemon
- Custom TLP configuration support
- Real-time TLP status monitoring

### GPU Switching Details
- **Integrated Mode**: Intel iGPU only, maximum battery life
- **Hybrid Mode**: Both GPUs available, automatic switching
- **Discrete Mode**: NVIDIA dGPU only, maximum performance
- **Reboot Handling**: Automatic reboot prompts when required

### Hibernation Features
- **Encrypted Swap**: LUKS encryption for security
- **Dynamic Management**: Swap only active when needed
- **Power Savings**: Disabled during battery mode
- **Resume Support**: Proper wake-from-hibernation

## 🛠️ Troubleshooting

### Power Management Issues

**TLP conflicts with power-profiles-daemon**
```bash
# Automatic fix during installation, or manual fix:
sudo systemctl mask power-profiles-daemon.service
sudo systemctl restart tlp.service

# Verify TLP is working
sudo tlp-stat | head -20
```

**Preset not applying**
```bash
# Check preset exists
power-control.sh list-presets

# Check current configuration
power-control.sh status

# Reset to default configuration
cp /usr/local/share/power-manager/power-control.conf.default ~/.config/power-control.conf

# Reapply preset
power-control.sh balanced
```

### GPU Switching Issues

**GPU switching not working**
```bash
# Enable GPU switching
power-control.sh config
# Set GPU_SWITCHING_ENABLED=true

# Check envycontrol status
envycontrol --query

# Check NVIDIA driver installation
nvidia-smi
lspci | grep -i nvidia

# Reset GPU configuration
sudo envycontrol --reset
```

**Reboot required but system won't reboot**
```bash
# Force reboot for GPU switch
sudo systemctl reboot

# Check if switch completed after reboot
power-control.sh gpu-status
```

### Disk Management Issues

**Disks not being detected**
```bash
# Check disk management status
disk-manager.sh status

# List all available disks
lsblk
disk-manager.sh list

# Check configuration
cat ~/.config/disk-manager.conf
```

**Disks not suspending**
```bash
# Check if disk management is enabled
disk-manager.sh status

# Verify disk is monitored
disk-manager.sh list

# Check if disk is whitelisted
disk-manager.sh whitelist

# Manual suspend test
disk-manager.sh suspend nvme1n1

# Check disk activity
disk-manager.sh activity nvme1n1
```

**System disk being suspended (DANGEROUS)**
```bash
# This should never happen, but if it does:
# 1. Immediately wake the system disk
disk-manager.sh wake nvme0n1  # or whatever your system disk is

# 2. Add system disk to permanent whitelist
disk-manager.sh whitelist-add nvme0n1 0  # 0 = never expire

# 3. Check system disk detection
disk-manager.sh system-disk

# 4. Ensure system disk exclusion is enabled
disk-manager.sh config
# Set EXCLUDE_SYSTEM_DISK=true
```

**Disk won't wake up**
```bash
# Try multiple wake attempts
disk-manager.sh wake nvme1n1
sudo dd if=/dev/nvme1n1 of=/dev/null bs=512 count=1

# Check if disk is physically responding
sudo dmesg | tail -20
lsblk

# For NVMe drives
sudo nvme list
sudo nvme get-feature -f 0x02 /dev/nvme1n1

# For SATA drives
sudo hdparm -C /dev/sdb
```

**Monitoring daemon issues**
```bash
# Check if daemon is running
ps aux | grep disk-manager

# Stop stuck daemon
disk-manager.sh stop-daemon

# Check daemon logs
journalctl | grep disk-manager

# Restart with debugging
disk-manager.sh monitor  # Single run for testing
```

### Hibernation Issues

**Hibernation not working**
```bash
# Check hibernation status
power-control.sh hibstatus

# Enable hibernation
power-control.sh config
# Set HIBERNATION_ENABLED=true

# Check swap configuration
swapon --show
free -h

# Check hibernation support
cat /sys/power/disk
ls -la /proc/swaps
```

**Resume from hibernation fails**
```bash
# Check GRUB configuration
sudo cat /proc/cmdline | grep resume

# Verify swap UUID
sudo blkid | grep swap

# Check hibernation image
sudo cat /sys/power/image_size
sudo cat /sys/power/reserved_size
```

### System Integration Issues

**Aliases not working**
```bash
# Reload bash configuration
source ~/.bashrc

# Check if aliases were installed
grep -i power ~/.bashrc

# Manual alias installation
echo 'alias power-status="power-status.sh"' >> ~/.bashrc
echo 'alias power-eco="power-control.sh ultra-eco"' >> ~/.bashrc
source ~/.bashrc
```

**Services not starting**
```bash
# Check service status
systemctl status power-control-startup.service
systemctl status power-control-wake.service

# Enable services
sudo systemctl enable power-control-startup.service
sudo systemctl enable power-control-wake.service

# View service logs
journalctl -u power-control-startup.service -n 50
```

### Logs and Debugging
```bash
# Check systemd services
systemctl status power-control-startup.service
systemctl status power-control-wake.service

# Check TLP status
power-control.sh tlp-status

# View system logs
journalctl -u power-control-startup.service
```

## 🔄 Updating

```bash
# Re-run installer to update
./install.sh

# Or via curl
curl -sSL https://raw.githubusercontent.com/username/linux-power-manager/main/install.sh | bash
```

## 🗑️ Uninstallation

```bash
# Run uninstaller
./uninstall.sh

# Or download and run
curl -sSL https://raw.githubusercontent.com/username/linux-power-manager/main/uninstall.sh | bash
```

The uninstaller safely removes all components and optionally backs up your configurations.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
```bash
git clone https://github.com/username/linux-power-manager.git
cd linux-power-manager

# Test installation in VM
./install.sh

# Run tests
./tests/run-tests.sh
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [TLP](https://linrunner.de/tlp/) - Advanced power management
- [envycontrol](https://github.com/bayasdev/envycontrol) - GPU switching utility
- Linux community for power management insights

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/username/linux-power-manager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/username/linux-power-manager/discussions)
- **Wiki**: [Project Wiki](https://github.com/username/linux-power-manager/wiki)

---

**Made with ❤️ for the Linux community**
