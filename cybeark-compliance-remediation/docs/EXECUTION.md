# CyberArk Compliance Remediation Analysis - Execution Guide

## Table of Contents

1. [Quick Start](#quick-start)
2. [Execution Modes](#execution-modes)
3. [Command-Line Parameters](#command-line-parameters)
4. [Execution Examples](#execution-examples)
5. [Understanding Output](#understanding-output)
6. [Scheduled Execution](#scheduled-execution)
7. [Monitoring and Logging](#monitoring-and-logging)
8. [Best Practices](#best-practices)

---

## Quick Start

### Basic Execution

```powershell
# Navigate to script directory
cd C:\Scripts\cybeark-compliance-remediation

# Run analysis
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 -ConfigPath ".\config\config.json"
```

### Prerequisites Checklist

Before running:
- ✓ Configuration file created and updated
- ✓ CyberArk token available (environment variable or secure file)
- ✓ Compliance and CMDB reports available
- ✓ Output and log directories exist
- ✓ Network access to PVWA and target systems

---

## Execution Modes

### 1. Dry-Run Mode (Default)

**Purpose:** Analysis only, no changes made

```powershell
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json" `
    -DryRun $true
```

**Behavior:**
- Analyzes compliance data
- Tests network connectivity
- Identifies remediable accounts
- Generates reports
- **Does NOT trigger any remediation actions**

**Use When:**
- First-time execution
- Testing configuration
- Regular compliance reporting
- Audit purposes

### 2. Production Mode

**Purpose:** Full analysis with optional remediation

```powershell
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json" `
    -DryRun $false
```

**Note:** Current implementation is analysis-only. Actual remediation requires additional approval workflows.

### 3. MCP Integration Mode

**Purpose:** Analysis with IBM ICA workflow integration

```powershell
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json" `
    -EnableMCP $true
```

**Behavior:**
- Performs full analysis
- Sends results to MCP server
- Triggers IBM ICA workflows (if configured)
- Sends notifications

**Prerequisites:**
- MCP server running
- IBM ICA configured
- MCP integration enabled in config

---

## Command-Line Parameters

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-ConfigPath` | String | Path to configuration JSON file |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-CyberArkToken` | SecureString | (from env/file) | CyberArk authentication token |
| `-DryRun` | Boolean | `$true` | Run in dry-run mode |
| `-EnableMCP` | Boolean | `$false` | Enable MCP integration |

### Parameter Examples

**Specify Token Directly:**
```powershell
$token = Read-Host "Enter Token" -AsSecureString
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json" `
    -CyberArkToken $token
```

**Override MCP Setting:**
```powershell
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json" `
    -EnableMCP $true
```

---

## Execution Examples

### Example 1: First-Time Execution

```powershell
# Set token
$env:CYBERARK_TOKEN = "your-token-here"

# Run with sample data
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json" `
    -DryRun $true

# Review output
Get-ChildItem .\output\
Get-Content .\logs\ComplianceAnalysis_*.log -Tail 50
```

### Example 2: Production Execution

```powershell
# Ensure token is available
if (-not $env:CYBERARK_TOKEN) {
    Write-Host "Token not found. Loading from secure file..."
    $encryptedToken = Get-Content config\token.secure
    $secureToken = ConvertTo-SecureString -String $encryptedToken
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    $env:CYBERARK_TOKEN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

# Run analysis
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json"
```

### Example 3: With MCP Integration

```powershell
# Start MCP server (in separate terminal)
cd mcp-integration
npm start

# Run analysis with MCP
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json" `
    -EnableMCP $true
```

### Example 4: Scheduled Task Execution

```powershell
# Install scheduled task
.\scripts\Install-ScheduledTask.ps1 `
    -TaskName "CyberArk Compliance Analysis" `
    -ScriptPath "C:\Scripts\cybeark-compliance-remediation\scripts\Invoke-CyberArkComplianceAnalysis.ps1" `
    -ConfigPath "C:\Scripts\cybeark-compliance-remediation\config\config.json" `
    -Schedule Daily `
    -StartTime "02:00"

# Verify task
Get-ScheduledTask -TaskName "CyberArk Compliance Analysis"

# Test run
Start-ScheduledTask -TaskName "CyberArk Compliance Analysis"
```

### Example 5: Multiple Environment Execution

```powershell
# Production environment
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config-prod.json"

# Development environment
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config-dev.json"

# Test environment
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config-test.json"
```

---

## Understanding Output

### Console Output

**Execution Start:**
```
========================================
CyberArk Compliance Remediation Analysis
========================================

[2026-05-27 08:00:00.000] [INFO] [Config] Importing configuration from: .\config\config.json
[2026-05-27 08:00:00.100] [SUCCESS] [Config] Configuration imported successfully
[2026-05-27 08:00:00.200] [SUCCESS] Logging initialized
```

**Progress Updates:**
```
[2026-05-27 08:00:05.000] [INFO] [DataImport] Importing compliance report from: C:/Reports/compliance.csv
[2026-05-27 08:00:05.500] [SUCCESS] [DataImport] Compliance report imported successfully. Records: 20
[2026-05-27 08:00:06.000] [INFO] [Analysis] Starting compliance analysis
[2026-05-27 08:00:06.100] [INFO] [Analysis] Total CPM-managed accounts to analyze: 20
[2026-05-27 08:00:10.000] [INFO] [Analysis] Progress: 10 / 20 accounts processed
```

**Completion Summary:**
```
========================================
Analysis Complete
========================================

Compliance Metrics:
  Total CPM-Managed Accounts: 20
  Compliant Accounts: 11
  Failed Accounts: 9
  Remediable Failed Accounts: 5
  Original Compliance: 55.00%
  Projected Compliance: 80.00%
  Projected Increase: +25.00%

Output Files:
  CSV Reports: C:/Reports/Output
  Excel Report: C:/Reports/Output/ComplianceAnalysis_20260527_080015.xlsx
  Log File: C:/Reports/Logs/ComplianceAnalysis_20260527_080000.log
  Transcript: C:/Reports/Logs/Transcript_20260527_080000.txt

Execution Time: 00:02:15
```

### Output Files

#### 1. Excel Workbook

**File:** `ComplianceAnalysis_YYYYMMDD_HHMMSS.xlsx`

**Tabs:**
- **Executive Summary:** High-level metrics
- **Non-Compliant Accounts:** Detailed failure list
- **Connectivity Results:** Network test results
- **Reconcile Readiness:** Remediable accounts
- **CMDB Mismatches:** Data discrepancies
- **Error Summary:** Categorized errors
- **Compliance Improvement:** Projection analysis

#### 2. CSV Reports

**RemediationSummary_YYYYMMDD_HHMMSS.csv:**
```csv
AccountID,AccountName,SafeName,PlatformID,Address,ComplianceStatus,IsRemediable,RemediationRecommendation
ACC002,WinServer02-Admin,Windows-Servers,WinServerLocal,winserver02.company.com,Non-Compliant,True,"REMEDIABLE: Retry password management using reconcile account 'WinServer02-Reconcile'"
```

**ConnectivityResults_YYYYMMDD_HHMMSS.csv:**
```csv
AccountID,AccountName,Address,TargetHost,Port,IsReachable,ResponseTime,TestTimestamp
ACC002,WinServer02-Admin,winserver02.company.com,winserver02.company.com,135,True,15,2026-05-27 08:00:10
```

**CMDBMismatches_YYYYMMDD_HHMMSS.csv:**
```csv
AccountID,AccountName,Address,Mismatches
ACC007,WinDB01-SQLAdmin,windb01.company.com,"System marked as inactive in CMDB"
```

**ComplianceMetrics_YYYYMMDD_HHMMSS.csv:**
```csv
TotalCPMManagedAccounts,CompliantAccounts,FailedAccounts,RemediableFailedAccounts,NonRemediableFailedAccounts,OriginalCompliancePercent,ProjectedCompliantAccounts,ProjectedCompliancePercent,ProjectedComplianceIncrease
20,11,9,5,4,55.00,16,80.00,25.00
```

#### 3. Log Files

**ComplianceAnalysis_YYYYMMDD_HHMMSS.log:**
```
[2026-05-27 08:00:00.000] [INFO] [Main] [CorrelationId: abc-123] Script execution started
[2026-05-27 08:00:05.000] [DEBUG] [API] [CorrelationId: abc-123] API Call: GET /PasswordVault/api/Accounts/ACC002
[2026-05-27 08:00:05.500] [SUCCESS] [API] [CorrelationId: abc-123] API call successful
```

**Transcript_YYYYMMDD_HHMMSS.txt:**
- Complete PowerShell session transcript
- All console output
- Error messages and stack traces

---

## Scheduled Execution

### Setup Scheduled Task

```powershell
.\scripts\Install-ScheduledTask.ps1 `
    -TaskName "CyberArk Compliance Analysis" `
    -ScriptPath "C:\Scripts\cybeark-compliance-remediation\scripts\Invoke-CyberArkComplianceAnalysis.ps1" `
    -ConfigPath "C:\Scripts\cybeark-compliance-remediation\config\config.json" `
    -Schedule Daily `
    -StartTime "02:00" `
    -RunAsUser "SYSTEM"
```

### Schedule Options

**Daily Execution:**
```powershell
-Schedule Daily -StartTime "02:00"
```

**Weekly Execution:**
```powershell
-Schedule Weekly -StartTime "03:00" -DaysOfWeek "Monday,Thursday"
```

**Monthly Execution:**
```powershell
-Schedule Monthly -StartTime "01:00"
```

### Managing Scheduled Tasks

**View Task:**
```powershell
Get-ScheduledTask -TaskName "CyberArk Compliance Analysis" | Format-List *
```

**Run Task Manually:**
```powershell
Start-ScheduledTask -TaskName "CyberArk Compliance Analysis"
```

**Check Task History:**
```powershell
Get-ScheduledTask -TaskName "CyberArk Compliance Analysis" | Get-ScheduledTaskInfo
```

**Disable Task:**
```powershell
Disable-ScheduledTask -TaskName "CyberArk Compliance Analysis"
```

**Enable Task:**
```powershell
Enable-ScheduledTask -TaskName "CyberArk Compliance Analysis"
```

**Remove Task:**
```powershell
Unregister-ScheduledTask -TaskName "CyberArk Compliance Analysis" -Confirm:$false
```

---

## Monitoring and Logging

### Real-Time Monitoring

**Monitor Log File:**
```powershell
Get-Content C:\Reports\Logs\ComplianceAnalysis_*.log -Wait -Tail 50
```

**Monitor Transcript:**
```powershell
Get-Content C:\Reports\Logs\Transcript_*.txt -Wait -Tail 50
```

### Log Analysis

**Search for Errors:**
```powershell
Select-String -Path "C:\Reports\Logs\*.log" -Pattern "\[ERROR\]" | Select-Object -Last 20
```

**Count API Calls:**
```powershell
(Select-String -Path "C:\Reports\Logs\*.log" -Pattern "API Call").Count
```

**Find Specific Account:**
```powershell
Select-String -Path "C:\Reports\Logs\*.log" -Pattern "ACC002"
```

### Performance Metrics

**Execution Time:**
```powershell
$log = Get-Content "C:\Reports\Logs\ComplianceAnalysis_*.log" -Raw
if ($log -match "Execution Time: (\d{2}:\d{2}:\d{2})") {
    Write-Host "Execution Time: $($matches[1])"
}
```

**Accounts Processed:**
```powershell
$log = Get-Content "C:\Reports\Logs\ComplianceAnalysis_*.log" -Raw
if ($log -match "Total accounts analyzed: (\d+)") {
    Write-Host "Accounts Processed: $($matches[1])"
}
```

### Log Retention

**Clean Old Logs (90+ days):**
```powershell
$retentionDays = 90
$cutoffDate = (Get-Date).AddDays(-$retentionDays)

Get-ChildItem "C:\Reports\Logs" -Filter "*.log" | 
    Where-Object { $_.LastWriteTime -lt $cutoffDate } |
    Remove-Item -Force

Get-ChildItem "C:\Reports\Logs" -Filter "*.txt" | 
    Where-Object { $_.LastWriteTime -lt $cutoffDate } |
    Remove-Item -Force
```

---

## Best Practices

### 1. Pre-Execution Checks

```powershell
# Verify configuration
Test-Path ".\config\config.json"

# Check token availability
if ($env:CYBERARK_TOKEN) {
    Write-Host "Token available" -ForegroundColor Green
} else {
    Write-Host "Token not found" -ForegroundColor Red
}

# Verify input files exist
$config = Get-Content ".\config\config.json" | ConvertFrom-Json
Test-Path $config.complianceReportPath
Test-Path $config.cmdbReportPath

# Check disk space
$drive = (Get-Item $config.outputDirectory).PSDrive
$freeSpace = [math]::Round($drive.Free / 1GB, 2)
Write-Host "Free space: $freeSpace GB"
```

### 2. Error Handling

**Wrap Execution in Try-Catch:**
```powershell
try {
    .\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
        -ConfigPath ".\config\config.json"
}
catch {
    Write-Host "Execution failed: $_" -ForegroundColor Red
    
    # Send alert email
    Send-MailMessage `
        -To "admin@company.com" `
        -From "cybeark-automation@company.com" `
        -Subject "CyberArk Compliance Analysis Failed" `
        -Body "Error: $_" `
        -SmtpServer "smtp.company.com"
}
```

### 3. Regular Maintenance

**Weekly Tasks:**
- Review log files for errors
- Verify scheduled task execution
- Check output file generation
- Monitor disk space usage

**Monthly Tasks:**
- Review compliance trends
- Update configuration if needed
- Rotate logs (if not automated)
- Test token validity

**Quarterly Tasks:**
- Review and update CMDB data
- Validate network connectivity rules
- Update documentation
- Review IBM ICA workflows

### 4. Security Best Practices

**Token Management:**
- Rotate tokens regularly (every 90 days)
- Never log tokens in plain text
- Use secure storage methods
- Limit token permissions to minimum required

**Access Control:**
- Restrict script directory permissions
- Limit scheduled task execution to service accounts
- Audit configuration changes
- Monitor log access

**Data Protection:**
- Encrypt sensitive output files
- Secure log files
- Implement data retention policies
- Regular backup of configuration

### 5. Performance Optimization

**For Large Environments (1000+ accounts):**
```json
{
  "networkConnectivity": {
    "parallelTests": true,
    "maxConcurrentTests": 20
  },
  "maxRetries": 2,
  "retryDelaySeconds": 3
}
```

**For Slow Networks:**
```json
{
  "apiTimeoutSeconds": 60,
  "networkConnectivity": {
    "testTimeout": 10
  }
}
```

---

## Troubleshooting Execution Issues

### Issue: Script Hangs During Execution

**Symptoms:**
- No console output for extended period
- Log file not updating

**Solutions:**
1. Check network connectivity to PVWA
2. Verify target systems are responsive
3. Review API timeout settings
4. Check for locked files in output directory

### Issue: Incomplete Results

**Symptoms:**
- Missing accounts in output
- Partial Excel workbook

**Solutions:**
1. Review log file for errors
2. Check API rate limiting
3. Verify all input data is valid
4. Increase retry attempts in configuration

### Issue: High Memory Usage

**Symptoms:**
- PowerShell process consuming excessive memory
- System slowdown

**Solutions:**
1. Process accounts in batches
2. Reduce concurrent network tests
3. Clear variables periodically
4. Restart PowerShell session

---

## Support and Resources

**Documentation:**
- [SETUP.md](SETUP.md) - Initial setup
- [COMPLIANCE_FORMULAS.md](COMPLIANCE_FORMULAS.md) - Calculation details
- [IBM ICA Integration](../mcp-integration/ibm-ica-integration.md)

**Log Locations:**
- Execution logs: `<logDirectory>/ComplianceAnalysis_*.log`
- Transcripts: `<logDirectory>/Transcript_*.txt`
- MCP logs: `mcp-integration/logs/mcp-server.log`

**Contact:**
- Internal Support: cybeark-automation-team@company.com
- CyberArk Documentation: https://docs.cyberark.com
- IBM ICA Support: https://www.ibm.com/docs/ica

---

## Version History

- **v1.0.0** (2026-05-27): Initial execution guide
  - Quick start instructions
  - Execution modes
  - Parameter reference
  - Output documentation
  - Monitoring guidance
  - Best practices