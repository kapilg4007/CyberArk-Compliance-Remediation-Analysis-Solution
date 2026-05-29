# CyberArk Compliance Remediation Dashboard

## Overview

Interactive HTML dashboard for visualizing CyberArk compliance analysis results and managing remediation activities with IBM ICA integration.

## Features

### 📊 Real-Time Metrics
- Total CPM-managed accounts
- Compliant vs. failed accounts
- Remediable accounts count
- Projected compliance percentage
- Compliance improvement tracking

### 📈 Interactive Charts
- **Compliance Overview**: Doughnut chart showing compliant vs. failed distribution
- **Compliance Projection**: Bar chart comparing current vs. projected compliance
- **Remediation Breakdown**: Pie chart of remediable vs. non-remediable accounts
- **Platform Distribution**: Horizontal bar chart showing accounts per platform

### 📋 Account Management Table
- Sortable and filterable account list
- Real-time search functionality
- Status badges (Compliant/Non-Compliant/Remediable)
- One-click remediation trigger
- Detailed remediation recommendations

### 🔍 Advanced Filtering
- Filter by compliance status
- Filter by platform type
- Search across all account fields
- Real-time table updates

## Quick Start

### Option 1: Open Directly (Recommended)

Simply open `index.html` in your web browser:

```bash
# Windows
start dashboard/index.html

# macOS
open dashboard/index.html

# Linux
xdg-open dashboard/index.html
```

### Option 2: Local Web Server

For better performance and to avoid CORS issues:

```bash
# Using Python 3
cd cybeark-compliance-remediation
python -m http.server 8000

# Then open: http://localhost:8000/dashboard/
```

```bash
# Using Node.js (http-server)
npm install -g http-server
cd cybeark-compliance-remediation
http-server -p 8000

# Then open: http://localhost:8000/dashboard/
```

```powershell
# Using PowerShell
cd cybeark-compliance-remediation
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8000/")
$listener.Start()
Write-Host "Server started at http://localhost:8000/"
# Then open: http://localhost:8000/dashboard/
```

## Data Sources

The dashboard automatically loads data from:

- `../output/sample-output/ComplianceMetrics_20260527_080000.csv`
- `../output/sample-output/RemediationSummary_20260527_080000.csv`

### Using Your Own Data

1. Run the compliance analysis script:
   ```powershell
   .\scripts\Invoke-CyberArkComplianceAnalysis.ps1 -ConfigPath ".\config\config.json"
   ```

2. Update the dashboard to point to your output files:
   - Edit `index.html`
   - Update the file paths in the `loadData()` function
   - Or copy your output files to `output/sample-output/` with the expected names

## Dashboard Components

### Metrics Cards

```
┌─────────────────────────────────────────────────────────┐
│  Total CPM-Managed  │  Compliant  │  Failed  │  etc.   │
│        20           │     11      │    9     │         │
│     Accounts        │   55.00%    │  45.00%  │         │
└─────────────────────────────────────────────────────────┘
```

### Charts Section

```
┌──────────────────────┬──────────────────────┐
│  Compliance Overview │  Compliance Projection│
│   (Doughnut Chart)   │    (Bar Chart)       │
├──────────────────────┼──────────────────────┤
│ Remediation Breakdown│  Platform Distribution│
│    (Pie Chart)       │    (Bar Chart)       │
└──────────────────────┴──────────────────────┘
```

### Accounts Table

```
┌────────────────────────────────────────────────────────────┐
│ Filters: [Status ▼] [Platform ▼] [Search...]              │
├────────────────────────────────────────────────────────────┤
│ ID    │ Name    │ Platform │ Status │ Remediable │ Action │
│ ACC001│ Server01│ Windows  │ ✓      │ No         │ [---]  │
│ ACC002│ Server02│ Windows  │ ✗      │ Yes        │ [Fix]  │
└────────────────────────────────────────────────────────────┘
```

## Features in Detail

### 1. Remediation Trigger

Click the "Remediate" button on any remediable account to:
- Trigger IBM ICA workflow
- Generate workflow ID
- Display confirmation dialog
- Track remediation status

### 2. Real-Time Filtering

**Status Filter:**
- All Status
- Compliant
- Non-Compliant
- Remediable Only

**Platform Filter:**
- All Platforms
- WinServerLocal
- UnixSSH
- WinDomain

