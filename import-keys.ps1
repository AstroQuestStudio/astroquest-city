# Import Groq + MiniMax + Gemini + NVIDIA keys from local files to ~/.aq/keys.json
$keysTxt  = "C:\Users\trufa\Downloads\keys.txt"
$minimaxTxt = "C:\Users\trufa\Documents\AstroQuest City\minimaxtokenplanapikey.txt"
$geminiTxt = "C:\Users\trufa\Downloads\gemini api keys.txt"
$nvidiaTxt = "C:\Users\trufa\Downloads\nvidia api keys.txt"
$keysJson = "$env:USERPROFILE\.aq\keys.json"

# Parse Groq keys (format: "groq N : gsk_xxx")
$groqLines = Get-Content $keysTxt -ErrorAction SilentlyContinue | Where-Object { $_ -match '^groq\s+\d+\s*:\s*(gsk_[A-Za-z0-9]+)' }
$groqKeys = @()
foreach ($line in $groqLines) {
  if ($line -match 'groq\s+\d+\s*:\s*(gsk_[A-Za-z0-9]+)') {
    $groqKeys += $matches[1]
  }
}
Write-Host "Found $($groqKeys.Count) Groq keys"

# Parse MiniMax key
$minimaxKey = $null
if (Test-Path $minimaxTxt) {
  $minimaxKey = (Get-Content $minimaxTxt -First 1).Trim()
  if ($minimaxKey) { Write-Host "MiniMax key: $($minimaxKey.Substring(0,15))..." }
}

# Parse Gemini keys (look for lines starting with "AQ.")
$geminiLines = Get-Content $geminiTxt -ErrorAction SilentlyContinue | Where-Object { $_ -match '^(AQ\.[A-Za-z0-9_-]+)$' }
$geminiKeys = @()
foreach ($line in $geminiLines) {
  if ($line -match '^(AQ\.[A-Za-z0-9_-]+)$') {
    $geminiKeys += $matches[1]
  }
}
Write-Host "Found $($geminiKeys.Count) Gemini keys"

# Parse NVIDIA keys (format: nvapi-...)
$nvidiaKeys = @()
if (Test-Path $nvidiaTxt) {
  $nvidiaLines = Get-Content $nvidiaTxt -ErrorAction SilentlyContinue
  foreach ($line in $nvidiaLines) {
    $trim = $line.Trim()
    if ($trim -match '^(nvapi-[A-Za-z0-9_-]{20,})$') {
      $nvidiaKeys += $matches[1]
    } elseif ($trim -match 'nvapi-[A-Za-z0-9_-]{20,}') {
      $nvidiaKeys += $matches[0]
    }
  }
}
Write-Host "Found $($nvidiaKeys.Count) NVIDIA keys"

# Build JSON
$json = @{
  groq_keys = $groqKeys
  minimax_key = $minimaxKey
  gemini_keys = $geminiKeys
  nvidia_keys = $nvidiaKeys
  litellm_master_key = "sk-aq-local"
  anthropic_key = $null
  openai_key = $null
} | ConvertTo-Json -Depth 4

# Write
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.aq" | Out-Null
[System.IO.File]::WriteAllText($keysJson, $json)

# Restrict permissions
try { icacls $keysJson /inheritance:r /grant:r "$env:USERNAME:(R,W)" 2>$null | Out-Null } catch {}

Write-Host ""
Write-Host "=== KEYS SAVED ==="
Write-Host "Path: $keysJson"
Write-Host "Groq keys:    $($groqKeys.Count)"
Write-Host "MiniMax:      $(if ($minimaxKey) { 'YES' } else { 'NO' })"
Write-Host "Gemini keys:  $($geminiKeys.Count)"
Write-Host "NVIDIA keys:  $($nvidiaKeys.Count)"
Write-Host ""
if ($groqKeys.Count -gt 0)    { Write-Host "Sample Groq:    $($groqKeys[0].Substring(0,12))..." }
if ($geminiKeys.Count -gt 0)  { Write-Host "Sample Gemini:  $($geminiKeys[0].Substring(0,12))..." }
if ($nvidiaKeys.Count -gt 0)  { Write-Host "Sample NVIDIA:  $($nvidiaKeys[0].Substring(0,12))..." }