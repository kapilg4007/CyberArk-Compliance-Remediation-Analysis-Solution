<#
.SYNOPSIS
    Install scheduled task for CyberArk Compliance Remediation Analysis

.DESCRIPTION
    Creates a Windows scheduled task to run the compliance analysis script
    on a regular schedule with proper security context and logging.

.PARAMETER TaskName
    Name of the scheduled task

.PARAMETER ScriptPath
    Full path to the Invoke-CyberArkComplianceAnalysis.ps1 script

.PARAMETER ConfigPath
    Full path to the configuration JSON file

.PARAMETER Schedule
    Schedule type: Daily, Weekly, Monthly

.PARAMETER StartTime
    Time to run the task (24-hour format, e.g., "02:00")

.PARAMETER RunAsUser
    User account to run the task (default: SYSTEM)

.PARAMETER DaysOfWeek
    Days of week for weekly schedule (e.g., "Monday,Wednesday,Friday")

.EXAMPLE
    .\Install-ScheduledTask.ps1 -TaskName "CyberArk Compliance Analysis" -ScriptPath "C:\Scripts\Invoke-CyberArkComplianceAnalysis.ps1" -ConfigPath "C:\Scripts\config\config.json" -Schedule Daily -StartTime "02:00"

.EXAMPLE
    .\Install-ScheduledTask.ps1 -TaskName "CyberArk Compliance Analysis" -ScriptPath "C:\Scripts\Invoke-CyberArkComplianceAnalysis.ps1" -ConfigPath "C:\Scripts\config\config.json" -Schedule Weekly -StartTime "03:00" -DaysOfWeek "Monday,Thursday"

.NOTES
    Version:        1.0.0
    Author:         CyberArk Automation Team
    Creation Date:  2026-05-27
    Requires:       Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$ScriptPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$ConfigPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Daily', 'Weekly', 'Monthly')]
    [string]$Schedule = 'Daily',

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$StartTime = '02:00',

    [Parameter(Mandatory = $false)]
    [string]$RunAsUser = 'SYSTEM',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
    [string[]]$DaysOfWeek = @('Monday')
)

#Requires -RunAsAdministrator

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'ERROR'   { Write-Host $logMessage -ForegroundColor Red }
        'WARNING' { Write-Host $logMessage -ForegroundColor Yellow }
        'SUCCESS' { Write-Host $logMessage -ForegroundColor Green }
        default   { Write-Host $logMessage }
    }
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." -Level INFO
    
    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Log "This script must be run as Administrator" -Level ERROR
        return $false
    }
    
    # Check if script file exists
    if (-not (Test-Path $ScriptPath)) {
        Write-Log "Script file not found: $ScriptPath" -Level ERROR
        return $false
    }
    
    # Check if config file exists
    if (-not (Test-Path $ConfigPath)) {
        Write-Log "Configuration file not found: $ConfigPath" -Level ERROR
        return $false
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "PowerShell 5.1 or higher is required" -Level ERROR
        return $false
    }
    
    Write-Log "Prerequisites check passed" -Level SUCCESS
    return $true
}

function Remove-ExistingTask {
    param([string]$Name)
    
    try {
        $existingTask = Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
        
        if ($existingTask) {
            Write-Log "Removing existing task: $Name" -Level WARNING
            Unregister-ScheduledTask -TaskName $Name -Confirm:$false
            Write-Log "Existing task removed" -Level SUCCESS
        }
    }
    catch {
        Write-Log "Error checking for existing task: $_" -Level WARNING
    }
}

function New-TaskAction {
    Write-Log "Creating task action..." -Level INFO
    
    # PowerShell executable
    $psExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    
    # Build arguments
    $arguments = @(
        "-NoProfile"
        "-NonInteractive"
        "-ExecutionPolicy Bypass"
        "-File `"$ScriptPath`""
        "-ConfigPath `"$ConfigPath`""
    )
    
    $argumentString = $arguments -join " "
    
    Write-Log "Action: $psExe $argumentString" -Level INFO
    
    $action = New-ScheduledTaskAction -Execute $psExe -Argument $argumentString
    
    return $action
}

function New-TaskTrigger {
    Write-Log "Creating task trigger..." -Level INFO
    
    $triggerParams = @{
        At = $StartTime
    }
    
    switch ($Schedule) {
        'Daily' {
            $trigger = New-ScheduledTaskTrigger @triggerParams -Daily
            Write-Log "Schedule: Daily at $StartTime" -Level INFO
        }
        'Weekly' {
            $trigger = New-ScheduledTaskTrigger @triggerParams -Weekly -DaysOfWeek $DaysOfWeek
            Write-Log "Schedule: Weekly on $($DaysOfWeek -join ', ') at $StartTime" -Level INFO
        }
        'Monthly' {
            $trigger = New-ScheduledTaskTrigger @triggerParams -Weekly -WeeksInterval 4
            Write-Log "Schedule: Monthly (every 4 weeks) at $StartTime" -Level INFO
        }
    }
    
    return $trigger
}

