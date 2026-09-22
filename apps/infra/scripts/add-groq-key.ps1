<#
.SYNOPSIS
    Add a new Groq key to .env AND add a corresponding entry to litellm/config.yaml
.DESCRIPTION
    Auto-increments the GROQ_KEY_NN counter. Backs up both files.
.EXAMPLE
    powershell -File add-groq-key.ps1 -Value "gsk_xxxxxxxxxxxxxxxxxxxxxxxxxx"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Value
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$envPath = Join-Path $root 'apps\infra\.env'
$configPath = Join-Path $root 'apps\infra\litellm\config.yaml'

if (-not (Test-Path $envPath)) {
    Write-Host "[!] .env absent" -ForegroundColor Yellow
    exit 1
}
if (-not (Test-Path $configPath)) {
    Write-Host "[!] config.yaml absent" -ForegroundColor Yellow
    exit 1
}

# Trouver le prochain numero
$lines = Get-Content $envPath -Encoding UTF8
$groqKeys = @()
foreach ($line in $lines) {
    if ($line -match '^GROQ_KEY_(\d+)\s*=') {
        $groqKeys += [int]$Matches[1]
    }
}
if ($groqKeys.Count -eq 0) {
    $next = 1
} else {
    $next = ($groqKeys | Measure-Object -Maximum).Maximum + 1
}
$pad = if ($next -lt 10) { '0' + $next } else { "$next" }
$varName = "GROQ_KEY_$pad"

Write-Host "[i] Prochaine cle : $varName"

# 1) Inserer dans .env via set-secret
& "$PSScriptRoot\set-secret.ps1" -Key $varName -Value $Value

# 2) Ajouter l'entree dans config.yaml
$bak = "$configPath.bak." + (Get-Date -Format 'yyyyMMdd-HHmmss')
Copy-Item $configPath $bak

$yaml = Get-Content $configPath -Raw
$marker = "# FIN POOL GROQ -- fin du bloc automatiquement edite"
if ($yaml -notmatch $marker) {
    # Premiere execution : ajouter le marker apres la derniere entree tier-4-groq
    $pattern = "(- model_name: ""tier-4-groq""[\s\S]*?max_tokens: 4096\s*\n)(\s*- model_name: ""tier-3-formatteur"")"
    $replacement = "`$1  # FIN POOL GROQ -- fin du bloc automatiquement edite`n`n`$2"
    $yaml = $yaml -replace $pattern, $replacement, 1
}

$newEntry = @"

  - model_name: "tier-4-groq"
    litellm_params:
      model: groq/openai/gpt-oss-120b
      api_key: os.environ/$varName
      rpm: 30
      max_tokens: 4096
"@
$yaml = $yaml -replace [regex]::Escape("# FIN POOL GROQ -- fin du bloc automatiquement edite"), ($newEntry.TrimStart() + "`n  # FIN POOL GROQ -- fin du bloc automatiquement edite")

Set-Content -Path $configPath -Value $yaml -Encoding UTF8 -NoNewline
Write-Host "[OK] Entree ajoutee dans config.yaml pour $varName" -ForegroundColor Green
Write-Host "     Backup : $bak"
Write-Host ""
Write-Host "Prochaines etapes :"
Write-Host "  1. Copier .env et config.yaml sur VPS3 (ou laisser le deploiement auto)"
Write-Host "  2. ssh root@46.224.170.108 'cd /opt/aq-app/infra && docker compose restart litellm'"