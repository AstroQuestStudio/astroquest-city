<#
.SYNOPSIS
    Remove one secret from apps/infra/.env (preserves all others)
.EXAMPLE
    powershell -File unset-secret.ps1 -Key GEMINI_API_KEY
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Key
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$envPath = Join-Path $root 'apps\infra\.env'

if (-not (Test-Path $envPath)) {
    Write-Host "[!] .env absent" -ForegroundColor Yellow
    exit 1
}

$bak = "$envPath.bak." + (Get-Date -Format 'yyyyMMdd-HHmmss')
Copy-Item $envPath $bak

$lines = @(Get-Content $envPath -Encoding UTF8)
$newLines = $lines | Where-Object { $_ -notmatch "^$([regex]::Escape($Key))\s*=" }
$removed = $lines.Count - $newLines.Count

Set-Content -Path $envPath -Value ($newLines -join "`n") -Encoding UTF8 -NoNewline
if ($removed -gt 0) {
    Write-Host "[OK] $Key supprime ($removed ligne(s))" -ForegroundColor Green
    Write-Host "     Backup : $bak"
} else {
    Remove-Item $bak -Force
    Write-Host "[i] $Key absent, rien a faire" -ForegroundColor Yellow
}