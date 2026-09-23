#requires -Version 5
<#
.SYNOPSIS
    aq-repl — interactive REPL that proxies every line to the AQ Smart Tier Auto-Router.
    Same UX as typing in the Tauri UI but in your terminal.

.EXAMPLE
    .\aq-repl.ps1
    # then type your prompts, get responses, 'exit' to quit
#>

$proxy = "http://127.0.0.1:4000"
$auth = "Bearer sk-aq-local"
$historyPath = "$env:USERPROFILE\.aq\repl_history.txt"

# Ensure ~/.aq exists
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.aq" | Out-Null

Write-Host "AQ REPL — type your prompts, 'exit' to quit, ':tier tier-name' to override, ':clear' to reset history." -ForegroundColor Cyan
Write-Host "Connected to $proxy" -ForegroundColor DarkGray
Write-Host ""

$history = New-Object System.Collections.Generic.List[string]

function Send-Prompt($prompt, $tier = "auto") {
    $body = @{
        messages = @(
            $history | ForEach-Object { @{ role = "user"; content = $_ } }
        ) + @(@{ role = "user"; content = $prompt })
        max_tokens = 2048
        temperature = 0.4
    } | ConvertTo-Json -Depth 8 -Compress

    try {
        $r = Invoke-WebRequest -Uri "$proxy/v1/auto/chat/completions" -Method POST `
            -Headers @{
                "Content-Type"  = "application/json"
                "Authorization" = $auth
            } `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 120
        $j = $r.Content | ConvertFrom-Json
        $content = $j.choices[0].message.content
        $tierUsed = $r.Headers["X-AO-Smart-Tier"][0]
        $provider = $j._provider
        $tokens = $j.usage.total_tokens

        Write-Host ""
        Write-Host "[$tierUsed / $provider / $tokens tok]" -ForegroundColor DarkGray
        Write-Host $content -ForegroundColor White
        Write-Host ""

        # Append to history
        $history.Add("[user] $prompt")
        $history.Add("[assistant] $content")

        # Persist history (truncate to last 50 turns to keep file small)
        $history | Select-Object -Last 100 | Out-File -FilePath $historyPath -Encoding utf8 -Force
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Reset-History {
    $script:history.Clear()
    Remove-Item -Force $historyPath -ErrorAction SilentlyContinue
    Write-Host "[history cleared]" -ForegroundColor Yellow
}

# Load previous history if present
if (Test-Path $historyPath) {
    $lines = Get-Content $historyPath -ErrorAction SilentlyContinue
    foreach ($l in $lines) { $history.Add($l) }
    if ($history.Count -gt 0) {
        Write-Host "[loaded $($history.Count) previous turns from $historyPath]" -ForegroundColor DarkGray
    }
}

while ($true) {
    $line = Read-Host "you"
    $line = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -eq "exit" -or $line -eq "quit") { break }
    if ($line -eq ":clear") { Reset-History; continue }
    if ($line -like ":tier *") {
        # Send the rest as the prompt with the forced tier
        $forcedTier = $line.Substring(6).Trim()
        $nextLine = Read-Host "you (tier=$forcedTier)"
        if ($nextLine -and $nextLine -ne "exit") {
            Send-Prompt -prompt $nextLine -tier $forcedTier
        }
        continue
    }
    if ($line.StartsWith("/")) { continue }  # skip command-like lines

    Send-Prompt -prompt $line -tier "auto"
}

Write-Host ""
Write-Host "[bye]" -ForegroundColor Cyan