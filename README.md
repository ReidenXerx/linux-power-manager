# Linux Power Manager

🔋 **Universal Power Management System for Linux**

A comprehensive, cross-distribution power management solution that provides intelligent power presets, TLP integration, GPU switching, and hibernation support for Linux laptops and desktops.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Supported Distributions](https://img.shields.io/badge/Distros-Ubuntu%20%7C%20Fedora%20%7C%20Arch%20%7C%20openSUSE-blue.svg)](#supported-distributions)

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

### Common Issues

**TLP conflicts with power-profiles-daemon**
```bash
# Automatic fix during installation, or manual fix:
sudo systemctl mask power-profiles-daemon.service
sudo systemctl restart tlp.service
```

**GPU switching not working**
```bash
# Enable GPU switching
power-control.sh config
# Set GPU_SWITCHING_ENABLED=true

# Check envycontrol status
envycontrol --query
```

**Hibernation not working**
```bash
# Check hibernation status
power-control.sh hibstatus

# Configure hibernation
power-control.sh config
# Set HIBERNATION_ENABLED=true
```

**Preset not applying**
```bash
# Check preset exists
power-control.sh list-presets

# Check configuration
power-control.sh status

# Reset configuration
cp /usr/local/share/power-manager/power-control.conf.default ~/.config/power-control.conf
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
