#!/bin/bash

# Enterprise Logging System
# Version: 1.0.0
# RFC 5424 compliant logging with multiple destinations

# ============================================================================
# ENTERPRISE LOGGING CONFIGURATION
# ============================================================================

LOG_CONFIG_FILE="$HOME/.config/power-manager-logging.conf"
LOG_DIR="/var/log/power-manager"
LOG_FILE="$LOG_DIR/power-manager.log"
LOG_LEVEL=6  # Default to INFO level

# RFC 5424 Log Levels
LOG_EMERG=0   # Emergency: system is unusable
LOG_ALERT=1   # Alert: action must be taken immediately
LOG_CRIT=2    # Critical: critical conditions
LOG_ERR=3     # Error: error conditions
LOG_WARNING=4 # Warning: warning conditions
LOG_NOTICE=5  # Notice: normal but significant condition
LOG_INFO=6    # Informational: informational messages
LOG_DEBUG=7   # Debug: debug-level messages

# ============================================================================
# LOGGING INITIALIZATION
# ============================================================================

init_logging() {
    # Create log directory
    sudo mkdir -p "$LOG_DIR" 2>/dev/null || true
    sudo chown $USER:$USER "$LOG_DIR" 2>/dev/null || true
    
    # Initialize logging configuration
    init_logging_config
    
    # Load configuration
    source "$LOG_CONFIG_FILE" 2>/dev/null || true
    
    # Set up log rotation
    setup_log_rotation
}

init_logging_config() {
    if [ ! -f "$LOG_CONFIG_FILE" ]; then
        cat > "$LOG_CONFIG_FILE" << LOG_CONF_EOF
# Enterprise Logging Configuration
LOG_LEVEL=6
LOG_TO_CONSOLE=true
LOG_TO_FILE=true
LOG_TO_JOURNAL=true
LOG_TO_SYSLOG=false
LOG_FORMAT="RFC5424"
LOG_TIMESTAMP_FORMAT="ISO8601"
LOG_INCLUDE_CONTEXT=true
LOG_INCLUDE_PID=true
LOG_INCLUDE_HOSTNAME=true
LOG_ROTATION_ENABLED=true
LOG_MAX_SIZE="10M"
LOG_MAX_FILES=5
LOG_CONF_EOF
    fi
}

# ============================================================================
# ENTERPRISE LOGGING FUNCTIONS
# ============================================================================

# Main logging function
log_message() {
    local level="$1"
    local message="$2"
    local context="${3:-GENERAL}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local hostname=$(hostname)
    local pid=$$
    local level_name=""
    
    # Convert numeric level to name
    case "$level" in
        $LOG_EMERG) level_name="EMERG" ;;
        $LOG_ALERT) level_name="ALERT" ;;
        $LOG_CRIT) level_name="CRIT" ;;
        $LOG_ERR) level_name="ERROR" ;;
        $LOG_WARNING) level_name="WARNING" ;;
        $LOG_NOTICE) level_name="NOTICE" ;;
        $LOG_INFO) level_name="INFO" ;;
        $LOG_DEBUG) level_name="DEBUG" ;;
        *) level_name="UNKNOWN" ;;
    esac
    
    # Check if we should log this level
    if [ "$level" -gt "$LOG_LEVEL" ]; then
        return 0
    fi
    
    # Format message according to RFC 5424
    local formatted_message="<${level}>1 ${timestamp} ${hostname} power-manager ${pid} [${context}] ${message}"
    
    # Log to console
    if [ "$LOG_TO_CONSOLE" = "true" ]; then
        log_to_console "$level" "$message" "$context"
    fi
    
    # Log to file
    if [ "$LOG_TO_FILE" = "true" ]; then
        log_to_file "$formatted_message"
    fi
    
    # Log to journal
    if [ "$LOG_TO_JOURNAL" = "true" ]; then
        log_to_journal "$level" "$message" "$context"
    fi
    
    # Log to syslog
    if [ "$LOG_TO_SYSLOG" = "true" ]; then
        log_to_syslog "$formatted_message"
    fi
}

