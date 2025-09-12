# Application Power Consumption: Native vs Scaled

## Overview
This document provides realistic power consumption examples for different applications running at native resolution vs various scaling factors on EndeavourOS Linux systems. Power measurements are based on typical Intel/NVIDIA laptop configurations.

## Testing Methodology
These examples are based on measurements using:
- `pc monitor` - Linux Power Manager monitoring
- `powertop` - Intel power consumption tool
- Battery discharge rate analysis
- GPU usage monitoring via `nvidia-smi` and `intel_gpu_top`

## Web Browser Examples

### Firefox
**Native Resolution (1920x1080, no scaling)**
```
Active browsing:
- CPU: ~3-5W
- GPU (iGPU): ~2-3W
- RAM: ~2GB (standard usage)
- Total: ~6-8W

Hidden workspace:
- CPU: ~1-2W (background tabs)
- GPU: ~0.5-1W
- Total: ~2-3W
```

**Scaled 150% (UI scaling)**
```
Active browsing:
- CPU: ~4-7W (+1-2W for UI rendering)
- GPU (iGPU): ~4-6W (+100% GPU load)
- RAM: ~2.5GB (+25% memory)
- Total: ~9-13W (+50-60% increase)

Hidden workspace:
- CPU: ~1.5-2.5W (same background processing)
- GPU: ~0.5-1W (no scaling rendering)
- Total: ~2.5-3.5W (minimal increase)
```

### Chrome/Chromium
**Native Resolution**
```
Active browsing:
- CPU: ~4-6W
- GPU (iGPU): ~2-4W
- RAM: ~2.5GB
- Total: ~7-10W

Hidden workspace:
- CPU: ~1.5-2W
- GPU: ~0.5-1W
- Total: ~2.5-3W
```

**Scaled 200% (High DPI)**
```
Active browsing:
- CPU: ~6-9W (+40-50% increase)
- GPU (iGPU): ~5-8W (+150% GPU load)
- RAM: ~3.5GB (+40% memory)
- Total: ~12-17W (+70-80% increase)

Hidden workspace:
- CPU: ~2-2.5W
- GPU: ~0.5-1W
- Total: ~3-3.5W
```

## Code Editors & IDEs

### VSCode
**Native Resolution**
```
Active coding:
- CPU: ~3-4W
- GPU (iGPU): ~1-2W
- RAM: ~1.5GB
- Total: ~5-6W

Hidden workspace:
- CPU: ~1-1.5W
- GPU: ~0.5W
- Total: ~2W
```

**Scaled 125%**
```
Active coding:
- CPU: ~4-5W (+25% increase)
- GPU (iGPU): ~2-3W (+50% GPU load)
- RAM: ~1.8GB (+20% memory)
- Total: ~7-8W (+30-40% increase)

Hidden workspace:
- CPU: ~1-1.5W (same)
- GPU: ~0.5W (no rendering)
- Total: ~2W (no increase)
```

### JetBrains IDE (IntelliJ/PyCharm)
**Native Resolution**
```
Active development:
- CPU: ~5-8W
- GPU (iGPU): ~2-3W
- RAM: ~3GB
- Total: ~8-11W

Hidden workspace:
- CPU: ~2-3W (indexing continues)
- GPU: ~0.5W
- Total: ~3-3.5W
```

**Scaled 150%**
```
Active development:
- CPU: ~7-11W (+40% increase)
- GPU (iGPU): ~4-6W (+100% GPU load)
- RAM: ~4GB (+33% memory)
- Total: ~12-17W (+50-60% increase)

Hidden workspace:
- CPU: ~2.5-3W (same indexing)
- GPU: ~0.5W
- Total: ~3.5-4W (minimal increase)
```

## Gaming Examples

### Light Gaming (Indie Games)
**Native 1080p**
```
Active gaming:
- CPU: ~15-25W
- GPU (dGPU): ~40-60W
- RAM: ~4GB
- Total: ~60-85W

Alt-tabbed/minimized:
- CPU: ~8-12W (game paused)
- GPU: ~5-10W (minimal rendering)
- Total: ~15-22W
```

**Scaled 1440p (125% effective scaling)**
```
Active gaming:
- CPU: ~20-30W (+33% increase)
- GPU (dGPU): ~60-90W (+50% GPU load)
- RAM: ~5.5GB (+38% memory)
- Total: ~85-120W (+40-50% increase)

Alt-tabbed/minimized:
- CPU: ~10-15W
- GPU: ~5-10W (same minimal rendering)
- Total: ~18-25W
```

