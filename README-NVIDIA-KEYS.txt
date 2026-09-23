# How to get free NVIDIA API keys

1. Go to https://build.nvidia.com
2. Sign in with your NVIDIA Developer account (free, no credit card)
3. Click your avatar → Settings → API Keys
4. Click "Generate API Key" — copy the nvapi-… value
5. Paste keys in `C:\Users\trufa\Downloads\nvidia api keys.txt`, one per line:
   nvapi-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   nvapi-YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
6. Run `import-keys.ps1` (it auto-detects this file)

Free tier limits:
  - Frontier MoE (Nemotron Ultra 550B, GLM-5.3, DeepSeek-v4-flash, kimi-k3): ~40 RPM, ~1k req/day
  - Small Nemotrons (30B Lightning, Mistral Nemotron): ~400 RPM
  - Add 2-3 personal keys for round-robin throughput

The keys are stored in `~/.aq/keys.json` (chmod 600), NEVER sent to the VPS.