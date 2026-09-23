#requires -Version 5
<#
.SYNOPSIS
    aq-coder â€” calls the local AQ proxy to generate code via free providers (Groq, NVIDIA, Gemini)
    instead of burning the user's MiniMax plan. Designed for Mavis self-coding tasks.

.DESCRIPTION
    Wraps `POST http://127.0.0.1:4000/v1/chat/completions` (the AQ local proxy) with sensible
    defaults for code generation:
      - Default tier: tier-6-ouvrier (Mistral Nemotron â€” agentic, free)
      - Smart tier override: tier-8-opus-reflection for long/strategic prompts
      - Reads API key from ~/.aq/keys.json (or env $AQ_MASTER_KEY, default "sk-aq-local")
      - Falls back through the tier chain automatically (handled by the proxy)
      - Writes output to file via -OutFile or prints to stdout

.EXAMPLE
    # Simple chat completion via free provider
    .\aq-coder.ps1 -Prompt "Write a Rust function that parses JSON safely"

.EXAMPLE
    # Use the cheap tier-3-formatteur for microtasks
    .\aq-coder.ps1 -Prompt "What's the diff between vec! and array!" -Tier "tier-3-formatteur"

.EXAMPLE
    # Save to file
    .\aq-coder.ps1 -Prompt "Add doc comments to fn main" -OutFile "C:\path\to\file.rs"

.EXAMPLE
    # Use as Mavis tool: pipe stdin
    "Refactor this Rust function to be more idiomatic" | .\aq-coder.ps1 -OutFile "out.rs"
#>

param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]$Prompt,

    [Parameter()]
    [string]$Tier = "auto",

    [Parameter()]
    [int]$MaxTokens = 4096,

    [Parameter()]
    [double]$Temperature = 0.3,

    [Parameter()]
    [string]$SystemPrompt = "You are an expert software engineer. Output only the requested code or answer. Be concise and idiomatic. No preamble, no explanation unless asked.",

    [Parameter()]
    [string]$OutFile,

    [Parameter()]
    [string]$ProxyUrl = "http://127.0.0.1:4000/v1",

    [Parameter()]
    [string]$ApiKey = "sk-aq-local",

    [Parameter()]
    [switch]$ShowChain,

    [Parameter()]
    [switch]$NoColor
)

# --- Smart tier router (matches local_proxy.rs auto-routing) ----
function Resolve-AutoTier {
    param([string]$Prompt)
    $len = $Prompt.Length
    $lower = $Prompt.ToLower()

    $strategyKeys = @('roadmap','vision','strategy','architect','design','plan')
    $codeKeys     = @('function','class','implement','fix','refactor','add','create','write','build','edit')
    $searchKeys   = @('search','find','where','how does','what is','list','grep')
    $formatKeys   = @('format','lint','prettier','style','comment','doc')
    $multimodal   = @('image','picture','photo','video','screenshot')

    foreach ($k in $strategyKeys) { if ($lower.Contains($k)) { return "tier-8-opus-reflection" } }
    foreach ($k in $multimodal)  { if ($lower.Contains($k)) { return "tier-studio-image" } }
    foreach ($k in $formatKeys)  { if ($lower.Contains($k)) { return "tier-3-formatteur" } }
    foreach ($k in $searchKeys)  { if ($lower.Contains($k)) { return "tier-4-groq" } }
    if ($len -gt 2000) { return "tier-8-opus-reflection" }
    foreach ($k in $codeKeys) { if ($lower.Contains($k)) { return "tier-7-constructeur" } }
    return "tier-6-ouvrier"
}

if ($Tier -eq "auto") {
    $Tier = Resolve-AutoTier -Prompt $Prompt
}

Write-Host ("[aq-coder] tier={0} max_tokens={1} temp={2}" -f $Tier, $MaxTokens, $Temperature) -ForegroundColor Cyan

# --- Build request body ------------------------------------------
$body = @{
    model       = $Tier
    max_tokens  = $MaxTokens
    temperature = $Temperature
    messages    = @(
        @{ role = "system"; content = $SystemPrompt },
        @{ role = "user";   content = $Prompt }
    )
} | ConvertTo-Json -Depth 6 -Compress

# --- Call proxy --------------------------------------------------
try {
    $resp = Invoke-WebRequest -Uri "$ProxyUrl/chat/completions" `
        -Method POST `
        -Headers @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $ApiKey"
        } `
        -Body $body `
        -UseBasicParsing `
        -TimeoutSec 120 `
        -ErrorAction Stop
} catch {
    Write-Host "[aq-coder] ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[aq-coder] Is the AQ local proxy running on $ProxyUrl ? (launch create-tauri-react.exe)" -ForegroundColor Yellow
    exit 1
}

# --- Parse response ----------------------------------------------
$json = $resp.Content | ConvertFrom-Json
$content = $json.choices[0].message.content

# --- Metadata (served-by, attempts) ------------------------------
if ($ShowChain -or $resp.Headers.ContainsKey("X-AO-Relay-Served-By")) {
    $servedBy = $resp.Headers["X-AO-Relay-Served-By"] | Select-Object -First 1
    $attempts = $resp.Headers["X-AO-Relay-Attempts"] | Select-Object -First 1
    if ($servedBy) { Write-Host "[aq-coder] served_by=$servedBy attempts=$attempts" -ForegroundColor DarkGray }
}

# --- Usage stats -------------------------------------------------
if ($json.usage) {
    $pt = $json.usage.prompt_tokens
    $ct = $json.usage.completion_tokens
    $tt = $json.usage.total_tokens
    Write-Host "[aq-coder] tokens: $pt prompt + $ct completion = $tt total" -ForegroundColor DarkGray
}

# --- Output ------------------------------------------------------
if ($OutFile) {
    [System.IO.File]::WriteAllText($OutFile, $content)
    Write-Host "[aq-coder] wrote $($content.Length) chars -> $OutFile" -ForegroundColor Green
} else {
    Write-Host $content
}

# Return object for piping in other scripts
[PSCustomObject]@{
    Tier       = $Tier
    Content    = $content
    TokensUsed = $json.usage.total_tokens
    ServedBy   = if ($resp.Headers.ContainsKey("X-AO-Relay-Served-By")) { $resp.Headers["X-AO-Relay-Served-By"][0] } else { "local" }
}