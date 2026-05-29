# CyberArk Compliance Calculation Formulas

## Overview

This document provides detailed explanations of the compliance calculation formulas used in the CyberArk Compliance Remediation Analysis solution.

## Core Metrics

### 1. Total CPM-Managed Accounts

**Definition:** The total number of accounts managed by CyberArk's Central Password Manager (CPM).

**Formula:**
```
Total CPM-Managed Accounts = COUNT(Accounts WHERE IsCPMManaged = TRUE)
```

**Example:**
```
Input: 20 accounts in compliance report
Filter: IsCPMManaged = TRUE
Result: 20 CPM-managed accounts
```

---

### 2. Compliant Accounts

**Definition:** Accounts that have successfully passed CPM password management operations.

**Formula:**
```
Compliant Accounts = COUNT(Accounts WHERE IsCPMManaged = TRUE AND ComplianceStatus = 'Compliant')
```

**Criteria for Compliance:**
- Account is CPM-managed
- Last CPM operation status = Success
- No outstanding errors
- Password verified/reconciled successfully

**Example:**
```
Input: 20 CPM-managed accounts
Compliant: 11 accounts with ComplianceStatus = 'Compliant'
Result: 11 compliant accounts
```

---

### 3. Failed CPM-Managed Accounts

**Definition:** CPM-managed accounts that have failed password management operations.

**Formula:**
```
Failed CPM-Managed Accounts = Total CPM-Managed Accounts - Compliant Accounts
```

**Alternative Formula:**
```
Failed CPM-Managed Accounts = COUNT(Accounts WHERE IsCPMManaged = TRUE AND ComplianceStatus ≠ 'Compliant')
```

**Example:**
```
Total CPM-Managed: 20 accounts
Compliant: 11 accounts
Failed: 20 - 11 = 9 accounts
```

---

### 4. Original Compliance Percentage

**Definition:** The current compliance rate before any remediation efforts.

**Formula:**
```
Original Compliance % = (Compliant Accounts / Total CPM-Managed Accounts) × 100
```

**Rounding:** Round to 2 decimal places

**Example:**
```
Compliant Accounts: 11
Total CPM-Managed: 20
Original Compliance % = (11 / 20) × 100 = 55.00%
```

---

## Remediation Analysis

### 5. Remediable Failed Accounts

**Definition:** Failed accounts that meet all criteria for successful remediation through reconcile account usage.

**Formula:**
```
Remediable Failed Accounts = COUNT(Failed Accounts WHERE ALL conditions are TRUE:
    1. Account exists in CyberArk
    2. Account is CPM-managed
    3. Target system is network reachable (all required ports)
    4. Associated reconcile account exists
    5. Reconcile account is usable (not disabled/locked)
    6. No blocking CMDB mismatch exists
)
```

**Detailed Criteria:**

#### Criterion 1: Account Exists in CyberArk
- Account can be retrieved via PVWA REST API
- Account ID is valid
- Account is not deleted

#### Criterion 2: Account is CPM-Managed
- IsCPMManaged = TRUE
- Account is assigned to a CPM
- Platform supports password management

#### Criterion 3: Target System is Network Reachable
**For Windows Systems:**
- Port 135 (RPC) = Reachable
- Port 139 (NetBIOS) = Reachable
- Port 445 (SMB) = Reachable

**For Linux/Unix Systems:**
- Port 22 (SSH) = Reachable

**Formula:**
```
AllPortsReachable = (
    COUNT(Ports WHERE IsReachable = TRUE) = COUNT(Required Ports)
)
```

#### Criterion 4: Associated Reconcile Account Exists
- Reconcile account name is defined
- Reconcile account found in CyberArk
- Reconcile account is in the same safe or accessible safe

#### Criterion 5: Reconcile Account is Usable
- Account status = Active
- Last CPM status = Success
- Account is not locked or disabled
- Credentials are valid

#### Criterion 6: No Blocking CMDB Mismatch
**Non-Blocking Mismatches:**
- Minor metadata differences
- Non-critical attribute mismatches

