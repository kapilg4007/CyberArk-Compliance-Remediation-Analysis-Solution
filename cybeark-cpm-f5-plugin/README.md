# CyberArk CPM Plugin for F5 BigIP

## Overview

This CyberArk Central Password Manager (CPM) plugin enables automated password management for F5 BigIP devices. The plugin is designed similar to the SSH plugin for Unix devices but includes F5-specific password reconciliation commands and validation mechanisms.

## Features

- **SSH-based Connection**: Uses standard SSH protocol for secure communication
- **F5-Specific Reconcile Command**: Implements the F5 `modify /auth user` command for password changes
- **Timestamp-based Validation**: Validates password changes by checking `/var/log/secure` log file
- **Automated Verification**: Automatically verifies new password by attempting login
- **Error Handling**: Comprehensive error detection and reporting

## Components

### 1. PromptFile.xml
Defines the connection prompts and expected responses for F5 devices:
- Login prompts (username/password)
- Command prompts (shell and TMSH)
- Error detection patterns
- Reconcile, Change, Verify, and Logoff prompts

### 2. ProcessFile.xml
Defines the password management processes:
- **Reconcile Process**: Changes password using F5 command
- **Change Process**: Alternative password change method
- **Verify Process**: Validates new password by reconnecting
- **Logoff Process**: Cleanly disconnects from device

### 3. Scripts

#### reconcile_f5.sh
Main reconciliation script that:
- Executes the F5 password change command: `modify /auth user <username> password <newpassword>`
- Records timestamps before and after execution
- Logs all operations for audit purposes

#### validate_f5_change.sh
Validation script that:
- Checks `/var/log/secure` for password change events
- Uses timestamp-based validation (60-second tolerance window)
- Searches for success/failure patterns in logs
- Returns appropriate exit codes based on validation results

## Installation

### Prerequisites
- CyberArk Password Vault v12.0 or higher
- CyberArk CPM installed and configured
- SSH access to F5 BigIP devices
- Appropriate permissions on F5 devices

### Installation Steps

1. **Copy Plugin Files**
   ```bash
   # Copy to CPM plugin directory
   cp -r cybeark-cpm-f5-plugin /opt/CARKaim/Vault/Plugins/F5-BigIP/
   ```

2. **Set Script Permissions**
   ```bash
   chmod +x /opt/CARKaim/Vault/Plugins/F5-BigIP/scripts/*.sh
   ```

3. **Configure Platform in PVWA**
   - Log in to PVWA (Password Vault Web Access)
   - Navigate to: Administration → Platform Management
   - Click "Import Platform"
   - Select the F5-BigIP platform files
   - Configure platform properties:
     - Name: F5-BigIP
     - System Type: Unix
     - Connection Component: SSH
     - Reconcile Account: Enable

4. **Create Safe and Add Accounts**
   - Create a Safe for F5 accounts
   - Add F5 device accounts with:
     - Address: F5 device IP/hostname
     - Username: F5 user account
     - Platform: F5-BigIP

## Configuration

### F5 Device Requirements

1. **SSH Access**
   - Ensure SSH is enabled on F5 device
   - Default port: 22 (configurable in ProcessFile.xml)

2. **User Permissions**
   - The reconcile account must have permissions to:
     - Execute `modify /auth user` commands
     - Read `/var/log/secure` log file

3. **Logging Configuration**
   - Ensure `/var/log/secure` is configured to log authentication events
   - Verify log rotation doesn't interfere with validation window

### Plugin Configuration

#### Connection Settings (ProcessFile.xml)
```xml
<ConnectionSettings>
    <Protocol>SSH</Protocol>
    <Port>22</Port>
    <ConnectionTimeout>60</ConnectionTimeout>
    <CommandTimeout>30</CommandTimeout>
    <MaxRetries>3</MaxRetries>
    <RetryInterval>5</RetryInterval>
</ConnectionSettings>
```

#### Validation Settings (ProcessFile.xml)
```xml
<ValidationSettings>
    <LogFile>/var/log/secure</LogFile>
    <ValidateByTimestamp>true</ValidateByTimestamp>
    <TimestampTolerance>60</TimestampTolerance>
    <SuccessPattern>password changed for user</SuccessPattern>
    <FailurePattern>password change failed|authentication failure</FailurePattern>
</ValidationSettings>
```

## Usage

### Reconcile Process Flow

1. **Connection**
   - CPM connects to F5 device via SSH
   - Authenticates using reconcile account credentials

2. **Password Change**
   - Executes: `modify /auth user <username> password <newpassword>`
   - Records execution timestamp

3. **Validation**
   - Checks `/var/log/secure` for password change events
   - Validates using timestamp (within 60-second window)
   - Searches for success/failure patterns

4. **Verification**
   - Disconnects current session
   - Reconnects using new password
   - Confirms successful authentication

5. **Completion**
   - Logs out from device
   - Reports success/failure to CPM

### Manual Testing

Test the reconcile script manually:
```bash
# Test reconcile
./scripts/reconcile_f5.sh testuser newpassword123

# Test validation
./scripts/validate_f5_change.sh testuser
```

## Troubleshooting

### Common Issues

1. **Connection Timeout**
   - Verify SSH connectivity: `ssh user@f5-device`
   - Check firewall rules
   - Increase ConnectionTimeout in ProcessFile.xml

2. **Authentication Failed**
   - Verify reconcile account credentials
   - Check user permissions on F5 device
   - Review `/var/log/secure` for authentication errors

3. **Validation Failed**
   - Check if `/var/log/secure` is readable
   - Verify log format matches expected patterns
   - Increase TimestampTolerance if needed

4. **Command Execution Failed**
   - Verify user has permission to modify passwords
   - Check F5 password policy compliance
   - Review F5 audit logs

### Log Files

- **CPM Logs**: `/var/opt/CARKaim/Logs/CPM/`
- **Plugin Logs**: `/var/log/cybeark_f5_reconcile.log`
- **Validation Logs**: `/var/log/cybeark_f5_validation.log`
- **F5 Secure Log**: `/var/log/secure`

### Debug Mode

Enable debug logging in ProcessFile.xml:
```xml
<DebugMode>true</DebugMode>
```

## F5 Command Reference

### Password Change Command
```bash
modify /auth user <username> password <newpassword>
```

### Verify User
```bash
list /auth user <username>
```

### Check Logs
```bash
tail -f /var/log/secure | grep <username>
```

## Security Considerations

1. **Secure Communication**
   - All communication uses SSH encryption
   - Passwords are never logged in plain text

2. **Audit Trail**
   - All operations are logged with timestamps
   - F5 device logs all password changes

3. **Access Control**
   - Reconcile account should have minimal required permissions
   - Use dedicated service account for CPM operations

4. **Password Policy**
   - Ensure CyberArk password policy matches F5 requirements
   - Configure appropriate complexity rules

## Support

For issues or questions:
- Review CyberArk CPM documentation: https://docs.cyberark.com
- Check F5 BigIP documentation
- Contact CyberArk support

## Version History

- **v1.0.0** (2026-05-21)
  - Initial release
  - SSH-based connection
  - F5-specific reconcile command
  - Timestamp-based validation
  - Log file validation support

## License

This plugin is provided as-is for use with CyberArk Password Vault.

## References

- [CyberArk CPM SDK - Prompts](https://docs.cyberark.com/pam-self-hosted/14.2/en/content/sdk/tpc-promps.htm)
- [CyberArk CPM SDK - Process](https://docs.cyberark.com/pam-self-hosted/14.2/en/content/sdk/tpc-process.htm)
- [F5 BigIP Documentation](https://support.f5.com/)