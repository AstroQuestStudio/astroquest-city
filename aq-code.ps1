#requires -Version 5
<#
.SYNOPSIS
    aq code "task description" -- delegates to opencode run for full coding agent
    with file edits, tools, LSP, multi-turn. Tracks task in Kanban.

.EXAMPLE
    .\aq-code.ps1 -Prompt "Add a /healthz endpoint to the Rust server"
    .\aq-code.ps1 -Prompt "Refactor the parser to use anyhow" -Agent build
    .\aq-code.ps1 -Prompt "What does this codebase do?" -Agent plan
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Prompt
)
# Optional: --agent <name> and --model <id> from remaining args
$Agent = "build"
$Model = "groq/openai/gpt-oss-120b"   # default: proven to work via env GROQ_API_KEY
$NoWorktree = $false
for ($i = 1; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "--agent" { $Agent = $args[$i + 1]; $i++ }
        "--model" { $Model = $args[$i + 1]; $i++ }
        "--no-worktree" { $NoWorktree = $true }
    }
}

$proxy = "http://127.0.0.1:4000"
$auth = "Bearer sk-aq-local"
$opencode = "C:\Users\trufa\.opencode\bin\opencode.exe"

# Pre-flight checks
if (-not (Test-Path $opencode)) {
    Write-Host "opencode not found at $opencode" -ForegroundColor Red
    Write-Host "Install: curl -fsSL https://opencode.ai/install | bash" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== AQ CODE ===" -ForegroundColor Cyan
Write-Host "opencode engine: $opencode"
Write-Host "agent: $Agent"
if ($Model) { Write-Host "model: $Model" }
Write-Host "prompt: $Prompt"
Write-Host ""

# 1) Task tracking (so it shows in the Kanban)
$taskId = $null
Write-Host "[1/3] Creating task in Kanban..." -ForegroundColor Cyan
try {
    $task = Invoke-WebRequest -Uri "$proxy/v1/tasks" -Method POST `
        -Headers @{ "Content-Type" = "application/json"; "Authorization" = $auth } `
        -Body (@{ prompt = $Prompt; tier = "auto" } | ConvertTo-Json -Compress) `
        -UseBasicParsing -TimeoutSec 10
    $j = $task.Content | ConvertFrom-Json
    $taskId = $j.id
    Write-Host "  task_id = $taskId" -ForegroundColor Green
} catch {
    Write-Host "  (task tracking unavailable, continuing without Kanban)" -ForegroundColor DarkGray
}

# 2) Git worktree isolation (optional)
$worktreePath = $null
if (-not $NoWorktree) {
    Write-Host "[2/3] Spawning git worktree..." -ForegroundColor Cyan
    if ($taskId) {
        try {
            $wt = Invoke-WebRequest -Uri "$proxy/v1/worktrees/$taskId" -Method POST `
                -Headers @{ "Content-Type" = "application/json"; "Authorization" = $auth } `
                -Body "{}" -UseBasicParsing -TimeoutSec 15
            $wj = $wt.Content | ConvertFrom-Json
            $worktreePath = $wj.path
            Write-Host "  branch = $($wj.branch)" -ForegroundColor Green
            Write-Host "  worktree = $worktreePath" -ForegroundColor Green
        } catch {
            Write-Host "  (worktree failed, running in current dir)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  (no task_id, skipping worktree)" -ForegroundColor DarkGray
    }
}

# 3) Delegate to opencode run
Write-Host "[3/3] Delegating to opencode run..." -ForegroundColor Cyan
Write-Host ""

# Build args
$ocArgs = @("run", "--agent", $Agent)
if ($Model) { $ocArgs += @("--model", $Model) }
$ocArgs += @("--title", "AQ task $taskId")
$ocArgs += $Prompt

if ($worktreePath) {
    Push-Location $worktreePath
}
try {
    & $opencode $ocArgs
    $exitCode = $LASTEXITCODE
} finally {
    if ($worktreePath) { Pop-Location }
}

# 4) Mark task done
if ($taskId) {
    try {
        Invoke-WebRequest -Uri "$proxy/v1/tasks/$taskId" -Method PATCH `
            -Headers @{ "Content-Type" = "application/json"; "Authorization" = $auth } `
            -Body (@{ status = "done" } | ConvertTo-Json -Compress) `
            -UseBasicParsing -TimeoutSec 5 | Out-Null
        Write-Host "[aq-code] task $taskId marked done" -ForegroundColor DarkGray
    } catch {}
}

exit $exitCode
