@echo off
REM aq.cmd — AstroQuest City CLI (opencode-style)
REM
REM Drop this in PATH (or its parent dir) and use `aq <subcommand>` from anywhere.
REM Inspired by opencode + Claude Code CLI patterns.
REM
REM Subcommands:
REM   aq "prompt"             Quick one-shot chat via Smart Tier Auto-Router
REM   aq chat                 Interactive REPL with history (similar to opencode)
REM   aq run "task"           Spawn an isolated git worktree + agent task
REM   aq tasks                List tasks (or `tasks create "prompt"` / `tasks delete <id>`)
REM   aq worktrees            List worktrees (or `worktrees create <task-id>` / `worktrees remove <path>`)
REM   aq tiers                List all model tiers + fallback chains
REM   aq route "prompt"       Show which tier would be chosen (debug)
REM   aq compact              Context compaction endpoint
REM   aq mcp start            Start the MCP server
REM   aq mcp stop             Stop the MCP server
REM   aq stats                Task + provider stats
REM   aq doctor               Run system health checks
REM   aq --version            Print version
REM   aq --help               This help

setlocal

set "SCRIPT_DIR=%~dp0"
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS%" set "PS=C:\Program Files\PowerShell\7\pwsh.exe"

set "PROXY=http://127.0.0.1:4000"
set "AUTH=sk-aq-local"
set "MCP_PORT=6789"

REM === Flags ===
if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="--version" goto :version
if "%~1"=="-V" goto :version

REM === Subcommands ===
if /I "%~1"=="chat"     goto :chat
if /I "%~1"=="run"      goto :run
if /I "%~1"=="tasks"    goto :tasks
if /I "%~1"=="worktrees" goto :worktrees
if /I "%~1"=="tiers"    goto :tiers
if /I "%~1"=="models"   goto :tiers
if /I "%~1"=="route"    goto :route
if /I "%~1"=="compact"  goto :compact
if /I "%~1"=="mcp"      goto :mcp
if /I "%~1"=="stats"    goto :stats
if /I "%~1"=="doctor"   goto :doctor
if /I "%~1"=="tui"      goto :tui
if /I "%~1"=="status"   goto :status
if /I "%~1"=="code"     goto :code
if /I "%~1"=="oc"       goto :oc

REM === Default: one-shot chat ===
REM Strip surrounding quotes from %* (cmd includes them)
set "AQ_PROMPT=%~1"
shift
:shift_args
if "%~1"=="" goto :shift_done
call set "AQ_PROMPT=%%AQ_PROMPT%% %~1"
shift
goto :shift_args
:shift_done
REM Write prompt to temp file, then read in PowerShell
set "AQ_PROMPT_FILE=%TEMP%\aq-prompt-%RANDOM%.txt"
> "%AQ_PROMPT_FILE%" echo %AQ_PROMPT%
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "& { $p = Get-Content -Raw -Path '%AQ_PROMPT_FILE%'; if ($p) { $p = $p.Trim() }; & '%SCRIPT_DIR%aq-coder.ps1' -Prompt \"$p\" -Tier auto -ShowChain }; Remove-Item -Force '%AQ_PROMPT_FILE%' -ErrorAction SilentlyContinue"
exit /b %ERRORLEVEL%

:version
echo aq 0.1.0 (AstroQuest City)
echo Tauri: apps\city\src-tauri\target\release\create-tauri-react.exe
echo Proxy: %PROXY%
echo MCP:   http://127.0.0.1:%MCP_PORT%
exit /b 0

:help
echo aq - AstroQuest City CLI (opencode-style)
echo.
echo Usage:
echo   aq "your prompt"                  One-shot chat via Smart Tier Auto-Router
echo   aq chat                           Interactive REPL with persistent history
echo   aq run "task description"         Spawn an isolated git worktree + agent task
echo   aq tasks [list^|create^|delete]    Manage the task queue
echo   aq worktrees [list^|create^|remove] Manage git worktrees
echo   aq tiers                          List all available model tiers + fallback chains
echo   aq route "prompt"                 Debug: show which tier would be chosen
echo   aq compact "prompt"               Force context compaction (summarize history)
echo   aq mcp start^|stop                Manage the MCP server
echo   aq stats                          Show task + provider stats
echo   aq doctor                         Run health checks (proxy, MCP, opencode)
echo   aq status                         Show running processes + ports
echo.
echo Examples:
echo   aq "What's the capital of France?"
echo   aq run "Refactor the LRU cache to use DashMap"
echo   aq chat              ^>^>  interactive mode with history
echo   aq tasks create "fix bug in main.rs"
echo   aq tiers             ^>^>  see all 22 tiers + 5-deep fallback chains
echo   aq route "Implement async Rust parser"
exit /b 0

:chat
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%aq-repl.ps1"
exit /b %ERRORLEVEL%

:run
set "TASK_DESC=%~2"
if "%TASK_DESC%"=="" (
    echo Usage: aq run "task description"
    exit /b 1
)
REM Create task + worktree in one go (idempotent)
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%aq-run-task.ps1" -Prompt "%TASK_DESC%"
exit /b %ERRORLEVEL%

:tasks
set "SUBCMD=%~2"
if "%SUBCMD%"=="" set "SUBCMD=list"
if /I "%SUBCMD%"=="list"     goto :tasks_list
if /I "%SUBCMD%"=="create"  goto :tasks_create
if /I "%SUBCMD%"=="delete"  goto :tasks_delete
if /I "%SUBCMD%"=="show"    goto :tasks_show
echo aq tasks [list^|create^|delete^|show]
exit /b 1