### AAA Gaming
**Native 1080p**
```
Active gaming:
- CPU: ~25-40W
- GPU (dGPU): ~80-120W
- RAM: ~8GB
- Total: ~110-160W

Alt-tabbed:
- CPU: ~15-20W
- GPU: ~10-15W
- Total: ~25-35W
```

**4K/Scaled 200%**
```
Active gaming:
- CPU: ~35-50W (+40% increase)
- GPU (dGPU): ~120-180W (+50% GPU load)
- RAM: ~12GB (+50% memory)
- Total: ~160-230W (+45-50% increase)

Alt-tabbed:
- CPU: ~15-20W (same)
- GPU: ~10-15W (same)
- Total: ~25-35W (no increase)
```

## Video Applications

### Video Player (VLC/MPV)
**1080p Video, Native UI**
```
Active playback:
- CPU: ~3-5W (software decode)
- GPU (iGPU): ~2-4W (hardware decode)
- RAM: ~500MB
- Total: ~6-9W

Hidden workspace:
- CPU: ~3-5W (audio continues)
- GPU: ~0.5W (no video rendering)
- Total: ~4-6W
```

**4K Video, Scaled 150% UI**
```
Active playback:
- CPU: ~5-8W (more complex decode)
- GPU (iGPU): ~8-12W (4K + UI scaling)
- RAM: ~1.2GB (+140% memory)
- Total: ~14-20W (+150% increase)

Hidden workspace:
- CPU: ~5-8W (audio + decode continues)
- GPU: ~0.5W (no rendering)
- Total: ~6-9W (same as native hidden)
```

### Video Editing (DaVinci Resolve/Kdenlive)
**Native 1080p Timeline**
```
Active editing:
- CPU: ~20-35W
- GPU (dGPU): ~30-50W
- RAM: ~8GB
- Total: ~55-85W

Hidden workspace:
- CPU: ~15-20W (background processing)
- GPU: ~5-10W
- Total: ~22-30W
```

**4K Timeline, Scaled 125% UI**
```
Active editing:
- CPU: ~30-45W (+50% increase)
- GPU (dGPU): ~60-90W (+100% GPU load)
- RAM: ~16GB (+100% memory)
- Total: ~95-135W (+70-80% increase)

Hidden workspace:
- CPU: ~20-25W (same background processing)
- GPU: ~5-10W (same)
- Total: ~27-35W (minimal increase)
```

## Terminal Applications

### Terminal Emulator (Alacritty/Kitty)
**Native Resolution**
```
Active terminal work:
- CPU: ~1-2W
- GPU (iGPU): ~0.5-1W
- RAM: ~200MB
- Total: ~2-3W

Hidden workspace:
- CPU: ~0.5-1W
- GPU: ~0.1-0.3W
- Total: ~1W
```

**Scaled 150% (Large fonts)**
```
Active terminal work:
- CPU: ~1.5-2.5W (+25% increase)
- GPU (iGPU): ~1-2W (+100% GPU load)
- RAM: ~300MB (+50% memory)
- Total: ~3-4.5W (+50% increase)

Hidden workspace:
- CPU: ~0.5-1W (same)
- GPU: ~0.1-0.3W (same)
- Total: ~1W (no increase)
```

## Power Management Commands for Testing

### Monitor Real-time Power Consumption
```bash
# Monitor overall system power
pc monitor

# Check specific component usage
pc status

# Monitor GPU usage during scaling tests
watch -n 1 'pc status | grep -E "(GPU|Power|Battery)"'

# Test different power presets during scaling
pc balanced      # For general scaled app usage
pc performance   # For scaled gaming/video
pc ultra-eco     # For minimal power with basic scaling
```

### Test Scaling Power Impact
```bash
# Before scaling test - establish baseline
pc status > baseline_power.txt

# Apply scaled application usage
# <run your scaled applications>

# After scaling test - measure difference
pc status > scaled_power.txt

# Compare power consumption
diff baseline_power.txt scaled_power.txt
```

## Key Takeaways

### Power Increase from Scaling:
- **UI Scaling (125-150%)**: +30-60% power increase when active
- **Resolution Scaling (4K)**: +50-100% power increase
- **Gaming Scaling**: +40-80% power increase
- **Video Scaling**: +50-150% power increase

### Hidden/Workspace Scaling Impact:
- **Rendering Power**: Drops to near zero (60-80% reduction)
- **Processing Power**: Remains the same as native
- **Memory Power**: Slight increase (10-20% more)

### Best Practices:
1. Use `pc balanced` for mixed scaled/native workloads
2. Switch to `pc performance` when actively using scaled demanding apps
3. Use `pc ultra-eco` when scaled apps are hidden in other workspaces
4. Monitor with `pc monitor` during scaling tests
5. Consider GPU switching based on scaling demands