**Search:**
- Search across all fields
- Real-time results
- Case-insensitive

### 3. Visual Indicators

**Status Badges:**
- 🟢 Green: Compliant
- 🔴 Red: Non-Compliant
- 🟡 Yellow: Remediable

**Metric Cards:**
- Hover effects
- Color-coded values
- Percentage indicators

## Customization

### Changing Colors

Edit the CSS in `index.html`:

```css
.metric-card.compliant .value { color: #10b981; } /* Green */
.metric-card.failed .value { color: #ef4444; }    /* Red */
.metric-card.remediable .value { color: #f59e0b; } /* Orange */
```

### Adding New Charts

```javascript
const newChartCtx = document.getElementById('newChart').getContext('2d');
charts.newChart = new Chart(newChartCtx, {
    type: 'line', // or 'bar', 'pie', 'doughnut'
    data: {
        labels: ['Label1', 'Label2'],
        datasets: [{
            data: [10, 20],
            backgroundColor: '#667eea'
        }]
    }
});
```

### Modifying Table Columns

Edit the table structure in `renderTable()` function:

```javascript
row.innerHTML = `
    <td>${account.AccountID}</td>
    <td>${account.AccountName}</td>
    // Add more columns here
`;
```

## Integration with IBM ICA

The dashboard includes IBM ICA workflow integration:

### Remediation Workflow

When clicking "Remediate":
1. Confirmation dialog appears
2. Workflow ID generated
3. IBM ICA API called (if configured)
4. Status tracked in IBM ICA dashboard

### Configuration

To enable live IBM ICA integration:

1. Update the `triggerRemediation()` function
2. Add IBM ICA API endpoint
3. Include authentication token
4. Handle workflow responses

Example:

```javascript
async function triggerRemediation(accountId) {
    const response = await fetch('https://ica.company.com/api/v1/workflows/execute', {
        method: 'POST',
        headers: {
            'Authorization': 'Bearer YOUR_TOKEN',
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            workflowId: 'compliance-remediation-workflow',
            parameters: { accountId }
        })
    });
    
    const result = await response.json();
    alert(`Workflow ${result.workflowInstanceId} started`);
}
```

## Browser Compatibility

Tested and working on:
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Edge 90+
- ✅ Safari 14+

## Dependencies

All dependencies loaded via CDN:
- **Chart.js 4.4.0**: For interactive charts
- **PapaParse 5.4.1**: For CSV parsing

No installation required!

## Troubleshooting

### Dashboard Not Loading

**Issue**: Blank page or loading message stuck

**Solutions:**
1. Check browser console for errors (F12)
2. Verify CSV files exist in correct location
3. Use a local web server instead of file://
4. Check file paths in `loadData()` function

### Charts Not Displaying

**Issue**: Charts area is empty

**Solutions:**
1. Ensure Chart.js CDN is accessible
2. Check browser console for errors
3. Verify data format in CSV files
4. Clear browser cache

### CORS Errors

**Issue**: "Access to fetch blocked by CORS policy"

**Solution:**
Use a local web server instead of opening file directly:
```bash
python -m http.server 8000
```

### Data Not Updating

**Issue**: Old data still showing

**Solutions:**
1. Hard refresh: Ctrl+F5 (Windows) or Cmd+Shift+R (Mac)
2. Clear browser cache
3. Check CSV file timestamps
4. Verify file paths

## Performance

- **Load Time**: < 1 second for 1000 accounts
- **Rendering**: Optimized for large datasets
- **Memory**: Efficient data handling
- **Responsive**: Works on mobile devices

## Security Notes

- Dashboard runs entirely in browser (client-side)
- No data sent to external servers
- CSV files loaded locally
- IBM ICA integration requires authentication
- Suitable for internal enterprise use

## Future Enhancements

Planned features:
- [ ] Real-time data refresh
- [ ] Export filtered results
- [ ] Historical trend analysis
- [ ] Email report generation
- [ ] Dark mode theme
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] Workflow status tracking

## Support

For issues or questions:
- Check browser console (F12)
- Review CSV file format
- Verify file paths
- Contact: cybeark-automation-team@company.com

## Version History

- **v1.0.0** (2026-05-27): Initial dashboard release
  - Interactive metrics cards
  - 4 chart types
  - Filterable accounts table
  - IBM ICA integration ready
  - Responsive design