:tasks_list
curl -s "%PROXY%/v1/tasks" -H "Authorization: Bearer %AUTH%"
echo.
exit /b 0

:tasks_create
set "PROMPT=%~3"
if "%PROMPT%"=="" (
    echo Usage: aq tasks create "prompt"
    exit /b 1
)
curl -s -X POST "%PROXY%/v1/tasks" -H "Authorization: Bearer %AUTH%" -H "Content-Type: application/json" -d "{\"prompt\":\"%PROMPT%\",\"tier\":\"auto\"}"
echo.
exit /b 0

:tasks_delete
set "ID=%~3"
if "%ID%"=="" (
    echo Usage: aq tasks delete task-0001
    exit /b 1
)
curl -s -X DELETE "%PROXY%/v1/tasks/%ID%" -H "Authorization: Bearer %AUTH%"
echo.
exit /b 0

:tasks_show
set "ID=%~3"
if "%ID%"=="" (
    echo Usage: aq tasks show task-0001
    exit /b 1
)
curl -s "%PROXY%/v1/tasks/%ID%" -H "Authorization: Bearer %AUTH%"
echo.
exit /b 0

:worktrees
set "SUBCMD=%~2"
if "%SUBCMD%"=="" set "SUBCMD=list"
if /I "%SUBCMD%"=="list"     goto :wt_list
if /I "%SUBCMD%"=="create"  goto :wt_create
if /I "%SUBCMD%"=="remove"  goto :wt_remove
echo aq worktrees [list^|create^|remove]
exit /b 1

:wt_list
curl -s "%PROXY%/v1/worktrees" -H "Authorization: Bearer %AUTH%"
echo.
exit /b 0

:wt_create
set "TASK=%~3"
if "%TASK%"=="" (
    echo Usage: aq worktrees create task-0001
    exit /b 1
)
curl -s -X POST "%PROXY%/v1/worktrees/%TASK%" -H "Authorization: Bearer %AUTH%" -H "Content-Type: application/json" -d "{}"
echo.
exit /b 0

:wt_remove
set "PATH_ARG=%~3"
if "%PATH_ARG%"=="" (
    echo Usage: aq worktrees remove "C:\path\to\worktree"
    exit /b 1
)
"%PS%" -NoProfile -Command "git worktree remove --force '%PATH_ARG%' 2>&1"
exit /b %ERRORLEVEL%

:tiers
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%aq-tiers.ps1"
exit /b %ERRORLEVEL%

:route
set "PROMPT=%~2"
if "%PROMPT%"=="" (
    echo Usage: aq route "your prompt" -- debug: see which tier would be picked
    exit /b 1
)
curl -s -X POST "%PROXY%/v1/auto/route" -H "Authorization: Bearer %AUTH%" -H "Content-Type: application/json" -d "{\"messages\":[{\"role\":\"user\",\"content\":\"%PROMPT%\"}]}"
echo.
exit /b 0

:compact
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%aq-compact.ps1"
exit /b %ERRORLEVEL%

:mcp
set "ACTION=%~2"
if /I "%ACTION%"=="start"   goto :mcp_start
if /I "%ACTION%"=="stop"    goto :mcp_stop
if /I "%ACTION%"=="status"  goto :mcp_status
if /I "%ACTION%"=="tools"   goto :mcp_tools
echo aq mcp [start^|stop^|status^|tools]
exit /b 1

:mcp_start
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%aq-mcp.ps1" -Action start
exit /b %ERRORLEVEL%

:mcp_stop
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%aq-mcp.ps1" -Action stop
exit /b %ERRORLEVEL%

:mcp_status
curl -s "http://127.0.0.1:%MCP_PORT%/health"
echo.
exit /b 0

:mcp_tools
curl -s "http://127.0.0.1:%MCP_PORT%/tools"
echo.
exit /b 0

:stats
echo === Tasks stats ===
curl -s "%PROXY%/v1/tasks/stats" -H "Authorization: Bearer %AUTH%"
echo.
echo.
echo === Tiers count ===
curl -s "%PROXY%/v1/models" -H "Authorization: Bearer %AUTH%" | "%PS%" -NoProfile -Command "$j = $input | ConvertFrom-Json; Write-Host ('Total tiers: ' + $j.data.Count); Write-Host ('Providers: ' + (($j.data | ForEach-Object { $_.owned_by } | Sort-Object -Unique) -join ', '))"
exit /b 0

:doctor
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%aq-doctor.ps1"
exit /b %ERRORLEVEL%

:status
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%aq-doctor.ps1" -Quick
exit /b %ERRORLEVEL%

:tui
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%aq-tui.ps1"
exit /b %ERRORLEVEL%

:code
REM aq code "task" -- delegates to opencode run for full coding agent
REM (file edits, tools, LSP, multi-turn) using opencode as the engine
REM Optional flags: --agent build|plan|ceo, --model <id>
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%aq-code.ps1" %2 %3 %4 %5 %6 %7 %8 %9
exit /b %ERRORLEVEL%

:oc
REM aq oc <args> -- passthrough to opencode CLI
"C:\Users\trufa\.opencode\bin\opencode.exe" %*
exit /b %ERRORLEVEL%