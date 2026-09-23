#requires -Version 5
<#
.SYNOPSIS
    install-aq — adds the AstroQuest City `aq` command to your user PATH
    so you can type `aq "your prompt"` from any directory.

.EXAMPLE
    .\install-aq.ps1
    # Now from any directory:
    aq "Write a Rust hello world"
    aq doctor
    aq run "Refactor LRU cache"
    aq chat
#>

$ErrorActionPreference = "Stop"

# 1. Find where the user wants aq.cmd to live (default: scripts dir in user profile)
$aqRoot = (Resolve-Path "$PSScriptRoot").Path
$aqCmd = Join-Path $aqRoot "aq.cmd"

if (-not (Test-Path $aqCmd)) {
    Write-Host "ERROR: aq.cmd not found at $aqCmd" -ForegroundColor Red
    exit 1
}

# 2. Create a bin directory in user profile if missing
$userBin = Join-Path $env:USERPROFILE "bin"
if (-not (Test-Path $userBin)) {
    New-Item -ItemType Directory -Force -Path $userBin | Out-Null
    Write-Host "Created $userBin" -ForegroundColor Cyan
}

# 3. Hard-link all aq.* scripts into the bin directory
$scriptsToLink = @(
    "aq.cmd",
    "aq-coder.ps1",
    "aq-repl.ps1",
    "aq-run-task.ps1",
    "aq-tiers.ps1",
    "aq-compact.ps1",
    "aq-mcp.ps1",
    "aq-doctor.ps1"
)
foreach ($script in $scriptsToLink) {
    $src = Join-Path $aqRoot $script
    if (-not (Test-Path $src)) { continue }
    $dst = Join-Path $userBin $script
    if (Test-Path $dst) { Remove-Item $dst -Force }
    try {
        $cmd = 'cmd /c mklink /H "' + $dst + '" "' + $src + '"'
        Invoke-Expression $cmd 2>&1 | Out-Null
        if (Test-Path $dst) {
            Write-Host "  Linked $script" -ForegroundColor DarkGray
        } else {
            throw "mklink failed"
        }
    } catch {
        Copy-Item -Path $src -Destination $dst -Force
        Write-Host "  Copied $script" -ForegroundColor DarkGray
    }
}

# 4. Add ~/bin to user PATH if missing
$currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentUserPath -notlike "*$userBin*") {
    $newPath = if ($currentUserPath) { "$currentUserPath;$userBin" } else { $userBin }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added $userBin to user PATH" -ForegroundColor Green
    # Also update current session
    $env:Path = "$env:Path;$userBin"
} else {
    Write-Host "$userBin already in user PATH" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Installation complete!"
Write-Host ""
Write-Host "Test from a new terminal:"
Write-Host "  cd C:\Users\trufa\Documents"
Write-Host "  aq --version"
Write-Host "  aq say hello in 3 words"
Write-Host ""
Write-Host "Note: open a NEW terminal window so the PATH update takes effect"