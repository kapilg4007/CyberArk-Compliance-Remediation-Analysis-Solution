# CyberArk Compliance Remediation Analysis Solution

## Overview

Enterprise-grade PowerShell 5.1+ solution for automating CyberArk compliance remediation analysis and reconciliation readiness across CPM-managed accounts, integrated with IBM ICA (IBM Concert Automation) via Model Context Protocol (MCP).

## Features

- **Automated Compliance Analysis**: Process compliance and CMDB reports to identify remediation opportunities
- **Network Connectivity Testing**: Multi-port testing for Windows, Linux, and Unix systems
- **Reconcile Account Discovery**: Automatic identification of linked reconcile accounts via CyberArk PVWA REST API
- **IBM ICA Integration**: Leverage MCP for enhanced automation and orchestration capabilities
- **Comprehensive Reporting**: Excel workbooks with multiple analysis tabs and CSV exports
- **Enterprise Security**: No hardcoded credentials, secure token handling, audit logging
- **Scheduled Execution**: Designed for non-interactive scheduled task execution

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Input Sources                             │
├─────────────────────────────────────────────────────────────┤
│  Compliance Report (CSV)  │  CMDB Report (CSV)              │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│              PowerShell Processing Engine                    │
├─────────────────────────────────────────────────────────────┤
│  • CSV Validation & Import                                   │
│  • CyberArk PVWA REST API Integration                       │
│  • Network Connectivity Testing                              │
│  • Reconcile Account Discovery                               │
│  • CMDB Matching & Validation                                │
│  • Compliance Calculation                                    │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│              IBM ICA MCP Integration                         │
├─────────────────────────────────────────────────────────────┤
│  • Workflow Orchestration                                    │
│  • Event-Driven Automation                                   │
│  • Integration with Enterprise Systems                       │
│  • Advanced Analytics & Reporting                            │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    Output Reports                            │
├─────────────────────────────────────────────────────────────┤
│  • Excel Workbook (Multi-tab Analysis)                       │
│  • CSV Summary Reports                                       │
│  • Detailed Audit Logs                                       │
│  • Remediation Recommendations                               │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
cybeark-compliance-remediation/
├── README.md                           # This file
├── scripts/
│   ├── Invoke-CyberArkComplianceAnalysis.ps1  # Main script
│   └── Install-ScheduledTask.ps1       # Scheduled task setup
├── config/
│   ├── config.json                     # Configuration file
│   └── config.template.json            # Configuration template
├── sample-data/
│   ├── sample-compliance-report.csv    # Sample compliance data
│   └── sample-cmdb-report.csv          # Sample CMDB data
├── docs/
│   ├── SETUP.md                        # Setup instructions
│   ├── EXECUTION.md                    # Execution guide
│   ├── COMPLIANCE_FORMULAS.md          # Calculation formulas
│   └── API_REFERENCE.md                # CyberArk API reference
├── mcp-integration/
│   ├── mcp-config.json                 # MCP server configuration
│   ├── ibm-ica-integration.md          # IBM ICA integration guide
│   └── workflows/                      # MCP workflow definitions
├── output/                             # Generated reports (gitignored)
└── logs/                               # Log files (gitignored)
```

## Prerequisites

### Required
- PowerShell 5.1 or higher
- Windows Server 2016+ or Windows 10+
- Network access to CyberArk PVWA REST API
- Valid CyberArk authentication token
- Read access to compliance and CMDB reports

### Optional
- ImportExcel PowerShell module (for Excel output)
- IBM ICA environment (for MCP integration)
- MCP server setup (for advanced automation)

## Quick Start

### 1. Configuration

Copy the configuration template:
```powershell
Copy-Item config/config.template.json config/config.json
```

Edit `config/config.json` with your environment details:
```json
{
  "pvwaBaseUrl": "https://your-pvwa.company.com",
  "complianceReportPath": "C:/Reports/compliance.csv",
  "cmdbReportPath": "C:/Reports/cmdb.csv",
  "outputDirectory": "C:/Reports/Output",
  "logDirectory": "C:/Reports/Logs",
  "enableExcelOutput": true,
  "enableMCPIntegration": false
}
```

### 2. Secure Token Management

Set the CyberArk token as an environment variable:
```powershell
$env:CYBERARK_TOKEN = "your-secure-token-here"
```

Or use a secure credential file (recommended for scheduled tasks):
```powershell
# Create secure credential
$token = Read-Host "Enter CyberArk Token" -AsSecureString
$token | ConvertFrom-SecureString | Out-File "config/token.secure"
```

### 3. Run the Analysis

```powershell
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 -ConfigPath ".\config\config.json"
```

### 4. Review Output

Check the output directory for:
- `ComplianceAnalysis_YYYYMMDD_HHMMSS.xlsx` - Excel workbook with multiple tabs
- `RemediationSummary_YYYYMMDD_HHMMSS.csv` - CSV summary
- Detailed logs in the logs directory

## IBM ICA MCP Integration

### Overview

The solution integrates with IBM ICA (IBM Concert Automation) through the Model Context Protocol (MCP), enabling:

- **Automated Workflow Orchestration**: Trigger remediation workflows based on analysis results
- **Event-Driven Actions**: React to compliance status changes in real-time
- **Enterprise Integration**: Connect with ITSM, monitoring, and notification systems
- **Advanced Analytics**: Leverage IBM ICA's analytics capabilities for trend analysis

### Setup

1. **Install MCP Server**:
   ```powershell
   # Install Node.js dependencies for MCP server
   cd mcp-integration
   npm install
   ```

2. **Configure MCP Integration**:
   Edit `mcp-integration/mcp-config.json` with your IBM ICA details

3. **Enable MCP in Configuration**:
   ```json
   {
     "enableMCPIntegration": true,
     "mcpServerUrl": "http://localhost:3000",
     "ibmIcaEndpoint": "https://ica.company.com/api"
   }
   ```

4. **Start MCP Server**:
   ```powershell
   cd mcp-integration
   node server.js
   ```

See [IBM ICA Integration Guide](mcp-integration/ibm-ica-integration.md) for detailed setup instructions.

## Compliance Calculation Formulas

### Original Compliance Percentage
```
Original Compliance % = (Compliant CPM-managed accounts / Total CPM-managed accounts) × 100
```

### Failed CPM-managed Accounts
```
Failed CPM-managed Accounts = Total CPM-managed accounts - Compliant CPM-managed accounts
```

### Remediable Failed Accounts
Accounts that meet ALL criteria:
- Account exists in CyberArk
- Account is CPM-managed
- Target system is reachable (network connectivity confirmed)
- Associated reconcile account exists
- Reconcile account is usable (not disabled/locked)
- No blocking CMDB mismatch exists

### Projected Compliance Percentage
```
Projected Compliance % = ((Current compliant CPM-managed accounts + Remediable failed accounts) / Total CPM-managed accounts) × 100
```

### Projected Compliance Increase
```
Projected Compliance Increase % = Projected Compliance % - Original Compliance %
```

See [COMPLIANCE_FORMULAS.md](docs/COMPLIANCE_FORMULAS.md) for detailed examples.

## Output Reports

### Excel Workbook Tabs

1. **Executive Summary**: High-level metrics and compliance percentages
2. **Non-Compliant Accounts**: Detailed list of failed accounts
3. **Connectivity Results**: Network connectivity test results per host/port
4. **Reconcile Readiness**: Accounts ready for reconcile-based remediation
5. **CMDB Mismatches**: Discrepancies between CyberArk and CMDB
6. **Error Summary**: Categorized errors and failure reasons
7. **Compliance Improvement**: Projected improvement analysis

### CSV Outputs

- **RemediationSummary.csv**: Consolidated remediation recommendations
- **ConnectivityResults.csv**: Detailed connectivity test results
- **CMDBMismatches.csv**: CMDB validation failures

## Scheduled Task Setup

To run the analysis automatically:

```powershell
.\scripts\Install-ScheduledTask.ps1 `
    -TaskName "CyberArk Compliance Analysis" `
    -ScriptPath "C:\Scripts\Invoke-CyberArkComplianceAnalysis.ps1" `
    -ConfigPath "C:\Scripts\config\config.json" `
    -Schedule Daily `
    -StartTime "02:00"
```

