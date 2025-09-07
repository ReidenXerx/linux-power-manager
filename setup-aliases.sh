#!/bin/bash

# Power Manager Alias Setup Script
# Version: 1.0.0
# Sets up convenient aliases and shortcuts for power management

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALIAS_FILE="$HOME/.bashrc"
ALIAS_BACKUP="$HOME/.bashrc.power-manager-backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# ALIAS SETUP FUNCTIONS
# ============================================================================

backup_bashrc() {
    log_info "Creating backup of .bashrc..."
    
    if [ -f "$ALIAS_FILE" ]; then
        cp "$ALIAS_FILE" "$ALIAS_BACKUP"
        log_success "Backup created: $ALIAS_BACKUP"
    else
        log_warning "No .bashrc found, will create new one"
    fi
}

add_aliases() {
    log_info "Adding power management aliases..."
    
    # Check if aliases already exist
    if grep -q "# Power Manager Aliases" "$ALIAS_FILE" 2>/dev/null; then
        log_warning "Power manager aliases already exist in .bashrc"
        return 0
    fi
    
    # Add aliases section
    cat >> "$ALIAS_FILE" << 'ALIAS_EOF'

# Power Manager Aliases
# =====================
# Convenient shortcuts for power management

# Main power control command
alias pc='power-control'
alias power='power-control'

# Status commands
alias pstatus='power-control status'
alias phealth='power-control health-check'
alias pmetrics='power-control metrics'

# System preset commands
alias pultra='power-control system-preset ultra-eco'
alias peco='power-control system-preset eco'
alias pbalanced='power-control system-preset balanced'
alias pperformance='power-control system-preset performance'
alias pgaming='power-control system-preset gaming'
alias pwork='power-control system-preset work'
alias pdev='power-control system-preset developer'

# GPU preset commands
alias gintegrated='power-control gpu-preset integrated'
alias ghybrid='power-control gpu-preset hybrid'
alias gdiscrete='power-control gpu-preset discrete'
alias ggaming='power-control gpu-preset gaming'
alias geco='power-control gpu-preset eco'

# Composite preset commands (quick access)
alias ultra='power-control ultra-eco'
alias eco='power-control eco-gaming'
alias balanced='power-control balanced'
alias balanced-dgpu='power-control balanced-dgpu'
alias performance='power-control performance'
alias performance-dgpu='power-control performance-dgpu'
alias gaming='power-control gaming-max'
alias work='power-control work-mode'
alias dev='power-control developer-mode'

# List commands
alias plist='power-control list-all-presets'
alias plistsys='power-control list-system-presets'
alias plistgpu='power-control list-gpu-presets'
alias plistcomp='power-control list-composite-presets'

# Help and version
alias phelp='power-control help'
alias pversion='power-control version'

# Power status (legacy command)
alias pstat='power-status.sh'

# End of Power Manager Aliases
ALIAS_EOF

    log_success "Power management aliases added to .bashrc"
}

create_desktop_shortcuts() {
    log_info "Creating desktop shortcuts..."
    
    # Create desktop directory if it doesn't exist
    DESKTOP_DIR="$HOME/Desktop"
    if [ ! -d "$DESKTOP_DIR" ]; then
        mkdir -p "$DESKTOP_DIR"
    fi
    
    # Create desktop shortcuts for common presets
    create_desktop_shortcut "Power Control - Balanced" "power-control balanced" "applications-system"
    create_desktop_shortcut "Power Control - Gaming" "power-control gaming-max" "applications-games"
    create_desktop_shortcut "Power Control - Ultra Eco" "power-control ultra-eco" "battery"
    create_desktop_shortcut "Power Control - Status" "power-control status" "utilities-system-monitor"
    
    log_success "Desktop shortcuts created"
}

