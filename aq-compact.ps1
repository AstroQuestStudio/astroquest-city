#requires -Version 5
<#
.SYNOPSIS
    aq compact — manually invoke context compaction endpoint.
    Useful before running a long task to summarize old context.
#>

$proxy = "http://127.0.0.1:4000"
$auth = "Bearer sk-aq-local"

Write-Host "Context compaction endpoint:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  POST $proxy/v1/compact" -ForegroundColor DarkGray
Write-Host "  Body: { messages: [...], keep_last: 5 }" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Or use it from aq chat — it auto-compacts when context exceeds threshold." -ForegroundColor DarkGray
Write-Host ""
Write-Host "Live test:" -ForegroundColor Cyan
$body = @{
    messages = @(
        @{ role = "user"; content = "First, we discussed Rust error handling. We decided to use anyhow for ergonomic error propagation." }
        @{ role = "assistant"; content = "Agreed. anyhow is great for applications, thiserror for libraries." }
        @{ role = "user"; content = "Then we talked about async. Tokio vs async-std. We chose tokio." }
        @{ role = "assistant"; content = "Tokio is more mature, has wider ecosystem support." }
        @{ role = "user"; content = "Finally, we discussed build times. sccache helps a lot." }
        @{ role = "assistant"; content = "sccache + mold = fast builds." }
        @{ role = "user"; content = "What about testing? mockall vs manual mocks?" }
    )
    keep_last = 3
} | ConvertTo-Json -Depth 4 -Compress

try {
    $r = Invoke-WebRequest -Uri "$proxy/v1/compact" -Method POST `
        -Headers @{
            "Content-Type"  = "application/json"
            "Authorization" = $auth
        } `
        -Body $body `
        -UseBasicParsing `
        -TimeoutSec 30
    $j = $r.Content | ConvertFrom-Json
    Write-Host "  compacted_count: $($j.compacted_count)" -ForegroundColor Green
    Write-Host "  tokens_saved_est: $($j.tokens_saved)" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
    Write-Host $j.summary
    Write-Host ""
    Write-Host "=== KEPT MESSAGES ($($j.kept_messages.Count)) ===" -ForegroundColor Cyan
    foreach ($m in $j.kept_messages) {
        Write-Host "  $($m.role): $($m.content.Substring(0, [Math]::Min(60, $m.content.Length)))..."
    }
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
}