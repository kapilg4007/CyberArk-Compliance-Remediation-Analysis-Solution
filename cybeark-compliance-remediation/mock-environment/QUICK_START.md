# Mock Environment Quick Start Guide

## Overview

This guide helps you test the CyberArk Compliance Remediation solution without a real CyberArk environment using our mock API server and sample data.

## What's Included

- ✅ Mock CyberArk PVWA REST API server
- ✅ Sample compliance report (20 accounts)
- ✅ Sample CMDB report (20 assets)
- ✅ Pre-configured test configuration
- ✅ Sample output files
- ✅ Interactive HTML dashboard

## Quick Start (3 Steps)

### Step 1: Start Mock API Server

Open PowerShell terminal #1:

```powershell
cd cybeark-compliance-remediation/mock-environment
.\mock-cybeark-api.ps1 -Port 8080
```

You should see:
```
Mock CyberArk API Server started on http://localhost:8080
Press Ctrl+C to stop the server
```

**Keep this terminal running!**

### Step 2: Run Compliance Analysis

Open PowerShell terminal #2:

```powershell
cd cybeark-compliance-remediation/mock-environment

# Set mock token
$env:CYBERARK_TOKEN = "mock-token-12345"

# Run analysis
..\scripts\Invoke-CyberArkComplianceAnalysis.ps1 -ConfigPath ".\config-mock.json"
```

### Step 3: View Dashboard

Open the dashboard in your browser:

```powershell
# Windows
start ..\dashboard\index.html

# Or navigate to:
# file:///C:/path/to/cybeark-compliance-remediation/dashboard/index.html
```

**That's it!** 🎉

## Expected Results

### Console Output

```
========================================
CyberArk Compliance Remediation Analysis
========================================

[2026-05-27 08:00:00] [SUCCESS] Configuration imported successfully
[2026-05-27 08:00:00] [SUCCESS] Logging initialized
[2026-05-27 08:00:05] [SUCCESS] Compliance report imported successfully. Records: 20
[2026-05-27 08:00:06] [SUCCESS] CMDB report imported successfully. Records: 20
[2026-05-27 08:00:10] [INFO] Starting compliance analysis
[2026-05-27 08:00:15] [INFO] Progress: 10 / 20 accounts processed
[2026-05-27 08:00:20] [INFO] Progress: 20 / 20 accounts processed
[2026-05-27 08:00:25] [SUCCESS] Compliance analysis completed

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
  CSV Reports: ../output
  Log File: ../logs/ComplianceAnalysis_20260527_080000.log
  Transcript: ../logs/Transcript_20260527_080000.txt

Execution Time: 00:00:25
```

### Generated Files

```
output/
├── RemediationSummary_20260527_080000.csv
├── ConnectivityResults_20260527_080000.csv
├── CMDBMismatches_20260527_080000.csv
└── ComplianceMetrics_20260527_080000.csv

logs/
├── ComplianceAnalysis_20260527_080000.log
└── Transcript_20260527_080000.txt
```

### Dashboard View

The dashboard will show:

**Metrics:**
- 📊 Total CPM-Managed: 20
- ✅ Compliant: 11 (55%)
- ❌ Failed: 9 (45%)
- 🔧 Remediable: 5 (55% of failed)
- 📈 Projected: 80% (+25%)

**Charts:**
- Compliance overview (doughnut)
- Projection comparison (bar)
- Remediation breakdown (pie)
- Platform distribution (bar)

**Table:**
- 20 accounts with full details
- Filterable by status/platform
- Searchable
- Remediation buttons

## Detailed Testing Scenarios

### Scenario 1: Basic Analysis

Test the core functionality:

```powershell
# Run with default settings
$env:CYBERARK_TOKEN = "mock-token"
..\scripts\Invoke-CyberArkComplianceAnalysis.ps1 -ConfigPath ".\config-mock.json"
```

**Expected:** 
- 20 accounts processed
- 5 remediable accounts identified
- CSV files generated
- Logs created

### Scenario 2: Dashboard Interaction

1. Open dashboard
2. Filter by "Non-Compliant" status
3. Search for "WinServer"
4. Click "Remediate" on remediable account
5. Verify confirmation dialog

**Expected:**
- Filtered results show only non-compliant
- Search narrows to Windows servers
- Remediation dialog appears
- Workflow ID generated

### Scenario 3: Mock API Testing

Test API endpoints directly:

```powershell
# Test account retrieval
Invoke-RestMethod -Uri "http://localhost:8080/PasswordVault/api/Accounts/ACC001"

# Test account search
Invoke-RestMethod -Uri "http://localhost:8080/PasswordVault/api/Accounts?search=WinServer01-Reconcile"
```

**Expected:**
- Account details returned
- Reconcile account found
- JSON responses

### Scenario 4: Error Handling

Test error scenarios:

