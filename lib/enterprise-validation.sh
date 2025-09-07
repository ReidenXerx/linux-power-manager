#!/bin/bash

# Enterprise Validation System
# Version: 1.0.0
# Comprehensive input validation and security checks

# ============================================================================
# VALIDATION CONFIGURATION
# ============================================================================

VALIDATION_CONFIG_FILE="$HOME/.config/power-manager-validation.conf"
VALIDATION_LEVEL="moderate"  # strict, moderate, permissive

# ============================================================================
# VALIDATION INITIALIZATION
# ============================================================================

init_validation() {
    # Initialize validation configuration
    init_validation_config
    
    # Load configuration
    source "$VALIDATION_CONFIG_FILE" 2>/dev/null || true
}

init_validation_config() {
    if [ ! -f "$VALIDATION_CONFIG_FILE" ]; then
        cat > "$VALIDATION_CONFIG_FILE" << 'VAL_CONF_EOF'
# Enterprise Validation Configuration
VALIDATION_LEVEL=moderate
SECURITY_CHECKS_ENABLED=true
PRIVILEGE_ESCALATION_CHECK=true
FILE_PERMISSION_CHECK=true
INPUT_SANITIZATION=true
PATH_TRAVERSAL_PROTECTION=true
COMMAND_INJECTION_PROTECTION=true
VAL_CONF_EOF
    fi
}

# ============================================================================
# INPUT VALIDATION FUNCTIONS
# ============================================================================