function New-TaskPrincipal {
    Write-Log "Creating task principal..." -Level INFO
    
    if ($RunAsUser -eq 'SYSTEM') {
        $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        Write-Log "Run as: SYSTEM (highest privileges)" -Level INFO
    }
    else {
        $principal = New-ScheduledTaskPrincipal -UserId $RunAsUser -LogonType Password -RunLevel Highest
        Write-Log "Run as: $RunAsUser (highest privileges)" -Level INFO
    }
    
    return $principal
}

function New-TaskSettings {
    Write-Log "Creating task settings..." -Level INFO
    
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -MultipleInstances IgnoreNew `
        -ExecutionTimeLimit (New-TimeSpan -Hours 4)
    
    Write-Log "Settings configured: Allow on battery, Start when available, Network required" -Level INFO
    
    return $settings
}

function Register-Task {
    param(
        [string]$Name,
        [object]$Action,
        [object]$Trigger,
        [object]$Principal,
        [object]$Settings
    )
    
    Write-Log "Registering scheduled task: $Name" -Level INFO
    
    try {
        $task = Register-ScheduledTask `
            -TaskName $Name `
            -Action $Action `
            -Trigger $Trigger `
            -Principal $Principal `
            -Settings $Settings `
            -Description "Automated CyberArk compliance remediation analysis with IBM ICA integration"
        
        Write-Log "Scheduled task registered successfully" -Level SUCCESS
        return $task
    }
    catch {
        Write-Log "Failed to register scheduled task: $_" -Level ERROR
        throw
    }
}

function Test-Task {
    param([string]$Name)
    
    Write-Log "Testing scheduled task..." -Level INFO
    
    try {
        $task = Get-ScheduledTask -TaskName $Name -ErrorAction Stop
        
        Write-Log "Task found: $($task.TaskName)" -Level SUCCESS
        Write-Log "State: $($task.State)" -Level INFO
        Write-Log "Next Run Time: $($task.NextRunTime)" -Level INFO
        
        # Optionally run the task immediately for testing
        $response = Read-Host "Do you want to run the task now for testing? (Y/N)"
        
        if ($response -eq 'Y' -or $response -eq 'y') {
            Write-Log "Starting task..." -Level INFO
            Start-ScheduledTask -TaskName $Name
            Write-Log "Task started. Check logs for results." -Level SUCCESS
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to verify task: $_" -Level ERROR
        return $false
    }
}

function Show-TaskSummary {
    param([object]$Task)
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Scheduled Task Summary" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Task Name:        $($Task.TaskName)" -ForegroundColor White
    Write-Host "State:            $($Task.State)" -ForegroundColor Green
    Write-Host "Schedule:         $Schedule" -ForegroundColor White
    Write-Host "Start Time:       $StartTime" -ForegroundColor White
    
    if ($Schedule -eq 'Weekly') {
        Write-Host "Days of Week:     $($DaysOfWeek -join ', ')" -ForegroundColor White
    }
    
    Write-Host "Run As:           $RunAsUser" -ForegroundColor White
    Write-Host "Script Path:      $ScriptPath" -ForegroundColor White
    Write-Host "Config Path:      $ConfigPath" -ForegroundColor White
    Write-Host "Next Run Time:    $($Task.NextRunTime)" -ForegroundColor Yellow
    
    Write-Host "`nManagement Commands:" -ForegroundColor Cyan
    Write-Host "  View task:      Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "  Run task:       Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "  Disable task:   Disable-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "  Enable task:    Enable-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "  Remove task:    Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    
    Write-Host "`n========================================`n" -ForegroundColor Cyan
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "CyberArk Compliance Analysis" -ForegroundColor Cyan
    Write-Host "Scheduled Task Installation" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        throw "Prerequisites check failed"
    }
    
    # Remove existing task if present
    Remove-ExistingTask -Name $TaskName
    
    # Create task components
    $action = New-TaskAction
    $trigger = New-TaskTrigger
    $principal = New-TaskPrincipal
    $settings = New-TaskSettings
    
    # Register the task
    $task = Register-Task -Name $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
    
    # Verify the task
    if (Test-Task -Name $TaskName) {
        Show-TaskSummary -Task $task
        
        Write-Log "Installation completed successfully!" -Level SUCCESS
        exit 0
    }
    else {
        throw "Task verification failed"
    }
}
catch {
    Write-Log "Installation failed: $_" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    exit 1
}

# Made with Bob
