#requires -Version 5
<#
.SYNOPSIS
    Tests the Smart Tier Auto-Router by calling /v1/auto/route with 5
    different prompt styles. Prints the chosen tier + reason for each.
#>

$proxy = "http://127.0.0.1:4000"
$auth = "Bearer sk-aq-local"

$prompts = @(
    @{
        Name = "FORMAT (short, lint keyword)"
        Prompt = "Format this Rust file: add doc comments to fn main."
    },
    @{
        Name = "CODE (medium, function keyword)"
        Prompt = "Write a Rust function called `parse_url` that takes a &str and returns a Result<Url, ParseError>. Handle invalid input gracefully."
    },
    @{
        Name = "SEARCH (find/where keyword)"
        Prompt = "Find all places in the codebase where the Opencode CLI is invoked and explain how they differ."
    },
    @{
        Name = "STRATEGIC (long-context + roadmap)"
        Prompt = "Here is the entire AstroQuest City project. Please provide a strategic roadmap for the next 6 months. Consider: we have 21 Groq keys, 12 Gemini AQ. keys, a Cloudflare Worker relay for multi-IP rotation, a Cortex pre-indexing system for 90 percent token savings, and a Tauri+R3F frontend. We want to build the perfect open-code-style agent OS with multi-agent task orchestration, then add an Autopolis-style city visualization layer on top. What should we prioritize? What should we defer? Where are the biggest risks?"
    },
    @{
        Name = "MULTIMODAL (image keyword)"
        Prompt = "Describe the image at https://example.com/screenshot.png — what UI elements are visible?"
    }
)

foreach ($p in $prompts) {
    Write-Host ""
    Write-Host "=== $($p.Name) ===" -ForegroundColor Yellow
    Write-Host "Prompt: $($p.Prompt.Substring(0, [Math]::Min(120, $p.Prompt.Length)))..." -ForegroundColor Gray
    $body = @{
        messages = @(
            @{ role = "user"; content = $p.Prompt }
        )
    } | ConvertTo-Json -Depth 4 -Compress

    try {
        $resp = Invoke-WebRequest -Uri "$proxy/v1/auto/route" `
            -Method POST `
            -Headers @{
                "Content-Type"  = "application/json"
                "Authorization" = $auth
            } `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 10
        $j = $resp.Content | ConvertFrom-Json
        Write-Host ("  chosen_tier: {0}" -f $j.chosen_tier) -ForegroundColor Cyan
        Write-Host ("  chain_length: {0}" -f $j.fallback_chain_length) -ForegroundColor DarkGray
        Write-Host ("  reason: {0}" -f $j.reason) -ForegroundColor DarkGray
        Write-Host ("  first fallback: {0}" -f $j.fallback_chain[0]) -ForegroundColor DarkCyan
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green