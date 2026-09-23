#requires -Version 5
<#
.SYNOPSIS
    aq mcp start|stop|status|tools — manage the MCP server.
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start","stop","status","tools")]
    [string]$Action
)

$port = 6789
$mcpDir = "$PSScriptRoot\..\apps\mcp-server"

switch ($Action) {
    "start" {
        $running = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $port }
        if ($running) {
            Write-Host "MCP server already running on port $port (PID $($running.OwningProcess))" -ForegroundColor Yellow
            exit 0
        }
        Write-Host "Starting MCP server on port $port..." -ForegroundColor Cyan
        Push-Location $mcpDir
        try {
            Start-Process -FilePath "node" -ArgumentList "--import","ts-node/esm","src/server.ts" -PassThru | Select-Object Id
            Start-Sleep -Seconds 3
            $check = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $port }
            if ($check) {
                Write-Host "OK — MCP server up on http://127.0.0.1:$port" -ForegroundColor Green
            } else {
                Write-Host "Failed to start — check logs" -ForegroundColor Red
            }
        } finally {
            Pop-Location
        }
    }
    "stop" {
        $running = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $port }
        if (-not $running) {
            Write-Host "MCP server not running on port $port" -ForegroundColor Yellow
            exit 0
        }
        $nodeProcs = Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*ts-node*" -or $_.CommandLine -like "*aq-mcp*" }
        foreach ($p in $nodeProcs) {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
            Write-Host "Killed PID $($p.ProcessId)" -ForegroundColor DarkGray
        }
        Write-Host "MCP server stopped." -ForegroundColor Green
    }
    "status" {
        $running = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $port }
        if ($running) {
            try {
                $r = Invoke-WebRequest -Uri "http://127.0.0.1:$port/health" -UseBasicParsing -TimeoutSec 3
                Write-Host $r.Content -ForegroundColor Green
            } catch {
                Write-Host "Port listening but not responding" -ForegroundColor Yellow
            }
        } else {
            Write-Host "MCP server is NOT running on port $port" -ForegroundColor Red
        }
    }
    "tools" {
        try {
            $r = Invoke-WebRequest -Uri "http://127.0.0.1:$port/tools" -UseBasicParsing -TimeoutSec 3
            $j = $r.Content | ConvertFrom-Json
            Write-Host "MCP tools ($($j.tools.Count)):" -ForegroundColor Cyan
            foreach ($t in $j.tools) {
                Write-Host "  $($t.name) — $($t.description)" -ForegroundColor White
            }
        } catch {
            Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}