#requires -Version 5
<#
.SYNOPSIS
    aq run "task description" — spawns a task in a fresh git worktree + agent run.
    Like `git worktree add` but combined with our task tracking.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Prompt
)

$proxy = "http://127.0.0.1:4000"
$auth = "Bearer sk-aq-local"

# 1) Create the task
Write-Host "[1/3] Creating task..." -ForegroundColor Cyan
try {
    $task = Invoke-WebRequest -Uri "$proxy/v1/tasks" -Method POST `
        -Headers @{
            "Content-Type"  = "application/json"
            "Authorization" = $auth
        } `
        -Body (@{ prompt = $Prompt; tier = "auto" } | ConvertTo-Json -Compress) `
        -UseBasicParsing `
        -TimeoutSec 10
    $j = $task.Content | ConvertFrom-Json
    $taskId = $j.id
    Write-Host "  task_id = $taskId" -ForegroundColor Green
} catch {
    Write-Host "FAIL creating task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2) Create a worktree for it
Write-Host "[2/3] Spawning git worktree..." -ForegroundColor Cyan
try {
    $wt = Invoke-WebRequest -Uri "$proxy/v1/worktrees/$taskId" -Method POST `
        -Headers @{
            "Content-Type"  = "application/json"
            "Authorization" = $auth
        } `
        -Body "{}" `
        -UseBasicParsing `
        -TimeoutSec 15
    $wj = $wt.Content | ConvertFrom-Json
    Write-Host "  branch = $($wj.branch)" -ForegroundColor Green
    Write-Host "  worktree = $($wj.path)" -ForegroundColor Green
} catch {
    Write-Host "FAIL creating worktree: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  (continuing without worktree)" -ForegroundColor DarkGray
}

# 3) Run the prompt through the Smart Router (so the task gets executed)
Write-Host "[3/3] Routing prompt via Smart Tier Auto-Router..." -ForegroundColor Cyan
try {
    $r = Invoke-WebRequest -Uri "$proxy/v1/auto/chat/completions" -Method POST `
        -Headers @{
            "Content-Type"  = "application/json"
            "Authorization" = $auth
        } `
        -Body (@{
            messages = @(@{ role = "user"; content = $Prompt })
            max_tokens = 2048
        } | ConvertTo-Json -Depth 4 -Compress) `
        -UseBasicParsing `
        -TimeoutSec 120
    $rj = $r.Content | ConvertFrom-Json
    $tier = $r.Headers["X-AO-Smart-Tier"][0]
    Write-Host "  tier = $tier, provider = $($rj._provider), model = $($rj.model)" -ForegroundColor Green
    Write-Host "  tokens = $($rj.usage.total_tokens)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "=== RESPONSE ===" -ForegroundColor Cyan
    Write-Host $rj.choices[0].message.content
    Write-Host "=== END ===" -ForegroundColor Cyan
} catch {
    Write-Host "FAIL running prompt: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}