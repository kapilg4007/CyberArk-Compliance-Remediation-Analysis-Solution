# CyberArk Compliance Remediation Analysis - Setup Guide

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Steps](#installation-steps)
3. [Configuration](#configuration)
4. [Security Setup](#security-setup)
5. [IBM ICA MCP Integration Setup](#ibm-ica-mcp-integration-setup)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

**Operating System:**
- Windows Server 2016 or later
- Windows 10/11 (for development/testing)

**PowerShell:**
- PowerShell 5.1 or higher
- Execution policy: RemoteSigned or Bypass

**Network Access:**
- CyberArk PVWA REST API (HTTPS)
- Target systems for connectivity testing
- IBM ICA endpoint (if using MCP integration)

### Software Dependencies

**Required:**
- PowerShell 5.1+ (included in Windows)
- .NET Framework 4.7.2 or higher

**Optional:**
- ImportExcel PowerShell module (for Excel output)
- Node.js 18+ (for MCP server)
- npm or yarn (for MCP dependencies)

### Access Requirements

**CyberArk:**
- Valid CyberArk user account
- API access permissions
- Read access to target safes
- Auditor or higher role recommended

**IBM ICA (if using MCP):**
- IBM ICA instance access
- OAuth 2.0 client credentials
- Workflow creation permissions

**File System:**
- Read access to compliance and CMDB reports
- Write access to output and log directories
- Minimum 1GB free disk space

---

## Installation Steps

### Step 1: Download/Clone the Solution

```powershell
# If using Git
git clone https://github.com/your-org/cybeark-compliance-remediation.git
cd cybeark-compliance-remediation

# Or extract from ZIP archive
Expand-Archive -Path cybeark-compliance-remediation.zip -DestinationPath C:\Scripts\
cd C:\Scripts\cybeark-compliance-remediation
```

### Step 2: Verify Directory Structure

```powershell
# List directory structure
Get-ChildItem -Recurse -Directory | Select-Object FullName
```

Expected structure:
```
cybeark-compliance-remediation/
├── scripts/
├── config/
├── sample-data/
├── docs/
├── mcp-integration/
├── output/
└── logs/
```

### Step 3: Install Optional PowerShell Modules

**ImportExcel Module (for Excel output):**

```powershell
# Check if module is installed
Get-Module -ListAvailable -Name ImportExcel

# Install if not present
Install-Module -Name ImportExcel -Scope CurrentUser -Force

# Verify installation
Import-Module ImportExcel
Get-Command -Module ImportExcel
```

**Alternative: CSV-Only Mode**

If you cannot install ImportExcel, set `enableExcelOutput: false` in configuration.

### Step 4: Set Execution Policy

```powershell
# Check current execution policy
Get-ExecutionPolicy

# Set execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or for the entire machine (requires admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

## Configuration

### Step 1: Create Configuration File

```powershell
# Copy template to config.json
Copy-Item config/config.template.json config/config.json

# Open in editor
notepad config/config.json
```

### Step 2: Update Configuration Values

**Minimum Required Configuration:**

```json
{
  "pvwaBaseUrl": "https://pvwa.company.com",
  "complianceReportPath": "C:/Reports/compliance-report.csv",
  "cmdbReportPath": "C:/Reports/cmdb-report.csv",
  "outputDirectory": "C:/Reports/Output",
  "logDirectory": "C:/Reports/Logs",
  "enableExcelOutput": true,
  "enableMCPIntegration": false
}
```

**Configuration Parameters:**

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| pvwaBaseUrl | CyberArk PVWA URL | Yes | - |
| complianceReportPath | Path to compliance CSV | Yes | - |
| cmdbReportPath | Path to CMDB CSV | Yes | - |
| outputDirectory | Output reports directory | Yes | - |
| logDirectory | Log files directory | Yes | - |
| enableExcelOutput | Generate Excel reports | No | true |
| enableMCPIntegration | Enable IBM ICA MCP | No | false |
| mcpServerUrl | MCP server endpoint | No | http://localhost:3000 |
| maxRetries | API retry attempts | No | 3 |
| retryDelaySeconds | Delay between retries | No | 5 |

### Step 3: Create Required Directories

```powershell
# Create directories if they don't exist
$config = Get-Content config/config.json | ConvertFrom-Json

New-Item -ItemType Directory -Force -Path $config.outputDirectory
New-Item -ItemType Directory -Force -Path $config.logDirectory

# Verify directories
Test-Path $config.outputDirectory
Test-Path $config.logDirectory
```

---

## Security Setup

### Option 1: Environment Variable (Recommended for Testing)

```powershell
# Set token as environment variable
$env:CYBERARK_TOKEN = "your-cybeark-token-here"

# Verify
$env:CYBERARK_TOKEN
```

**Note:** Environment variables are session-specific and cleared on logout.

### Option 2: Secure File (Recommended for Production)

```powershell
# Create secure token file
$token = Read-Host "Enter CyberArk Token" -AsSecureString
$token | ConvertFrom-SecureString | Out-File "config/token.secure"

# Verify file created
Test-Path config/token.secure
```

**Security Notes:**
- Secure files use Windows DPAPI encryption
- Only the creating user can decrypt
- Suitable for scheduled tasks running as specific user

### Option 3: Parameter (Interactive Use Only)

```powershell
# Pass token as parameter
$secureToken = Read-Host "Enter Token" -AsSecureString
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json" `
    -CyberArkToken $secureToken
```

### Securing Configuration Files

```powershell
# Set restrictive permissions on config directory
$acl = Get-Acl config
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", "Allow"
)
$acl.AddAccessRule($rule)
Set-Acl config $acl

# Verify permissions
Get-Acl config | Format-List
```

---

## IBM ICA MCP Integration Setup

### Step 1: Install Node.js

**Download and Install:**
1. Visit https://nodejs.org/
2. Download LTS version (18.x or higher)
3. Run installer with default options
4. Verify installation:

```powershell
node --version
npm --version
```

### Step 2: Install MCP Server Dependencies

```powershell
cd mcp-integration

# Initialize npm (if package.json doesn't exist)
npm init -y

# Install dependencies
npm install @modelcontextprotocol/sdk express body-parser axios dotenv winston

# Verify installation
npm list
```

### Step 3: Configure MCP Server

**Create .env file:**

```powershell
# Create .env file
@"
IBM_ICA_ENDPOINT=https://ica.company.com/api/v1
IBM_ICA_CLIENT_ID=your-client-id
IBM_ICA_CLIENT_SECRET=your-client-secret
IBM_ICA_TOKEN_ENDPOINT=https://ica.company.com/oauth/token
MCP_SERVER_PORT=3000
LOG_LEVEL=info
"@ | Out-File -FilePath .env -Encoding UTF8
```

**Update mcp-config.json:**

```powershell
# Edit MCP configuration
notepad mcp-config.json
```

Update IBM ICA endpoints and credentials.

### Step 4: Test MCP Server

```powershell
# Start MCP server
npm start

# In another terminal, test health endpoint
Invoke-RestMethod -Uri "http://localhost:3000/api/health"
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2026-05-27T08:00:00.000Z"
}
```

### Step 5: Enable MCP in Configuration

```powershell
# Update config.json
$config = Get-Content config/config.json | ConvertFrom-Json
$config.enableMCPIntegration = $true
$config.mcpServerUrl = "http://localhost:3000"
$config | ConvertTo-Json -Depth 10 | Out-File config/config.json
```

---

## Verification

### Test 1: Configuration Validation

```powershell
# Test configuration loading
$config = Get-Content config/config.json | ConvertFrom-Json
Write-Host "PVWA URL: $($config.pvwaBaseUrl)"
Write-Host "Output Directory: $($config.outputDirectory)"
```

### Test 2: Sample Data Test

```powershell
# Run with sample data
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json" `
    -DryRun $true
```

**Note:** Update config.json to point to sample-data CSV files for testing.

### Test 3: Network Connectivity

```powershell
# Test PVWA connectivity
$pvwaUrl = "https://pvwa.company.com"
Test-NetConnection -ComputerName ([System.Uri]$pvwaUrl).Host -Port 443

# Test MCP server (if enabled)
Test-NetConnection -ComputerName localhost -Port 3000
```

### Test 4: Token Validation

```powershell
# Test CyberArk token
$token = $env:CYBERARK_TOKEN
$headers = @{
    'Authorization' = $token
    'Content-Type' = 'application/json'
}

try {
    $response = Invoke-RestMethod `
        -Uri "https://pvwa.company.com/PasswordVault/api/Accounts?limit=1" `
        -Method GET `
        -Headers $headers
    Write-Host "Token is valid" -ForegroundColor Green
}
catch {
    Write-Host "Token validation failed: $_" -ForegroundColor Red
}
```

### Test 5: Output Generation

```powershell
# Check if output files are created
Get-ChildItem $config.outputDirectory -Filter "*.csv"
Get-ChildItem $config.outputDirectory -Filter "*.xlsx"
Get-ChildItem $config.logDirectory -Filter "*.log"
```

---

## Troubleshooting

### Issue: PowerShell Execution Policy Error

**Error:**
```
File cannot be loaded because running scripts is disabled on this system
```

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: ImportExcel Module Not Found

**Error:**
```
The term 'Export-Excel' is not recognized
```

**Solution:**
```powershell
Install-Module -Name ImportExcel -Scope CurrentUser -Force
Import-Module ImportExcel
```

**Alternative:** Disable Excel output in config.json

### Issue: CyberArk Token Authentication Failed

**Error:**
```
401 Unauthorized
```

**Solutions:**
1. Verify token is valid and not expired
2. Check token format (should include "Bearer" prefix if required)
3. Verify PVWA URL is correct
4. Ensure user has API access permissions

### Issue: Network Connectivity Test Fails

**Error:**
```
Test-NetConnection: Cannot resolve hostname
```

**Solutions:**
1. Verify DNS resolution
2. Check firewall rules
3. Ensure target systems are online
4. Verify correct ports are being tested

### Issue: MCP Server Won't Start

**Error:**
```
Error: Cannot find module '@modelcontextprotocol/sdk'
```

**Solution:**
```powershell
cd mcp-integration
npm install
```

### Issue: Output Directory Access Denied

**Error:**
```
Access to the path is denied
```

**Solutions:**
1. Verify directory exists
2. Check write permissions
3. Run PowerShell as administrator (if needed)
4. Update directory path in config.json

### Issue: CSV Import Fails

**Error:**
```
Missing required columns in compliance report
```

**Solutions:**
1. Verify CSV file format
2. Check column names match expected schema
3. Ensure CSV is UTF-8 encoded
4. Remove any BOM (Byte Order Mark) from CSV

---

## Next Steps

After successful setup:

1. **Review Documentation:**
   - [EXECUTION.md](EXECUTION.md) - Running the analysis
   - [COMPLIANCE_FORMULAS.md](COMPLIANCE_FORMULAS.md) - Understanding metrics
   - [IBM ICA Integration Guide](../mcp-integration/ibm-ica-integration.md)

2. **Schedule Automated Execution:**
   ```powershell
   .\scripts\Install-ScheduledTask.ps1 `
       -TaskName "CyberArk Compliance Analysis" `
       -ScriptPath "C:\Scripts\Invoke-CyberArkComplianceAnalysis.ps1" `
       -ConfigPath "C:\Scripts\config\config.json" `
       -Schedule Daily `
       -StartTime "02:00"
   ```

3. **Monitor and Optimize:**
   - Review log files regularly
   - Adjust retry settings if needed
   - Fine-tune network connectivity timeouts
   - Monitor MCP server performance

---

## Support

For assistance:
- **Documentation:** Review all files in `/docs` directory
- **Logs:** Check log files in configured log directory
- **Internal Support:** Contact CyberArk automation team
- **IBM ICA Support:** Refer to IBM ICA documentation

---

## Version History

- **v1.0.0** (2026-05-27): Initial setup guide
  - Installation instructions
  - Configuration steps
  - Security setup
  - IBM ICA MCP integration
  - Verification procedures
  - Troubleshooting guide