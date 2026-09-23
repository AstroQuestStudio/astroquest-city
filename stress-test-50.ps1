#requires -Version 5
<#
.SYNOPSIS
    Spawns 50 parallel agent tasks via the AQ Smart Tier Auto-Router,
    measures throughput, fail rate, and average latency.

.EXAMPLE
    .\stress-test-50.ps1
#>

param(
    [int]$Count = 50,
    [int]$MaxConcurrency = 20,
    [string]$Proxy = "http://127.0.0.1:4000"
)

Write-Host "=== AQ Stress Test: $Count parallel agent tasks ===" -ForegroundColor Cyan
Write-Host "Proxy: $Proxy"
Write-Host "Max concurrency: $MaxConcurrency"
Write-Host ""

$prompts = @(
    "What is 2+2? Reply in one word.",
    "Name three colors.",
    "Say hello.",
    "What is the capital of Japan?",
    "Count to 5.",
    "What's 10*10?",
    "Name a fruit.",
    "Is fire hot? Yes or no.",
    "What's the opposite of day?",
    "Name one planet.",
    "What color is the sky on a sunny day?",
    "How many legs does a dog have?",
    "What's 100/4?",
    "Name a mammal.",
    "What comes after Tuesday?",
    "Is water wet?",
    "What is 5+7?",
    "Name a metal.",
    "What's 3*3?",
    "Say goodbye.",
    "What's the first letter of the alphabet?",
    "How many days in a year?",
    "Name a vegetable.",
    "What's 50+25?",
    "Is ice cold?",
    "Name an animal that flies.",
    "What's 9-4?",
    "What's the capital of Italy?",
    "Name a bird.",
    "How many continents are there?",
    "What's 6*7?",
    "Name a flower.",
    "What comes before Monday?",
    "Is snow white?",
    "What's 12+8?",
    "Name an insect.",
    "What's the biggest ocean?",
    "Name a fish.",
    "What's 15+15?",
    "Is gold a metal?",
    "Name a tree.",
    "What's 100-50?",
    "How many hours in a day?",
    "Name a desert.",
    "What's 11*11?",
    "What's the boiling point of water in Celsius?",
    "Name a sport.",
    "What's 30/6?",
    "How many colors in a rainbow?",
    "Name a country in Asia.",
    "What's 7+8?"
)

if ($prompts.Count -lt $Count) {
    Write-Host "[warn] only $($prompts.Count) prompts defined, padding with repeats" -ForegroundColor Yellow
}

Write-Host "[1/3] Spawning $Count tasks via /v1/tasks POST..." -ForegroundColor Cyan
$createdIds = @()
$sw = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt $Count; $i++) {
    $prompt = $prompts[$i % $prompts.Count]
    try {
        $r = Invoke-WebRequest -Uri "$Proxy/v1/tasks" -Method POST `
            -Headers @{
                "Content-Type"  = "application/json"
                "Authorization" = "Bearer sk-aq-local"
            } `
            -Body (@{ prompt = $prompt; tier = "auto" } | ConvertTo-Json -Compress) `
            -UseBasicParsing `
            -TimeoutSec 5
        $j = $r.Content | ConvertFrom-Json
        $createdIds += $j.id
    } catch {
        Write-Host "  [fail] $($_.Exception.Message)" -ForegroundColor Red
    }
}
$sw.Stop()
Write-Host "  created $($createdIds.Count)/$Count in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s" -ForegroundColor Green
Write-Host ""

Write-Host "[2/3] Triggering tasks via /v1/auto/chat/completions (smart router)..." -ForegroundColor Cyan
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$results = @()
$runningPool = @()

# Use a thread-safe collection
$bag = [System.Collections.Concurrent.ConcurrentBag[object]]::new()

# Throttle to MaxConcurrency using semaphores
$sem = [System.Threading.SemaphoreSlim]::new($MaxConcurrency, $MaxConcurrency)

