<#
.SYNOPSIS
    Mock CyberArk PVWA REST API Server for Testing

.DESCRIPTION
    Creates a simple HTTP server that simulates CyberArk PVWA REST API responses
    for testing the compliance analysis script without a real CyberArk environment.

.PARAMETER Port
    Port number for the mock API server (default: 8080)

.EXAMPLE
    .\mock-cybeark-api.ps1 -Port 8080

.NOTES
    This is for testing purposes only. Not for production use.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$Port = 8080
)

# Mock account data
$script:MockAccounts = @{
    'ACC001' = @{
        id = 'ACC001'
        name = 'WinServer01-Admin'
        address = 'winserver01.company.com'
        userName = 'Administrator'
        safeName = 'Windows-Servers'
        platformId = 'WinServerLocal'
        secretManagement = @{
            status = 'success'
        }
        platformAccountProperties = @{
            ReconcileAccountName = 'WinServer01-Reconcile'
        }
    }
    'ACC002' = @{
        id = 'ACC002'
        name = 'WinServer02-Admin'
        address = 'winserver02.company.com'
        userName = 'Administrator'
        safeName = 'Windows-Servers'
        platformId = 'WinServerLocal'
        secretManagement = @{
            status = 'failed'
        }
        platformAccountProperties = @{
            ReconcileAccountName = 'WinServer02-Reconcile'
        }
    }
    'ACC003' = @{
        id = 'ACC003'
        name = 'LinuxDB01-Root'
        address = 'linuxdb01.company.com'
        userName = 'root'
        safeName = 'Linux-Servers'
        platformId = 'UnixSSH'
        secretManagement = @{
            status = 'failed'
        }
        platformAccountProperties = @{
            ReconcileAccountName = 'LinuxDB01-Reconcile'
        }
    }
}

# Mock reconcile accounts
$script:MockReconcileAccounts = @{
    'WinServer01-Reconcile' = @{
        id = 'REC001'
        name = 'WinServer01-Reconcile'
        address = 'winserver01.company.com'
        userName = 'reconcile_admin'
        safeName = 'Windows-Servers'
        platformId = 'WinServerLocal'
        secretManagement = @{
            status = 'success'
        }
    }
    'WinServer02-Reconcile' = @{
        id = 'REC002'
        name = 'WinServer02-Reconcile'
        address = 'winserver02.company.com'
        userName = 'reconcile_admin'
        safeName = 'Windows-Servers'
        platformId = 'WinServerLocal'
        secretManagement = @{
            status = 'success'
        }
    }
    'LinuxDB01-Reconcile' = @{
        id = 'REC003'
        name = 'LinuxDB01-Reconcile'
        address = 'linuxdb01.company.com'
        userName = 'reconcile_root'
        safeName = 'Linux-Servers'
        platformId = 'UnixSSH'
        secretManagement = @{
            status = 'success'
        }
    }
}

function Start-MockAPIServer {
    param([int]$Port)
    
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$Port/")
    $listener.Start()
    
    Write-Host "Mock CyberArk API Server started on http://localhost:$Port" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "[$timestamp] $($request.HttpMethod) $($request.Url.PathAndQuery)" -ForegroundColor Cyan
            
            # Handle different API endpoints
            $responseData = Handle-Request -Request $request
            
            # Set response
            $response.ContentType = "application/json"
            $response.StatusCode = $responseData.StatusCode
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData.Body)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
        }
    }
    finally {
        $listener.Stop()
        Write-Host "Mock API Server stopped" -ForegroundColor Yellow
    }
}

function Handle-Request {
    param($Request)
    
    $path = $Request.Url.AbsolutePath
    $query = $Request.Url.Query
    
    # GET /PasswordVault/api/Accounts/{id}
    if ($path -match '/PasswordVault/api/Accounts/([A-Z0-9]+)$') {
        $accountId = $matches[1]
        if ($script:MockAccounts.ContainsKey($accountId)) {
            return @{
                StatusCode = 200
                Body = ($script:MockAccounts[$accountId] | ConvertTo-Json -Depth 10)
            }
        }
        else {
            return @{
                StatusCode = 404
                Body = '{"ErrorCode":"PASWS044E","ErrorMessage":"Account not found"}'
            }
        }
    }
    
    # GET /PasswordVault/api/Accounts?search=...
    if ($path -eq '/PasswordVault/api/Accounts' -and $query) {
        # Parse search query
        if ($query -match 'search=([^&]+)') {
            $searchTerm = [System.Web.HttpUtility]::UrlDecode($matches[1])
            
            # Search in reconcile accounts
            $results = @()
            foreach ($key in $script:MockReconcileAccounts.Keys) {
                if ($key -like "*$searchTerm*") {
                    $results += $script:MockReconcileAccounts[$key]
                }
            }
            
            return @{
                StatusCode = 200
                Body = (@{ value = $results } | ConvertTo-Json -Depth 10)
            }
        }
    }
    
    # Default response
    return @{
        StatusCode = 200
        Body = '{"message":"Mock CyberArk API","version":"1.0.0"}'
    }
}

# Start the server
Start-MockAPIServer -Port $Port

# Made with Bob
