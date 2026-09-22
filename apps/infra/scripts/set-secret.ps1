<#
.SYNOPSIS
    Set or update one secret in apps/infra/.env (preserves all others)
.DESCRIPTION
    Idempotent. Adds the key if absent, replaces if present.
    Backs up the .env before writing.
.PARAMETER Key
    Name of the env var (e.g. GEMINI_API_KEY, GROQ_KEY_22)
.PARAMETER Value
    Value to set
.EXAMPLE
    powershell -File set-secret.ps1 -Key GEMINI_API_KEY -Value "AIza..."
    powershell -File set-secret.ps1 -Key GROQ_KEY_22 -Value "gsk_..."
.NOTES
    Use unset-secret.ps1 to remove, show-env.ps1 to list.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Key,
    [Parameter(Mandatory)][string]$Value
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$envPath = Join-Path $root 'apps\infra\.env'

if (-not (Test-Path $envPath)) {
    Write-Host "[!] .env absent : $envPath" -ForegroundColor Yellow
    Write-Host "    Lance d'abord : powershell -File bootstrap-env.ps1" -ForegroundColor Yellow
    exit 1
}

# Backup
$bak = "$envPath.bak." + (Get-Date -Format 'yyyyMMdd-HHmmss')
Copy-Item $envPath $bak
Write-Host "[i] Backup : $bak"

# Load existing
$lines = @(Get-Content $envPath -Encoding UTF8)
$found = $false
$newLines = for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match "^$([regex]::Escape($Key))\s*=") {
        $found = $true
        "$Key=$Value"
    } else {
        $line
    }
}
if (-not $found) {
    $newLines += "$Key=$Value"
}

Set-Content -Path $envPath -Value ($newLines -join "`n") -Encoding UTF8 -NoNewline
if ($found) {
    Write-Host "[OK] $Key mis a jour" -ForegroundColor Green
} else {
    Write-Host "[OK] $Key ajoute" -ForegroundColor Green
}

# Masque pour les logs
$masked = if ($Value.Length -gt 12) {
    $Value.Substring(0, 6) + ('*' * [Math]::Max(0, $Value.Length - 10)) + $Value.Substring($Value.Length - 4)
} else {
    '****'
}
Write-Host "     Valeur : $masked"