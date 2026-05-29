#!/bin/bash
################################################################################
# CyberArk CPM F5 Reconcile Script
# Description: Reconciles F5 user password using the modify command
# Usage: Called by CyberArk CPM during reconcile process
################################################################################

# Exit on error
set -e

# Variables passed by CyberArk CPM
USERNAME="${1}"
NEW_PASSWORD="${2}"
LOG_FILE="/var/log/cybeark_f5_reconcile.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Function to execute F5 password change command
execute_password_change() {
    local username="$1"
    local new_password="$2"
    
    log_message "INFO: Starting password reconcile for user: ${username}"
    
    # Record timestamp before command execution
    TIMESTAMP_BEFORE=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Execute F5 password change command
    # The command format: modify /auth user <username> password <newpassword>
    log_message "INFO: Executing F5 password change command"
    
    # Execute the command
    if modify /auth user "${username}" password "${new_password}"; then
        log_message "INFO: F5 password change command executed successfully"
        COMMAND_EXIT_CODE=0
    else
        COMMAND_EXIT_CODE=$?
        log_message "ERROR: F5 password change command failed with exit code: ${COMMAND_EXIT_CODE}"
        return ${COMMAND_EXIT_CODE}
    fi
    
    # Record timestamp after command execution
    TIMESTAMP_AFTER=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_message "INFO: Command execution completed. Exit code: ${COMMAND_EXIT_CODE}"
    log_message "INFO: Timestamp before: ${TIMESTAMP_BEFORE}"
    log_message "INFO: Timestamp after: ${TIMESTAMP_AFTER}"
    
    return ${COMMAND_EXIT_CODE}
}

# Main execution
main() {
    log_message "=========================================="
    log_message "INFO: F5 Password Reconcile Script Started"
    log_message "INFO: Username: ${USERNAME}"
    log_message "=========================================="
    
    # Validate input parameters
    if [ -z "${USERNAME}" ]; then
        log_message "ERROR: Username parameter is missing"
        exit 1
    fi
    
    if [ -z "${NEW_PASSWORD}" ]; then
        log_message "ERROR: New password parameter is missing"
        exit 1
    fi
    
    # Execute password change
    if execute_password_change "${USERNAME}" "${NEW_PASSWORD}"; then
        log_message "INFO: Password reconcile completed successfully"
        log_message "INFO: Proceeding to validation phase"
        exit 0
    else
        log_message "ERROR: Password reconcile failed"
        exit 1
    fi
}

# Execute main function
main "$@"

# Made with Bob
