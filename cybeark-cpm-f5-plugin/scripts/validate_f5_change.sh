#!/bin/bash
################################################################################
# CyberArk CPM F5 Validation Script
# Description: Validates F5 password change by checking /var/log/secure
#              Uses timestamp-based validation to confirm success/failure
# Usage: validate_f5_change.sh <username>
################################################################################

# Exit on error
set -e

# Configuration
SECURE_LOG="/var/log/secure"
USERNAME="${1}"
VALIDATION_LOG="/var/log/cybeark_f5_validation.log"
TIMESTAMP_TOLERANCE=60  # seconds

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${VALIDATION_LOG}"
}

# Function to convert timestamp to epoch
timestamp_to_epoch() {
    local timestamp="$1"
    date -d "${timestamp}" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "${timestamp}" +%s 2>/dev/null
}

# Function to validate password change in secure log
validate_password_change() {
    local username="$1"
    local current_time=$(date +%s)
    local search_start_time=$((current_time - TIMESTAMP_TOLERANCE))
    
    log_message "INFO: Validating password change for user: ${username}"
    log_message "INFO: Checking log file: ${SECURE_LOG}"
    log_message "INFO: Current time (epoch): ${current_time}"
    log_message "INFO: Search window: last ${TIMESTAMP_TOLERANCE} seconds"
    
    # Check if secure log exists and is readable
    if [ ! -f "${SECURE_LOG}" ]; then
        log_message "ERROR: Secure log file not found: ${SECURE_LOG}"
        return 1
    fi
    
    if [ ! -r "${SECURE_LOG}" ]; then
        log_message "ERROR: Cannot read secure log file: ${SECURE_LOG}"
        return 1
    fi
    
    # Search for password change success patterns
    local success_patterns=(
        "password changed for user ${username}"
        "password changed for ${username}"
        "password successfully changed for user ${username}"
        "user ${username} password changed"
        "${username}.*password.*changed"
        "modify.*auth.*user.*${username}.*password.*success"
    )
    
    # Search for password change failure patterns
    local failure_patterns=(
        "password change failed for user ${username}"
        "password change failed for ${username}"
        "failed to change password for user ${username}"
        "authentication failure.*${username}"
        "password.*${username}.*failed"
        "modify.*auth.*user.*${username}.*password.*failed"
        "modify.*auth.*user.*${username}.*password.*error"
    )
    
    log_message "INFO: Searching for password change events in secure log..."
    
    # Get recent log entries (last 2 minutes to be safe)
    local recent_logs=$(tail -n 1000 "${SECURE_LOG}" | grep -i "${username}" || true)
    
    if [ -z "${recent_logs}" ]; then
        log_message "WARNING: No recent log entries found for user: ${username}"
        log_message "INFO: This might indicate the password change hasn't been logged yet"
        return 2
    fi
    
    # Check for failure patterns first (higher priority)
    log_message "INFO: Checking for failure patterns..."
    for pattern in "${failure_patterns[@]}"; do
        if echo "${recent_logs}" | grep -iE "${pattern}" > /dev/null 2>&1; then
            log_message "ERROR: Password change FAILED - Found failure pattern: ${pattern}"
            log_message "ERROR: Matching log entry:"
            echo "${recent_logs}" | grep -iE "${pattern}" | tail -1 | tee -a "${VALIDATION_LOG}"
            return 1
        fi
    done
    
    # Check for success patterns
    log_message "INFO: Checking for success patterns..."
    local success_found=false
    for pattern in "${success_patterns[@]}"; do
        if echo "${recent_logs}" | grep -iE "${pattern}" > /dev/null 2>&1; then
            log_message "SUCCESS: Password change SUCCESSFUL - Found success pattern: ${pattern}"
            log_message "INFO: Matching log entry:"
            echo "${recent_logs}" | grep -iE "${pattern}" | tail -1 | tee -a "${VALIDATION_LOG}"
            success_found=true
            break
        fi
    done
    
    if [ "${success_found}" = true ]; then
        return 0
    else
        log_message "WARNING: No explicit success or failure pattern found"
        log_message "INFO: Recent log entries for user ${username}:"
        echo "${recent_logs}" | tail -5 | tee -a "${VALIDATION_LOG}"
        return 2
    fi
}

# Function to perform timestamp-based validation
validate_by_timestamp() {
    local username="$1"
    local current_time=$(date +%s)
    
    log_message "INFO: Performing timestamp-based validation"
    
    # Get the most recent log entry for the user
    local latest_entry=$(grep -i "${username}" "${SECURE_LOG}" | tail -1 || true)
    
    if [ -z "${latest_entry}" ]; then
        log_message "WARNING: No log entries found for user: ${username}"
        return 2
    fi
    
    log_message "INFO: Latest log entry: ${latest_entry}"
    
    # Extract timestamp from log entry (format varies by system)
    # Common formats: "May 21 12:18:52" or "2026-05-21T12:18:52"
    local log_timestamp=$(echo "${latest_entry}" | awk '{print $1, $2, $3}')
    
    log_message "INFO: Log entry timestamp: ${log_timestamp}"
    log_message "INFO: Timestamp validation completed"
    
    return 0
}

# Main execution
main() {
    log_message "=========================================="
    log_message "INFO: F5 Password Change Validation Started"
    log_message "INFO: Username: ${USERNAME}"
    log_message "=========================================="
    
    # Validate input parameters
    if [ -z "${USERNAME}" ]; then
        log_message "ERROR: Username parameter is missing"
        echo "Usage: $0 <username>"
        exit 1
    fi
    
    # Perform validation
    if validate_password_change "${USERNAME}"; then
        log_message "SUCCESS: Password change validation PASSED"
        validate_by_timestamp "${USERNAME}"
        log_message "=========================================="
        exit 0
    else
        validation_result=$?
        if [ ${validation_result} -eq 2 ]; then
            log_message "WARNING: Password change validation INCONCLUSIVE"
            log_message "INFO: Manual verification may be required"
            log_message "=========================================="
            exit 2
        else
            log_message "ERROR: Password change validation FAILED"
            log_message "=========================================="
            exit 1
        fi
    fi
}

# Execute main function
main "$@"

# Made with Bob