# Console logging with colors
log_to_console() {
    local level="$1"
    local message="$2"
    local context="$3"
    local timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        $LOG_EMERG|$LOG_ALERT|$LOG_CRIT)
            echo -e "\033[1;31m[${timestamp}] [${context}] EMERGENCY: ${message}\033[0m" >&2
            ;;
        $LOG_ERR)
            echo -e "\033[0;31m[${timestamp}] [${context}] ERROR: ${message}\033[0m" >&2
            ;;
        $LOG_WARNING)
            echo -e "\033[1;33m[${timestamp}] [${context}] WARNING: ${message}\033[0m"
            ;;
        $LOG_NOTICE)
            echo -e "\033[0;32m[${timestamp}] [${context}] NOTICE: ${message}\033[0m"
            ;;
        $LOG_INFO)
            echo -e "\033[0;36m[${timestamp}] [${context}] INFO: ${message}\033[0m"
            ;;
        $LOG_DEBUG)
            echo -e "\033[0;35m[${timestamp}] [${context}] DEBUG: ${message}\033[0m"
            ;;
    esac
}

# File logging
log_to_file() {
    local message="$1"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || true
}

# Journal logging
log_to_journal() {
    local level="$1"
    local message="$2"
    local context="$3"
    
    if command -v logger >/dev/null 2>&1; then
        logger -t "power-manager" -p "user.${level}" "[${context}] ${message}" 2>/dev/null || true
    fi
}

# Syslog logging
log_to_syslog() {
    local message="$1"
    
    if command -v logger >/dev/null 2>&1; then
        logger -t "power-manager" "$message" 2>/dev/null || true
    fi
}

# ============================================================================
# CONVENIENCE LOGGING FUNCTIONS
# ============================================================================

log_emerg() { log_message $LOG_EMERG "$1" "$2"; }
log_alert() { log_message $LOG_ALERT "$1" "$2"; }
log_crit() { log_message $LOG_CRIT "$1" "$2"; }
log_error() { log_message $LOG_ERR "$1" "$2"; }
log_warning() { log_message $LOG_WARNING "$1" "$2"; }
log_notice() { log_message $LOG_NOTICE "$1" "$2"; }
log_info() { log_message $LOG_INFO "$1" "$2"; }
log_debug() { log_message $LOG_DEBUG "$1" "$2"; }

# Success and error aliases
log_success() { log_message $LOG_NOTICE "SUCCESS: $1" "$2"; }
log_failure() { log_message $LOG_ERR "FAILURE: $1" "$2"; }

# ============================================================================
# LOG ROTATION
# ============================================================================

setup_log_rotation() {
    if [ "$LOG_ROTATION_ENABLED" = "true" ]; then
        # Create logrotate configuration
        sudo tee /etc/logrotate.d/power-manager >/dev/null << EOF
$LOG_FILE {
    daily
    missingok
    rotate $LOG_MAX_FILES
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        # Reload any services if needed
    endscript
}
EOF
    fi
}

# ============================================================================
# LOG ANALYSIS FUNCTIONS
# ============================================================================

# Get log statistics
get_log_stats() {
    if [ -f "$LOG_FILE" ]; then
        echo "Log Statistics:"
        echo "==============="
        echo "Total entries: $(wc -l < "$LOG_FILE")"
        echo "File size: $(du -h "$LOG_FILE" | cut -f1)"
        echo "Last modified: $(stat -c %y "$LOG_FILE")"
        echo ""
        echo "Level distribution:"
        grep -o '<[0-9]>' "$LOG_FILE" | sort | uniq -c | while read count level; do
            case "$level" in
                "<0>") echo "  EMERGENCY: $count" ;;
                "<1>") echo "  ALERT: $count" ;;
                "<2>") echo "  CRITICAL: $count" ;;
                "<3>") echo "  ERROR: $count" ;;
                "<4>") echo "  WARNING: $count" ;;
                "<5>") echo "  NOTICE: $count" ;;
                "<6>") echo "  INFO: $count" ;;
                "<7>") echo "  DEBUG: $count" ;;
            esac
        done
    else
        echo "No log file found at: $LOG_FILE"
    fi
}

# Search logs
search_logs() {
    local pattern="$1"
    local level="${2:-}"
    
    if [ -f "$LOG_FILE" ]; then
        if [ -n "$level" ]; then
            grep "<${level}>" "$LOG_FILE" | grep "$pattern"
        else
            grep "$pattern" "$LOG_FILE"
        fi
    else
        echo "No log file found at: $LOG_FILE"
    fi
}

# Export functions
export -f init_logging
export -f log_message
export -f log_emerg
export -f log_alert
export -f log_crit
export -f log_error
export -f log_warning
export -f log_notice
export -f log_info
export -f log_debug
export -f log_success
export -f log_failure
export -f get_log_stats
export -f search_logs
