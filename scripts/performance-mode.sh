#!/bin/bash

echo "🚀 Switching to PERFORMANCE MODE (Maximum Power)..."

# Set power profile to performance only if power-profiles-daemon is available
if powerprofilesctl list >/dev/null 2>&1; then
    powerprofilesctl set performance 2>/dev/null
    POWER_PROFILE=$(powerprofilesctl get 2>/dev/null || echo "TLP-managed")
else
    POWER_PROFILE="TLP-managed"
fi

# Enable turbo boost for maximum performance
sudo bash -c 'echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo'

# Verify changes
echo "✅ Power Profile: $POWER_PROFILE"
echo "✅ Turbo Boost Enabled: $(cat /sys/devices/system/cpu/intel_pstate/no_turbo)"

# Show current CPU frequencies
echo "📊 Current CPU frequencies (first 4 cores):"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | head -4 | while read freq; do
    echo "   $(echo "scale=2; $freq/1000" | bc) MHz"
done

# Show temperature
echo "🌡️  CPU Temperature: $(sensors | grep "Package id 0" | awk '{print $4}')"

echo "⚡ PERFORMANCE MODE ACTIVATED - Full power unleashed!"