See [EXECUTION.md](docs/EXECUTION.md) for advanced scheduling options.

## Security Considerations

- **No Hardcoded Credentials**: All sensitive data via secure parameters or environment variables
- **Token Encryption**: Use Windows DPAPI for token storage
- **Audit Logging**: All API calls and actions logged with timestamps
- **Least Privilege**: Script requires only read access to CyberArk API
- **Dry-Run by Default**: No automatic remediation actions without explicit approval
- **Secure Communication**: HTTPS/TLS for all API communications

## Troubleshooting

### Common Issues

1. **Token Authentication Failure**
   - Verify token is valid and not expired
   - Check PVWA URL is correct and accessible
   - Ensure token has required permissions

2. **Excel Output Not Generated**
   - Install ImportExcel module: `Install-Module -Name ImportExcel`
   - Or set `enableExcelOutput: false` for CSV-only mode

3. **Network Connectivity Tests Fail**
   - Verify firewall rules allow outbound connections
   - Check target systems are online
   - Ensure correct ports are configured

4. **MCP Integration Issues**
   - Verify MCP server is running
   - Check network connectivity to IBM ICA
   - Review MCP server logs

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed solutions.

## Support and Contribution

For issues, questions, or contributions, please refer to the project documentation or contact the CyberArk automation team.

## License

Enterprise Internal Use Only - Proprietary

## Version History

- **v1.0.0** (2026-05-27): Initial release with IBM ICA MCP integration
  - Core compliance analysis functionality
  - Network connectivity testing
  - Reconcile account discovery
  - Excel and CSV reporting
  - IBM ICA MCP integration
  - Scheduled task support