create_desktop_shortcut() {
    local name="$1"
    local command="$2"
    local icon="$3"
    local filename="$DESKTOP_DIR/${name// /_}.desktop"
    
    cat > "$filename" << DESKTOP_EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Comment=Power Management Shortcut
Exec=gnome-terminal -- bash -c "$command; read -p 'Press Enter to close...'"
Icon=$icon
Terminal=true
Categories=System;Settings;
DESKTOP_EOF

    chmod +x "$filename"
}

create_shell_completion() {
    log_info "Setting up shell completion..."
    
    # Create completion script
    COMPLETION_FILE="$HOME/.power-control-completion.sh"
    
    cat > "$COMPLETION_FILE" << COMPLETION_EOF
# Power Control Bash Completion
# ============================

_power_control_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="\${COMP_WORDS[COMP_CWORD]}"
    prev="\${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    opts="status health-check metrics help version"
    opts="\$opts system-preset gpu-preset composite-preset"
    opts="\$opts list-system-presets list-gpu-presets list-composite-presets list-all-presets"
    opts="\$opts ultra-eco eco-gaming balanced balanced-dgpu performance performance-dgpu gaming-max work-mode developer-mode"
    
    # System presets
    if [[ \$prev == "system-preset" ]]; then
        COMPREPLY=( \$(compgen -W "ultra-eco eco balanced performance gaming work developer" -- \$cur) )
        return 0
    fi
    
    # GPU presets
    if [[ \$prev == "gpu-preset" ]]; then
        COMPREPLY=( \$(compgen -W "integrated hybrid discrete gaming eco" -- \$cur) )
        return 0
    fi
    
    # Composite presets
    if [[ \$prev == "composite-preset" ]]; then
        COMPREPLY=( \$(compgen -W "ultra-eco eco-gaming balanced balanced-dgpu performance performance-dgpu gaming-max work-mode developer-mode" -- \$cur) )
        return 0
    fi
    
    # Default completion
    COMPREPLY=( \$(compgen -W "\$opts" -- \$cur) )
    return 0
}

complete -F _power_control_completion power-control
complete -F _power_control_completion pc
complete -F _power_control_completion power
COMPLETION_EOF

    # Add completion to .bashrc
    if ! grep -q "power-control-completion" "$ALIAS_FILE"; then
        echo "" >> "$ALIAS_FILE"
        echo "# Power Control Completion" >> "$ALIAS_FILE"
        echo "source $COMPLETION_FILE" >> "$ALIAS_FILE"
        log_success "Shell completion added"
    else
        log_warning "Shell completion already exists"
    fi
}

