<#
.SYNOPSIS
    List all keys in apps/infra/.env with masked values
.EXAMPLE
    powershell -File show-env.ps1
    powershell -File show-env.ps1 -Key GEMINI_API_KEY   # show one full value
#>
[CmdletBinding()]
param(
    [string]$Key
)

$ErrorActionPreference = 'Continue'
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$envPath = Join-Path $root 'apps\infra\.env'

if (-not (Test-Path $envPath)) {
    Write-Host "[!] .env absent" -ForegroundColor Yellow
    exit 1
}

$lines = Get-Content $envPath -Encoding UTF8 | Where-Object {
    $_ -match '^[A-Z_][A-Z0-9_]*=' -and $_ -notmatch '^\s*#'
}

function Mask-Value([string]$v) {
    if ([string]::IsNullOrWhiteSpace($v)) { return '<vide>' }
    if ($v.Length -le 12) { return '****' }
    return $v.Substring(0, 6) + ('*' * [Math]::Max(0, $v.Length - 10)) + $v.Substring($v.Length - 4)
}

if ($Key) {
    $match = $lines | Where-Object { $_ -match "^$([regex]::Escape($Key))\s*=" } | Select-Object -First 1
    if ($match) {
        $val = ($match -split '=', 2)[1]
        Write-Host "$Key = $val"
    } else {
        Write-Host "[!] $Key absent" -ForegroundColor Yellow
    }
    exit 0
}

# Liste complete
Write-Host "=== apps/infra/.env (masque) ==="
$count = 0
foreach ($line in $lines) {
    if ($line -match '^([A-Z_][A-Z0-9_]*)\s*=\s*(.*)$') {
        $k = $Matches[1]
        $v = $Matches[2]
        $masked = Mask-Value $v
        $count++
        $pad = 22
        if ($k.Length -gt $pad) { $pad = $k.Length + 2 }
        Write-Host ("  {0,-$pad} = {1}" -f $k, $masked)
    }
}
Write-Host ""
Write-Host "Total : $count cles"