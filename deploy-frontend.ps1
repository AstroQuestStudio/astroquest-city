<#
.SYNOPSIS
    Deploie le frontend AstroQuest City sur VPS3 (Vite build vers /var/www/aq/)
    + chmod 755 pour eviter le bug de permissions Caddy
.NOTES
    Usage : powershell -File deploy-frontend.ps1
#>
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot").Path
$src = Join-Path $root 'apps\city\dist'
$dst = '/var/www/aq/'
$key = 'C:\Users\trufa\.ssh\astroquest_vps2'
$sshHost = 'root@46.224.170.108'

Write-Host "[1/4] Build frontend..." -ForegroundColor Cyan
Set-Location (Join-Path $root 'apps\city')
npm run build 2>&1 | Select-Object -Last 5

Write-Host "`n[2/4] Nettoyer l'ancien contenu sur VPS3" -ForegroundColor Cyan
ssh -i $key -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -p 22 $sshHost "rm -rf $dst"

Write-Host "`n[3/4] SCP dist/ vers VPS3" -ForegroundColor Cyan
scp -i $key -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -P 22 -r "$src\*" "${sshHost}:${dst}"

Write-Host "`n[4/4] Fix permissions (755 pour que caddy puisse lire)" -ForegroundColor Cyan
ssh -i $key -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -p 22 $sshHost "chmod -R 755 $dst"

Write-Host "`n[OK : frontend deploye sur https://edge.astroquest.fr/" -ForegroundColor Green