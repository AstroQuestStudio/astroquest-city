#requires -Version 5
<#
.SYNOPSIS
    aq doctor / status â€” health check for AQ City components.
#>

param([switch]$Quick)

$services = @(
    [pscustomobject]@{ Name = "Tauri App";   Port = $null; ProcessName = "create-tauri-react" }
    [pscustomobject]@{ Name = "Local Proxy"; Port = 4000;  ProcessName = "create-tauri-react" }
    [pscustomobject]@{ Name = "OpenCode CLI"; Port = 4097; ProcessName = "opencode" }
    [pscustomobject]@{ Name = "MCP Server";  Port = 6789;  ProcessName = "node" }
)

Write-Host "=== AQ Doctor ===" -ForegroundColor Cyan
Write-Host ""

$ok = 0
$total = 0
foreach ($s in $services) {
    $total++
    if ($s.Port) {
        $c = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $s.Port }
        if (-not $c) {
            Write-Host "  [FAIL] $($s.Name) - port $($s.Port) NOT listening" -ForegroundColor Red
            continue
        }
    }
    $p = Get-Process -Name $s.ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $p) {
        Write-Host "  [FAIL] $($s.Name) - no process named '$($s.ProcessName)'" -ForegroundColor Red
        continue
    }
    $ws = [math]::Round($p.WorkingSet64/1MB, 1)
    $portText = ""
    if ($s.Port) { $portText = ", port $($s.Port)" }
    Write-Host "  [ OK ] $($s.Name) (PID $($p.Id), WS ${ws}MB$portText)" -ForegroundColor Green
    $ok++
}

Write-Host ""
Write-Host "Summary: $ok/$total services healthy" -ForegroundColor $(if ($ok -eq $total) {"Green"} else {"Yellow"})

Write-Host ""
Write-Host "=== Files ===" -ForegroundColor Cyan
$aqDir = "$env:USERPROFILE\.aq"
$files = @(
    [pscustomobject]@{ Name = "Workspace keys";  Path = "$aqDir\keys.json" }
    [pscustomobject]@{ Name = "Task store";      Path = "$aqDir\tasks.json" }
    [pscustomobject]@{ Name = "Cloudflare Worker code"; Path = "$PSScriptRoot\apps\relay-cf" }
    [pscustomobject]@{ Name = "MCP server code"; Path = "$PSScriptRoot\apps\mcp-server" }
)
foreach ($f in $files) {
    if (Test-Path $f.Path) {
        Write-Host "  [ OK ] $($f.Name) - $($f.Path)" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] $($f.Name) - NOT FOUND: $($f.Path)" -ForegroundColor Yellow
    }
}

if (-not $Quick) {
    Write-Host ""
    Write-Host "=== Key counts ===" -ForegroundColor Cyan
    $keysFile = "$aqDir\keys.json"
    if (Test-Path $keysFile) {
        try {
            $keys = Get-Content $keysFile -Raw | ConvertFrom-Json
            Write-Host "  Groq keys:    $(if ($keys.groq_keys) { $keys.groq_keys.Count } else { 0 })" -ForegroundColor White
            Write-Host "  Gemini keys:  $(if ($keys.gemini_keys) { $keys.gemini_keys.Count } else { 0 })" -ForegroundColor White
            Write-Host "  NVIDIA keys:  $(if ($keys.nvidia_keys) { $keys.nvidia_keys.Count } else { 0 })" -ForegroundColor White
            Write-Host "  Has MiniMax:   $(if ($keys.minimax_key) { 'YES' } else { 'no' })" -ForegroundColor White
            Write-Host "  Has Anthropic: $(if ($keys.anthropic_key) { 'YES' } else { 'no' })" -ForegroundColor White
        } catch {
            Write-Host "  keys.json malformed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  No keys.json found. Run import-keys.ps1" -ForegroundColor Yellow
    }
}