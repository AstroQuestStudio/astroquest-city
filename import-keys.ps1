# Import Groq + MiniMax + Gemini keys from local files to ~/.aq/keys.json
$keysTxt = "C:\Users\trufa\Downloads\keys.txt"
$minimaxTxt = "C:\Users\trufa\Documents\AstroQuest City\minimaxtokenplanapikey.txt"
$geminiTxt = "C:\Users\trufa\Downloads\gemini api keys.txt"
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
  Write-Host "MiniMax key: $($minimaxKey.Substring(0,15))..."
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

# Build JSON
$json = @{
  groq_keys = $groqKeys
  minimax_key = $minimaxKey
  gemini_keys = $geminiKeys
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
Write-Host "Groq keys: $($groqKeys.Count)"
Write-Host "MiniMax: $(if ($minimaxKey) { 'YES' } else { 'NO' })"
Write-Host "Gemini keys: $($geminiKeys.Count)"
Write-Host ""
Write-Host "Sample Groq key: $($groqKeys[0].Substring(0,12))..."
if ($geminiKeys.Count -gt 0) {
  Write-Host "Sample Gemini key: $($geminiKeys[0].Substring(0,12))..."
}