**Blocking Mismatches:**
- System marked as inactive in CMDB
- System decommissioned
- Critical security policy violations
- Ownership conflicts

**Example:**
```
Failed Accounts: 9
Analysis Results:
  - ACC002: ✓ All criteria met → Remediable
  - ACC003: ✗ Network unreachable → Not remediable
  - ACC005: ✓ All criteria met → Remediable
  - ACC007: ✗ Network unreachable → Not remediable
  - ACC009: ✗ No reconcile account → Not remediable
  - ACC011: ✓ All criteria met → Remediable
  - ACC013: ✓ All criteria met → Remediable
  - ACC015: ✗ CMDB mismatch (inactive) → Not remediable
  - ACC017: ✗ Network unreachable → Not remediable
  - ACC019: ✓ All criteria met → Remediable

Remediable Failed Accounts: 5
```

---

### 6. Non-Remediable Failed Accounts

**Definition:** Failed accounts that cannot be remediated through automated reconcile processes.

**Formula:**
```
Non-Remediable Failed Accounts = Failed CPM-Managed Accounts - Remediable Failed Accounts
```

**Example:**
```
Failed Accounts: 9
Remediable: 5
Non-Remediable: 9 - 5 = 4 accounts
```

---

## Projection Calculations

### 7. Projected Compliant Accounts

**Definition:** Expected number of compliant accounts after successful remediation.

**Formula:**
```
Projected Compliant Accounts = Current Compliant Accounts + Remediable Failed Accounts
```

**Assumption:** All remediable accounts will be successfully remediated.

**Example:**
```
Current Compliant: 11 accounts
Remediable Failed: 5 accounts
Projected Compliant: 11 + 5 = 16 accounts
```

---

### 8. Projected Compliance Percentage

**Definition:** Expected compliance rate after remediation efforts.

**Formula:**
```
Projected Compliance % = (Projected Compliant Accounts / Total CPM-Managed Accounts) × 100
```

**Rounding:** Round to 2 decimal places

**Example:**
```
Projected Compliant: 16 accounts
Total CPM-Managed: 20 accounts
Projected Compliance % = (16 / 20) × 100 = 80.00%
```

---

### 9. Projected Compliance Increase

**Definition:** The improvement in compliance percentage after remediation.

**Formula:**
```
Projected Compliance Increase % = Projected Compliance % - Original Compliance %
```

**Example:**
```
Projected Compliance: 80.00%
Original Compliance: 55.00%
Projected Increase: 80.00% - 55.00% = +25.00%
```

---

## Complete Calculation Example

### Scenario: Enterprise with 20 CPM-Managed Accounts

**Input Data:**
- Total accounts in compliance report: 20
- All accounts are CPM-managed: 20
- Compliant accounts: 11
- Failed accounts: 9

**Step 1: Calculate Original Compliance**
```
Original Compliance % = (11 / 20) × 100 = 55.00%
```

**Step 2: Analyze Failed Accounts**

| Account ID | Network | Reconcile | CMDB | Remediable |
|------------|---------|-----------|------|------------|
| ACC002     | ✓       | ✓         | ✓    | Yes        |
| ACC003     | ✗       | ✓         | ✓    | No         |
| ACC005     | ✓       | ✓         | ✓    | Yes        |
| ACC007     | ✗       | ✓         | ✓    | No         |
| ACC009     | ✓       | ✗         | ✓    | No         |
| ACC011     | ✓       | ✓         | ✓    | Yes        |
| ACC013     | ✓       | ✓         | ✓    | Yes        |
| ACC015     | ✓       | ✓         | ✗    | No         |
| ACC017     | ✗       | ✓         | ✓    | No         |
| ACC019     | ✓       | ✓         | ✓    | Yes        |

**Remediable Failed Accounts:** 5

**Step 3: Calculate Projections**
```
Projected Compliant Accounts = 11 + 5 = 16
Projected Compliance % = (16 / 20) × 100 = 80.00%
Projected Increase % = 80.00% - 55.00% = +25.00%
```

