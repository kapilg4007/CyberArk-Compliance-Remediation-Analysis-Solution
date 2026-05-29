        }
        
        # MCP Integration
        if ($EnableMCP -or $script:Config.enableMCPIntegration) {
            Write-Log "Sending results to IBM ICA MCP server..." -Component "Main"
            $mcpResponse = Send-ToMCPServer -AnalysisResults $analysisResults `
                                           -Metrics $metrics `
                                           -MCPServerUrl $script:Config.mcpServerUrl
        }
        
        # Display summary
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "Analysis Complete" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        Write-Host "Compliance Metrics:" -ForegroundColor Yellow
        Write-Host "  Total CPM-Managed Accounts: $($metrics.TotalCPMManagedAccounts)"
        Write-Host "  Compliant Accounts: $($metrics.CompliantAccounts)" -ForegroundColor Green
        Write-Host "  Failed Accounts: $($metrics.FailedAccounts)" -ForegroundColor Red
        Write-Host "  Remediable Failed Accounts: $($metrics.RemediableFailedAccounts)" -ForegroundColor Yellow
        Write-Host "  Original Compliance: $($metrics.OriginalCompliancePercent)%"
        Write-Host "  Projected Compliance: $($metrics.ProjectedCompliancePercent)%" -ForegroundColor Green
        Write-Host "  Projected Increase: +$($metrics.ProjectedComplianceIncrease)%" -ForegroundColor Green
        
        Write-Host "`nOutput Files:" -ForegroundColor Yellow
        Write-Host "  CSV Reports: $($script:Config.outputDirectory)"
        if ($excelPath) {
            Write-Host "  Excel Report: $excelPath" -ForegroundColor Green
        }
        Write-Host "  Log File: $script:LogPath"
        Write-Host "  Transcript: $script:TranscriptPath"
        
        $endTime = Get-Date
        $duration = $endTime - $script:StartTime
        Write-Host "`nExecution Time: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
        
        Write-Log "Script execution completed successfully" -Level SUCCESS
        
        return @{
            Success         = $true
            Metrics         = $metrics
            AnalysisResults = $analysisResults
            OutputPaths     = $csvPaths
            ExcelPath       = $excelPath
        }
    }
    catch {
        Write-Log "Script execution failed: $_" -Level ERROR
        Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
        
        Write-Host "`n========================================" -ForegroundColor Red
        Write-Host "Execution Failed" -ForegroundColor Red
        Write-Host "========================================`n" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        
        throw
    }
    finally {
        # Stop transcript
        if ($script:TranscriptPath) {
            try {
                Stop-Transcript -ErrorAction SilentlyContinue
            }
            catch {
                # Transcript may not be running
            }
        }
    }
}

# Execute main function
Invoke-Main