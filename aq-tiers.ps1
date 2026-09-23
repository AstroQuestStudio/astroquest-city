#requires -Version 5
<#
.SYNOPSIS
    aq tiers â€” pretty-print all available model tiers with fallback chains.
#>

$proxy = "http://127.0.0.1:4000"
$auth = "Bearer sk-aq-local"

try {
    $r = Invoke-WebRequest -Uri "$proxy/v1/models" -UseBasicParsing -TimeoutSec 10
    $j = $r.Content | ConvertFrom-Json
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "AstroQuest City tiers (total: $($j.data.Count))" -ForegroundColor Cyan
Write-Host ""
foreach ($tier in $j.data) {
    $chain = $tier.chain -join " -> "
    Write-Host ("[primary {0,-20}] {1,-30} chain({2})" -f $tier.owned_by, $tier.id, $tier.chain_length) -ForegroundColor White -NoNewline
    Write-Host ""
    Write-Host ("    " + $chain) -ForegroundColor DarkGray
    Write-Host ""
}