create_man_pages() {
    log_info "Creating man pages..."
    
    # Create man page directory
    MAN_DIR="$HOME/.local/share/man/man1"
    mkdir -p "$MAN_DIR"
    
    # Create man page for power-control
    cat > "$MAN_DIR/power-control.1" << MAN_EOF
.TH POWER-CONTROL 1 "2025-09-07" "Power Manager" "User Commands"
.SH NAME
power-control \- Modular power management system
.SH SYNOPSIS
.B power-control
[\fIcommand\fR] [\fIoptions\fR]
.SH DESCRIPTION
Power Control is a modular power management system that provides flexible,
composable power management with separate system and GPU presets.
.SH COMMANDS
.TP
\fBstatus\fR
Show modular system status
.TP
\fBhealth-check\fR
Run comprehensive health check
.TP
\fBmetrics\fR
Show system metrics
.TP
\fBsystem-preset <name>\fR
Apply system preset (TLP, power profile, WiFi, disk)
.TP
\fBgpu-preset <name>\fR
Apply GPU preset (GPU switching only)
.TP
\fBcomposite-preset <name>\fR
Apply composite preset (system + GPU)
.TP
\fBultra-eco\fR
Quick apply ultra eco composite preset
.TP
\fBbalanced\fR
Quick apply balanced composite preset
.TP
\fBgaming-max\fR
Quick apply gaming max composite preset
.TP
\fBhelp\fR
Show help information
.TP
\fBversion\fR
Show version information
.SH EXAMPLES
.TP
\fBpower-control status\fR
Show current system status
.TP
\fBpower-control system-preset gaming\fR
Apply gaming system preset
.TP
\fBpower-control gpu-preset hybrid\fR
Apply hybrid GPU preset
.TP
\fBpower-control balanced\fR
Apply balanced composite preset
.SH ALIASES
Common aliases are available:
.TP
\fBpc\fR
Short for power-control
.TP
\fBpstatus\fR
Short for power-control status
.TP
\fBpbalanced\fR
Short for power-control system-preset balanced
.TP
\fBghybrid\fR
Short for power-control gpu-preset hybrid
.SH FILES
.TP
\fB~/.config/modular-power.conf\fR
Main configuration file
.TP
\fB~/.config/system-presets.conf\fR
System presets configuration
.TP
\fB~/.config/gpu-presets.conf\fR
GPU presets configuration
.TP
\fB~/.config/composite-presets.conf\fR
Composite presets configuration
.SH AUTHOR
Power Manager Team
.SH SEE ALSO
power-status.sh(1), tlp(8), supergfxctl(1)
MAN_EOF

    # Update man database
    if command -v mandb >/dev/null 2>&1; then
        mandb -q
        log_success "Man pages created and database updated"
    else
        log_success "Man pages created"
    fi
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_aliases() {
    log_info "Validating aliases..."
    
    # Check if .bashrc was modified
    if grep -q "# Power Manager Aliases" "$ALIAS_FILE"; then
        log_success "Aliases found in .bashrc"
    else
        log_error "Aliases not found in .bashrc"
        return 1
    fi
    
    # Check if completion is set up
    if grep -q "power-control-completion" "$ALIAS_FILE"; then
        log_success "Shell completion found"
    else
        log_warning "Shell completion not found"
    fi
    
    # Check if man pages exist
    if [ -f "$HOME/.local/share/man/man1/power-control.1" ]; then
        log_success "Man pages found"
    else
        log_warning "Man pages not found"
    fi
    
    log_success "Alias validation completed"
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================

main() {
    echo "=========================================="
    echo "Power Manager - Alias Setup"
    echo "=========================================="
    echo ""
    
    log_info "Setting up power management aliases and shortcuts..."
    echo ""
    
    # Backup .bashrc
    backup_bashrc
    echo ""
    
    # Add aliases
    add_aliases
    echo ""
    
    # Create desktop shortcuts
    create_desktop_shortcuts
    echo ""
    
    # Set up shell completion
    create_shell_completion
    echo ""
    
    # Create man pages
    create_man_pages
    echo ""
    
    # Validate setup
    validate_aliases
    echo ""
    
    echo "=========================================="
    log_success "Alias setup completed!"
    echo "=========================================="
    echo ""
    echo "Available aliases:"
    echo "  pc, power          # Main power control command"
    echo "  pstatus, phealth   # Status commands"
    echo "  pultra, peco       # System presets"
    echo "  gintegrated, ghybrid # GPU presets"
    echo "  ultra, balanced    # Composite presets"
    echo "  plist, plistsys    # List commands"
    echo ""
    echo "To use the new aliases, run:"
    echo "  source ~/.bashrc"
    echo ""
    echo "Or restart your terminal session."
    echo ""
    log_info "Desktop shortcuts created in ~/Desktop"
    log_info "Man pages available: man power-control"
    log_info "Backup of .bashrc: $ALIAS_BACKUP"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Check if help requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Power Manager - Alias Setup"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Create backup of .bashrc"
    echo "  2. Add convenient aliases for power management"
    echo "  3. Create desktop shortcuts for common presets"
    echo "  4. Set up shell completion"
    echo "  5. Create man pages"
    echo "  6. Validate the setup"
    echo ""
    echo "After running this script, you can use shortcuts like:"
    echo "  pc status        # Instead of power-control status"
    echo "  pbalanced        # Instead of power-control system-preset balanced"
    echo "  ghybrid          # Instead of power-control gpu-preset hybrid"
    echo "  balanced         # Instead of power-control balanced"
    exit 0
fi

# Run main function
main "$@"
