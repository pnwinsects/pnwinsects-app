# Stops the offline PNW Moths reference copy.
# Driven by "Stop PNW Moths.cmd"; not meant to be run directly.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Get-Content (Join-Path $root 'bundle.env') | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
        $parts = $line.Split('=', 2)
        if ($parts.Count -eq 2) {
            $value = $parts[1].Trim().Trim('"').Trim("'")
            [Environment]::SetEnvironmentVariable($parts[0].Trim(), $value, 'Process')
        }
    }
}
$siteTitle = if ($env:SITE_TITLE) { $env:SITE_TITLE } else { 'PNW Moths' }

Write-Host "Stopping the $siteTitle reference copy..."
Write-Host ''

if (Get-Command docker -ErrorAction SilentlyContinue) { docker info *> $null } else { $LASTEXITCODE = 1 }
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Docker Desktop is not running, so the site is already stopped.'
    Start-Sleep -Seconds 4
    exit 0
}

docker compose --env-file bundle.env -f docker-compose.offline.yml stop

Write-Host ''
Write-Host "Stopped. Nothing has been deleted - open the Start $siteTitle file"
Write-Host 'whenever you want it back, and it will come up in under a minute.'
Start-Sleep -Seconds 6