# Use a script block invoked via runspace
$jobs = @()
for ($i = 0; $i -lt $Count; $i++) {
    $prompt = $prompts[$i % $prompts.Count]
    $idx = $i

    $job = Start-ThreadJob -ArgumentList $Proxy, $prompt, $idx -ScriptBlock {
        param($p, $q, $i)
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $r = Invoke-WebRequest -Uri "$p/v1/auto/chat/completions" -Method POST `
                -Headers @{
                    "Content-Type"  = "application/json"
                    "Authorization" = "Bearer sk-aq-local"
                } `
                -Body (@{
                    messages = @(@{ role = "user"; content = $q })
                    max_tokens = 100
                    temperature = 0.1
                } | ConvertTo-Json -Depth 5 -Compress) `
                -UseBasicParsing `
                -TimeoutSec 90
            $stopwatch.Stop()
            $j = $r.Content | ConvertFrom-Json
            return @{
                idx = $i
                ok = $true
                status = $r.StatusCode
                tier = $r.Headers["X-AO-Smart-Tier"][0]
                provider = $j._provider
                model = $j.model
                tokens = $j.usage.total_tokens
                latency_ms = $stopwatch.ElapsedMilliseconds
                preview = ($j.choices[0].message.content -replace "`n", " ").Substring(0, [Math]::Min(60, $j.choices[0].message.content.Length))
            }
        } catch {
            $stopwatch.Stop()
            return @{
                idx = $i
                ok = $false
                error = $_.Exception.Message
                latency_ms = $stopwatch.ElapsedMilliseconds
            }
        }
    }
    $jobs += $job
}

# Wait for all jobs
$jobs | ForEach-Object {
    $_ | Wait-Job | Out-Null
    $res = Receive-Job -Job $_
    $results += $res
    Remove-Job -Job $_ -Force
}
$sw.Stop()
Write-Host "  all $Count responses received in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s" -ForegroundColor Green
Write-Host ""

Write-Host "[3/3] Computing stats..." -ForegroundColor Cyan
$okCount = ($results | Where-Object { $_.ok }).Count
$failCount = ($results | Where-Object { -not $_.ok }).Count
$totalTokens = ($results | Where-Object { $_.ok } | ForEach-Object { $_.tokens }) | Measure-Object -Sum
$latencies = ($results | Where-Object { $_.ok } | ForEach-Object { $_.latency_ms }) | Sort-Object
$providerCounts = ($results | Where-Object { $_.ok } | Group-Object provider | Select-Object @{n='provider';e={$_.Name}}, @{n='count';e={$_.Count}}, @{n='avg_tokens';e={[math]::Round((($_.Group | ForEach-Object { $_.tokens }) | Measure-Object -Average).Average, 1)}})
$tierCounts = ($results | Where-Object { $_.ok } | Group-Object tier | Select-Object @{n='tier';e={$_.Name}}, @{n='count';e={$_.Count}})

Write-Host ""
Write-Host "=== RESULTS ===" -ForegroundColor Green
Write-Host "Success:   $okCount / $Count"
Write-Host "Failures:  $failCount"
Write-Host "Throughput: $([math]::Round($Count / $sw.Elapsed.TotalSeconds, 2)) req/s"
Write-Host "Total tokens: $($totalTokens.Sum)"
Write-Host ""
Write-Host "Latency stats (successful only):"
if ($latencies.Count -gt 0) {
    $p50 = $latencies[[Math]::Floor($latencies.Count * 0.5)]
    $p95 = $latencies[[Math]::Floor($latencies.Count * 0.95)]
    $p99 = $latencies[[Math]::Floor($latencies.Count * 0.99)]
    Write-Host "  p50: $p50 ms"
    Write-Host "  p95: $p95 ms"
    Write-Host "  p99: $p99 ms"
    Write-Host "  avg: $([Math]::Round((($latencies | Measure-Object -Average).Average), 0)) ms"
}
Write-Host ""
Write-Host "By provider:"
$providerCounts | Format-Table -AutoSize
Write-Host "By tier:"
$tierCounts | Format-Table -AutoSize

if ($failCount -gt 0) {
    Write-Host ""
    Write-Host "Failures (first 5):" -ForegroundColor Red
    $results | Where-Object { -not $_.ok } | Select-Object -First 5 | ForEach-Object {
        Write-Host "  [$($_.idx)] $($_.error)"
    }
}

Write-Host ""
Write-Host "=== Tasks in store ==="
try {
    $r = Invoke-WebRequest -Uri "$Proxy/v1/tasks/stats" -UseBasicParsing -TimeoutSec 5
    Write-Host $r.Content
} catch {
    Write-Host "  FAIL: $($_.Exception.Message)"
}