**Step 4: Summary**

| Metric                              | Value    |
|-------------------------------------|----------|
| Total CPM-Managed Accounts          | 20       |
| Compliant Accounts                  | 11       |
| Failed Accounts                     | 9        |
| Remediable Failed Accounts          | 5        |
| Non-Remediable Failed Accounts      | 4        |
| Original Compliance %               | 55.00%   |
| Projected Compliant Accounts        | 16       |
| Projected Compliance %              | 80.00%   |
| **Projected Compliance Increase %** | **+25.00%** |

---

## Business Value Calculation

### ROI Metrics

**Time Saved per Remediated Account:**
```
Assuming manual remediation takes 30 minutes per account:
Time Saved = Remediable Accounts × 30 minutes
Example: 5 accounts × 30 min = 150 minutes (2.5 hours)
```

**Cost Savings:**
```
Assuming $50/hour labor cost:
Cost Savings = (Time Saved in hours) × Hourly Rate
Example: 2.5 hours × $50 = $125 per analysis cycle
```

**Risk Reduction:**
```
Risk Score Reduction = (Remediable Accounts / Failed Accounts) × 100
Example: (5 / 9) × 100 = 55.56% of failed accounts can be remediated
```

---

## Formula Validation

### Edge Cases

**Case 1: No CPM-Managed Accounts**
```
If Total CPM-Managed Accounts = 0:
  Original Compliance % = 0%
  Projected Compliance % = 0%
  Projected Increase % = 0%
```

**Case 2: All Accounts Compliant**
```
If Compliant Accounts = Total CPM-Managed Accounts:
  Original Compliance % = 100%
  Remediable Failed Accounts = 0
  Projected Compliance % = 100%
  Projected Increase % = 0%
```

**Case 3: No Remediable Accounts**
```
If Remediable Failed Accounts = 0:
  Projected Compliant Accounts = Current Compliant Accounts
  Projected Compliance % = Original Compliance %
  Projected Increase % = 0%
```

**Case 4: All Failed Accounts Remediable**
```
If Remediable Failed Accounts = Failed Accounts:
  Projected Compliance % = 100%
  Projected Increase % = 100% - Original Compliance %
```

---

## Implementation Notes

### PowerShell Implementation

```powershell
function Calculate-ComplianceMetrics {
    param([array]$AnalysisResults)
    
    $totalCPMManaged = $AnalysisResults.Count
    $compliantAccounts = ($AnalysisResults | Where-Object { $_.IsCompliant }).Count
    $failedAccounts = $totalCPMManaged - $compliantAccounts
    $remediableAccounts = ($AnalysisResults | Where-Object { $_.IsRemediable }).Count
    
    $originalCompliancePercent = if ($totalCPMManaged -gt 0) { 
        [math]::Round(($compliantAccounts / $totalCPMManaged) * 100, 2) 
    } else { 0 }
    
    $projectedCompliantAccounts = $compliantAccounts + $remediableAccounts
    $projectedCompliancePercent = if ($totalCPMManaged -gt 0) { 
        [math]::Round(($projectedCompliantAccounts / $totalCPMManaged) * 100, 2) 
    } else { 0 }
    
    $complianceIncrease = $projectedCompliancePercent - $originalCompliancePercent
    
    return @{
        TotalCPMManagedAccounts     = $totalCPMManaged
        CompliantAccounts           = $compliantAccounts
        FailedAccounts              = $failedAccounts
        RemediableFailedAccounts    = $remediableAccounts
        OriginalCompliancePercent   = $originalCompliancePercent
        ProjectedCompliancePercent  = $projectedCompliancePercent
        ProjectedComplianceIncrease = $complianceIncrease
    }
}
```

---

## References

- CyberArk CPM Documentation
- CyberArk PVWA REST API Guide
- Enterprise Compliance Standards
- Password Management Best Practices

---

## Version History

- **v1.0.0** (2026-05-27): Initial formula documentation
  - Core compliance metrics
  - Remediation analysis formulas
  - Projection calculations
  - Business value metrics