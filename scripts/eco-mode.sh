#!/bin/bash

echo "🌱 Switching to ECO MODE (Maximum Power Savings)..."

# Set power profile to power-saver only if power-profiles-daemon is available
if powerprofilesctl list >/dev/null 2>&1; then
    powerprofilesctl set power-saver 2>/dev/null
    POWER_PROFILE=$(powerprofilesctl get 2>/dev/null || echo "TLP-managed")
else
    POWER_PROFILE="TLP-managed"
fi

# Disable turbo boost for maximum energy savings
sudo bash -c 'echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo' 2>/dev/null

# Verify changes
echo "✅ Power Profile: $POWER_PROFILE"
echo "✅ Turbo Boost Disabled: $(cat /sys/devices/system/cpu/intel_pstate/no_turbo)"

# Show current CPU frequencies
echo "📊 Current CPU frequencies (first 4 cores):"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | head -4 | while read freq; do
    echo "   $(echo "scale=2; $freq/1000" | bc) MHz"
done

# Show temperature (suppress sensor errors)
echo "🌡️  CPU Temperature: $(sensors 2>/dev/null | grep "Package id 0" | awk '{print $4}')"

echo "🎯 ECO MODE ACTIVATED - Optimized for battery life and low heat!"
