$c = Get-Content "$env:USERPROFILE\.aq\keys.json" -Raw | ConvertFrom-Json
$k = $c.groq_keys[0]
$payload = '{"model":"openai/gpt-oss-20b","messages":[{"role":"user","content":"Reponds OK"}],"max_tokens":5}'
Write-Host "Testing Groq key 1: $($k.Substring(0,12))..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$res = Invoke-WebRequest -Uri "https://api.groq.com/openai/v1/chat/completions" -Method POST -Headers @{Authorization="Bearer $k"} -ContentType "application/json" -Body $payload -UseBasicParsing -TimeoutSec 10
$sw.Stop()
Write-Host "HTTP $($res.StatusCode) in $($sw.ElapsedMilliseconds)ms"
Write-Host $res.Content

Write-Host ""
Write-Host "Testing MiniMax key..."
$mk = $c.minimax_key
$payload2 = '{"model":"MiniMax-M2.7","messages":[{"role":"user","content":"Reponds OK"}],"max_tokens":15,"reasoning_effort":"low"}'
$sw2 = [System.Diagnostics.Stopwatch]::StartNew()
try {
  $res2 = Invoke-WebRequest -Uri "https://api.minimax.io/v1/chat/completions" -Method POST -Headers @{Authorization="Bearer $mk"} -ContentType "application/json" -Body $payload2 -UseBasicParsing -TimeoutSec 30
  $sw2.Stop()
  Write-Host "HTTP $($res2.StatusCode) in $($sw2.ElapsedMilliseconds)ms"
  Write-Host $res2.Content.Substring(0, [Math]::Min(400, $res2.Content.Length))
} catch {
  Write-Host "Error: $($_.Exception.Message)"
}