# Stops the offline PNW Moths reference copy.
# Driven by "Stop PNW Moths.cmd"; not meant to be run directly.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host 'Stopping the PNW Moths reference copy...'
Write-Host ''

if (Get-Command docker -ErrorAction SilentlyContinue) { docker info *> $null } else { $LASTEXITCODE = 1 }
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Docker Desktop is not running, so the site is already stopped.'
    Start-Sleep -Seconds 4
    exit 0
}

docker compose -f docker-compose.offline.yml stop

Write-Host ''
Write-Host 'Stopped. Nothing has been deleted - double-click "Start PNW Moths"'
Write-Host 'whenever you want it back, and it will come up in under a minute.'
Start-Sleep -Seconds 6