```powershell
# Invalid account ID
Invoke-RestMethod -Uri "http://localhost:8080/PasswordVault/api/Accounts/INVALID"
# Expected: 404 error

# Stop mock API server
# Run analysis again
# Expected: Connection error, retry logic
```

## Mock Data Details

### Accounts Breakdown

| Status | Count | Percentage |
|--------|-------|------------|
| Compliant | 11 | 55% |
| Non-Compliant | 9 | 45% |
| Remediable | 5 | 25% |
| Non-Remediable | 4 | 20% |

### Platform Distribution

| Platform | Count |
|----------|-------|
| WinServerLocal | 9 |
| UnixSSH | 8 |
| WinDomain | 3 |

### Failure Reasons

- Network connectivity issues: 3 accounts
- No reconcile account: 1 account
- CMDB mismatches: 2 accounts
- Authentication failures: 3 accounts

## Customizing Mock Data

### Add More Accounts

Edit `../sample-data/sample-compliance-report.csv`:

```csv
ACC021,NewAccount,SafeName,PlatformID,address.com,username,Active,Non-Compliant,Failed,Error,2026-05-27,2026-05-27,ReconcileAccount,True,Failure reason
```

### Modify Mock API Responses

Edit `mock-cybeark-api.ps1`:

```powershell
$script:MockAccounts = @{
    'ACC021' = @{
        id = 'ACC021'
        name = 'NewAccount'
        # Add more properties
    }
}
```

### Change Compliance Metrics

The metrics are calculated automatically based on the data in the CSV files. To change them:

1. Edit compliance report CSV
2. Adjust ComplianceStatus values
3. Re-run analysis
4. Metrics will update automatically

## Troubleshooting

### Issue: Mock API Won't Start

**Error:** "Address already in use"

**Solution:**
```powershell
# Check if port 8080 is in use
Get-NetTCPConnection -LocalPort 8080

# Use different port
.\mock-cybeark-api.ps1 -Port 8081

# Update config-mock.json
"pvwaBaseUrl": "http://localhost:8081"
```

### Issue: Script Can't Connect to API

**Error:** "Unable to connect to the remote server"

**Solution:**
1. Verify mock API is running
2. Check port number matches
3. Test API manually:
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:8080/"
   ```

### Issue: Dashboard Shows "Loading..."

**Solution:**
1. Check browser console (F12)
2. Verify CSV files exist in `output/sample-output/`
3. Use local web server:
   ```powershell
   python -m http.server 8000
   # Open: http://localhost:8000/dashboard/
   ```

### Issue: No Output Files Generated

**Solution:**
1. Check output directory exists
2. Verify write permissions
3. Review log files for errors
4. Check config-mock.json paths

## Advanced Testing

### Test with MCP Integration

1. Start MCP server:
   ```powershell
   cd ../mcp-integration
   npm install
   npm start
   ```

2. Update config:
   ```json
   {
     "enableMCPIntegration": true,
     "mcpServerUrl": "http://localhost:3000"
   }
   ```

3. Run analysis with MCP:
   ```powershell
   ..\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
       -ConfigPath ".\config-mock.json" `
       -EnableMCP $true
   ```

### Performance Testing

Test with larger datasets:

```powershell
# Generate 1000 mock accounts
1..1000 | ForEach-Object {
    "ACC$_,Account$_,Safe,Platform,host$_.com,user,Active,Compliant,Success,,2026-05-27,2026-05-27,Reconcile$_,True,"
} | Out-File -FilePath "../sample-data/large-compliance-report.csv"

# Update config to use large file
# Run analysis
```

### API Load Testing

```powershell
# Concurrent requests
1..10 | ForEach-Object -Parallel {
    Invoke-RestMethod -Uri "http://localhost:8080/PasswordVault/api/Accounts/ACC001"
}
```

## Next Steps

After testing with mock environment:

1. **Review Output Files**
   - Check CSV reports
   - Analyze log files
   - Verify calculations

2. **Explore Dashboard**
   - Test all filters
   - Try remediation buttons
   - Export data

3. **Customize Configuration**
   - Adjust retry settings
   - Modify timeouts
   - Enable/disable features

4. **Prepare for Production**
   - Update config with real PVWA URL
   - Configure secure token storage
   - Set up scheduled tasks
   - Enable MCP integration

## Production Deployment

When ready for production:

1. Stop using mock environment
2. Update configuration:
   ```json
   {
     "pvwaBaseUrl": "https://real-pvwa.company.com",
     "complianceReportPath": "C:/Reports/compliance.csv",
     "cmdbReportPath": "C:/Reports/cmdb.csv"
   }
   ```
3. Configure secure token
4. Test with real data
5. Schedule automated runs

## Support

For questions or issues:
- Review main README.md
- Check SETUP.md and EXECUTION.md
- Review log files
- Contact: cybeark-automation-team@company.com

## Summary

✅ Mock environment provides:
- Risk-free testing
- Sample data and outputs
- Interactive dashboard
- Full feature demonstration
- Easy customization

🚀 Ready to test? Start with Step 1 above!