# Validate preset name
validate_preset_name() {
    local preset="$1"
    local preset_type="${2:-any}"  # system, gpu, composite, any
    
    # Check if preset is empty
    if [ -z "$preset" ]; then
        log_error "Preset name cannot be empty" "VALIDATION"
        return 1
    fi
    
    # Check for invalid characters
    if [[ ! "$preset" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Preset name contains invalid characters: $preset" "VALIDATION"
        return 1
    fi
    
    # Check length
    if [ ${#preset} -gt 50 ]; then
        log_error "Preset name too long: $preset" "VALIDATION"
        return 1
    fi
    
    # Check for reserved names
    local reserved_names=("none" "null" "undefined" "default" "system" "root" "admin")
    for reserved in "${reserved_names[@]}"; do
        if [ "$preset" = "$reserved" ]; then
            log_error "Preset name is reserved: $preset" "VALIDATION"
            return 1
        fi
    done
    
    log_debug "Preset name validation passed: $preset" "VALIDATION"
    return 0
}

# Validate file path
validate_file_path() {
    local path="$1"
    local allow_relative="${2:-false}"
    
    # Check if path is empty
    if [ -z "$path" ]; then
        log_error "File path cannot be empty" "VALIDATION"
        return 1
    fi
    
    # Check for path traversal attempts
    if [[ "$path" =~ \.\. ]]; then
        log_error "Path traversal attempt detected: $path" "VALIDATION"
        return 1
    fi
    
    # Check for absolute path if required
    if [ "$allow_relative" = "false" ] && [[ ! "$path" =~ ^/ ]]; then
        log_error "Absolute path required: $path" "VALIDATION"
        return 1
    fi
    
    # Check for null bytes
    if [[ "$path" =~ $'\0' ]]; then
        log_error "Null byte in path: $path" "VALIDATION"
        return 1
    fi
    
    log_debug "File path validation passed: $path" "VALIDATION"
    return 0
}

# Validate configuration value
validate_config_value() {
    local key="$1"
    local value="$2"
    
    # Check if key is empty
    if [ -z "$key" ]; then
        log_error "Configuration key cannot be empty" "VALIDATION"
        return 1
    fi
    
    # Check if value is empty
    if [ -z "$value" ]; then
        log_error "Configuration value cannot be empty: $key" "VALIDATION"
        return 1
    fi
    
    # Validate key format
    if [[ ! "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
        log_error "Invalid configuration key format: $key" "VALIDATION"
        return 1
    fi
    
    # Check for command injection attempts
    if [[ "$value" =~ [\;\|\&\`\$\(\)] ]]; then
        log_error "Command injection attempt detected in value: $key" "VALIDATION"
        return 1
    fi
    
    log_debug "Configuration value validation passed: $key" "VALIDATION"
    return 0
}

# ============================================================================
# SECURITY VALIDATION FUNCTIONS
# ============================================================================

# Validate privilege escalation
validate_privilege_escalation() {
    local command="$1"
    
    if [ "$PRIVILEGE_ESCALATION_CHECK" != "true" ]; then
        return 0
    fi
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_warning "Running as root - privilege escalation validation skipped" "VALIDATION"
        return 0
    fi
    
    # Check if command requires sudo
    if [[ "$command" =~ ^sudo ]]; then
        # Validate sudo command
        local sudo_command="${command#sudo }"
        
        # Check for dangerous commands
        local dangerous_commands=("rm -rf" "dd if=" "mkfs" "fdisk" "parted")
        for dangerous in "${dangerous_commands[@]}"; do
            if [[ "$sudo_command" =~ $dangerous ]]; then
                log_error "Dangerous command detected: $sudo_command" "VALIDATION"
                return 1
            fi
        done
        
        # Check for system file modifications
        if [[ "$sudo_command" =~ ^(cp|mv|rm|chmod|chown).*/(etc|usr|var|sys|proc) ]]; then
            log_warning "System file modification detected: $sudo_command" "VALIDATION"
        fi
    fi
    
    log_debug "Privilege escalation validation passed: $command" "VALIDATION"
    return 0
}

# Validate file permissions
validate_file_permissions() {
    local file="$1"
    local required_permissions="${2:-644}"
    
    if [ "$FILE_PERMISSION_CHECK" != "true" ]; then
        return 0
    fi
    
    if [ ! -f "$file" ]; then
        log_error "File does not exist: $file" "VALIDATION"
        return 1
    fi
    
    # Get current permissions
    local current_permissions=$(stat -c "%a" "$file" 2>/dev/null)
    
    if [ -z "$current_permissions" ]; then
        log_error "Cannot read file permissions: $file" "VALIDATION"
        return 1
    fi
    
    # Check if permissions are too permissive
    if [ "$current_permissions" -gt "$required_permissions" ]; then
        log_warning "File permissions too permissive: $file ($current_permissions > $required_permissions)" "VALIDATION"
        
        if [ "$VALIDATION_LEVEL" = "strict" ]; then
            log_error "Strict validation failed: file permissions too permissive" "VALIDATION"
            return 1
        fi
    fi
    
    log_debug "File permissions validation passed: $file" "VALIDATION"
    return 0
}

# ============================================================================
# SYSTEM VALIDATION FUNCTIONS
# ============================================================================

# Validate system state
validate_system_state() {
    local component="$1"
    
    case "$component" in
        "tlp")
            validate_tlp_state
            ;;
        "gpu")
            validate_gpu_state
            ;;
        "power")
            validate_power_state
            ;;
        "disk")
            validate_disk_state
            ;;
        *)
            log_error "Unknown system component: $component" "VALIDATION"
            return 1
            ;;
    esac
}

# Validate TLP state
validate_tlp_state() {
    if ! command -v tlp >/dev/null 2>&1; then
        log_warning "TLP not available" "VALIDATION"
        return 1
    fi
    
    # Check if TLP is running
    if ! systemctl is-active tlp >/dev/null 2>&1; then
        log_warning "TLP service not active" "VALIDATION"
        return 1
    fi
    
    # Check TLP configuration
    if [ ! -f "/etc/tlp.conf" ]; then
        log_error "TLP configuration file not found" "VALIDATION"
        return 1
    fi
    
    log_debug "TLP state validation passed" "VALIDATION"
    return 0
}

# Validate GPU state
validate_gpu_state() {
    # Check for GPU switching tools
    local gpu_tools=("supergfxctl" "envycontrol")
    local found_tool=false
    
    for tool in "${gpu_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            found_tool=true
            break
        fi
    done
    
    if [ "$found_tool" = "false" ]; then
        log_warning "No GPU switching tools available" "VALIDATION"
        return 1
    fi
    
    log_debug "GPU state validation passed" "VALIDATION"
    return 0
}

# Validate power state
validate_power_state() {
    # Check for power management tools
    local power_tools=("powerprofilesctl" "gsettings")
    local found_tool=false
    
    for tool in "${power_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            found_tool=true
            break
        fi
    done
    
    if [ "$found_tool" = "false" ]; then
        log_warning "No power management tools available" "VALIDATION"
        return 1
    fi
    
    log_debug "Power state validation passed" "VALIDATION"
    return 0
}

# Validate disk state
validate_disk_state() {
    # Check for disk management tools
    if ! command -v disk-manager.sh >/dev/null 2>&1; then
        log_warning "Disk manager not available" "VALIDATION"
        return 1
    fi
    
    log_debug "Disk state validation passed" "VALIDATION"
    return 0
}

# ============================================================================
# CONFIGURATION VALIDATION FUNCTIONS
# ============================================================================

# Validate configuration file
validate_config_file() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file" "VALIDATION"
        return 1
    fi
    
    # Check file permissions
    validate_file_permissions "$config_file" "644"
    
    # Check for syntax errors
    if ! bash -n "$config_file" 2>/dev/null; then
        log_error "Configuration file has syntax errors: $config_file" "VALIDATION"
        return 1
    fi
    
    # Check for dangerous content
    if grep -q "rm -rf\|dd if=\|mkfs\|fdisk" "$config_file"; then
        log_error "Dangerous commands found in configuration file: $config_file" "VALIDATION"
        return 1
    fi
    
    log_debug "Configuration file validation passed: $config_file" "VALIDATION"
    return 0
}

# Validate preset configuration
validate_preset_config() {
    local preset_file="$1"
    local preset_type="$2"
    
    if [ ! -f "$preset_file" ]; then
        log_error "Preset configuration file not found: $preset_file" "VALIDATION"
        return 1
    fi
    
    # Check file permissions
    validate_file_permissions "$preset_file" "644"
    
    # Validate preset-specific settings
    case "$preset_type" in
        "system")
            validate_system_preset_config "$preset_file"
            ;;
        "gpu")
            validate_gpu_preset_config "$preset_file"
            ;;
        "composite")
            validate_composite_preset_config "$preset_file"
            ;;
        *)
            log_error "Unknown preset type: $preset_type" "VALIDATION"
            return 1
            ;;
    esac
    
    log_debug "Preset configuration validation passed: $preset_file" "VALIDATION"
    return 0
}

# Validate system preset configuration
validate_system_preset_config() {
    local preset_file="$1"
    
    # Check for required system preset settings
    local required_settings=("TLP_MODE" "POWER_PROFILE" "WIFI_MODE" "DISK_MODE" "DESCRIPTION")
    
    for setting in "${required_settings[@]}"; do
        if ! grep -q "^[A-Z_]*_${setting}=" "$preset_file"; then
            log_warning "Missing system preset setting: $setting" "VALIDATION"
        fi
    done
    
    return 0
}

# Validate GPU preset configuration
validate_gpu_preset_config() {
    local preset_file="$1"
    
    # Check for required GPU preset settings
    local required_settings=("GPU_MODE" "DESCRIPTION")
    
    for setting in "${required_settings[@]}"; do
        if ! grep -q "^[A-Z_]*_${setting}=" "$preset_file"; then
            log_warning "Missing GPU preset setting: $setting" "VALIDATION"
        fi
    done
    
    return 0
}

# Validate composite preset configuration
validate_composite_preset_config() {
    local preset_file="$1"
    
    # Check for required composite preset settings
    local required_settings=("SYSTEM_PRESET" "GPU_PRESET" "DESCRIPTION")
    
    for setting in "${required_settings[@]}"; do
        if ! grep -q "^[A-Z_]*_COMPOSITE_${setting}=" "$preset_file"; then
            log_warning "Missing composite preset setting: $setting" "VALIDATION"
        fi
    done
    
    return 0
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

export -f init_validation
export -f validate_preset_name
export -f validate_file_path
export -f validate_config_value
export -f validate_privilege_escalation
export -f validate_file_permissions
export -f validate_system_state
export -f validate_tlp_state
export -f validate_gpu_state
export -f validate_power_state
export -f validate_disk_state
export -f validate_config_file
export -f validate_preset_config
export -f validate_system_preset_config
export -f validate_gpu_preset_config
export -f validate_composite_preset_config
