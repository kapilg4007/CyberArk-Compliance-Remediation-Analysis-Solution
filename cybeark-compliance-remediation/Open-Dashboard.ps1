<#
.SYNOPSIS
    Quick launcher for CyberArk Compliance Dashboard

.DESCRIPTION
    Opens the compliance dashboard in your default web browser.
    Automatically starts a local web server if needed to avoid CORS issues.

.PARAMETER UseWebServer
    Start a local web server (recommended for best experience)

.PARAMETER Port
    Port number for web server (default: 8000)

.EXAMPLE
    .\Open-Dashboard.ps1
    Opens dashboard directly in browser

.EXAMPLE
    .\Open-Dashboard.ps1 -UseWebServer
    Starts web server and opens dashboard
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$UseWebServer,
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 8000
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CyberArk Compliance Dashboard Launcher" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$dashboardPath = Join-Path $PSScriptRoot "dashboard\index.html"

if (-not (Test-Path $dashboardPath)) {
    Write-Host "Error: Dashboard file not found at: $dashboardPath" -ForegroundColor Red
    exit 1
}

if ($UseWebServer) {
    Write-Host "Starting local web server on port $Port..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop the server`n" -ForegroundColor Yellow
    
    # Check if Python is available
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    
    if ($pythonCmd) {
        Write-Host "Using Python web server..." -ForegroundColor Green
        Write-Host "Dashboard URL: http://localhost:$Port/dashboard/`n" -ForegroundColor Cyan
        
        # Open browser
        Start-Sleep -Seconds 2
        Start-Process "http://localhost:$Port/dashboard/"
        
        # Start Python server
        Set-Location $PSScriptRoot
        python -m http.server $Port
    }
    else {
        Write-Host "Python not found. Using PowerShell web server..." -ForegroundColor Yellow
        Write-Host "Dashboard URL: http://localhost:$Port/dashboard/`n" -ForegroundColor Cyan
        
        # Simple PowerShell HTTP server
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://localhost:$Port/")
        $listener.Start()
        
        Write-Host "Web server started successfully!" -ForegroundColor Green
        
        # Open browser
        Start-Process "http://localhost:$Port/dashboard/"
        
        Write-Host "`nServing files from: $PSScriptRoot" -ForegroundColor Gray
        Write-Host "Press Ctrl+C to stop...`n" -ForegroundColor Yellow
        
        try {
            while ($listener.IsListening) {
                $context = $listener.GetContext()
                $request = $context.Request
                $response = $context.Response
                
                $requestedPath = $request.Url.LocalPath.TrimStart('/')
                if ($requestedPath -eq '' -or $requestedPath -eq 'dashboard' -or $requestedPath -eq 'dashboard/') {
                    $requestedPath = 'dashboard/index.html'
                }
                
                $filePath = Join-Path $PSScriptRoot $requestedPath
                
                Write-Host "$(Get-Date -Format 'HH:mm:ss') - $($request.HttpMethod) $($request.Url.LocalPath)" -ForegroundColor Gray
                
                if (Test-Path $filePath -PathType Leaf) {
                    $content = [System.IO.File]::ReadAllBytes($filePath)
                    
                    # Set content type
                    $extension = [System.IO.Path]::GetExtension($filePath)
                    switch ($extension) {
                        '.html' { $response.ContentType = 'text/html' }
                        '.css'  { $response.ContentType = 'text/css' }
                        '.js'   { $response.ContentType = 'application/javascript' }
                        '.json' { $response.ContentType = 'application/json' }
                        '.csv'  { $response.ContentType = 'text/csv' }
                        default { $response.ContentType = 'application/octet-stream' }
                    }
                    
                    $response.StatusCode = 200
                    $response.ContentLength64 = $content.Length
                    $response.OutputStream.Write($content, 0, $content.Length)
                }
                else {
                    $response.StatusCode = 404
                    $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 - File Not Found: $requestedPath")
                    $response.OutputStream.Write($notFound, 0, $notFound.Length)
                }
                
                $response.OutputStream.Close()
            }
        }
        finally {
            $listener.Stop()
            Write-Host "`nWeb server stopped." -ForegroundColor Yellow
        }
    }
}
} 
else {
    Write-Host "Opening dashboard directly in browser..." -ForegroundColor Green
    Write-Host "Dashboard path: $dashboardPath`n" -ForegroundColor Gray
    
    # Open in default browser
    Start-Process $dashboardPath
    
    Write-Host "✓ Dashboard opened!" -ForegroundColor Green
    Write-Host "`nNote: If you see CORS errors, run with -UseWebServer flag:" -ForegroundColor Yellow
    Write-Host "  .\Open-Dashboard.ps1 -UseWebServer`n" -ForegroundColor Cyan
}
}
# Made with Bob
