# Starts the offline PNW Moths reference copy and opens it in the browser.
# Driven by "Start PNW Moths.cmd"; not meant to be run directly.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Fail($message) {
    Write-Host ''
    Write-Host '-----------------------------------------------------------'
    Write-Host $message
    Write-Host '-----------------------------------------------------------'
    Write-Host ''
    Read-Host 'Press Enter to close this window'
    exit 1
}

Write-Host 'Starting the PNW Moths reference copy...'
Write-Host ''

# 1. Is Docker Desktop installed at all? Checked separately, because a missing
#    command leaves $LASTEXITCODE untouched and the check below would pass.
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Fail @'
Docker Desktop does not appear to be installed on this computer.

Install it (it is free) from:
    https://www.docker.com/products/docker-desktop/

Accept all the suggested options, and restart the computer if it asks you
to. Then open Docker Desktop from the Start menu, wait until the whale icon
in the bottom-left corner stops animating and turns green, and double-click
"Start PNW Moths" again.
'@
}

# 2. Is Docker Desktop running?
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Fail @'
Docker Desktop does not seem to be running.

Open Docker Desktop from the Start menu, wait until the whale icon in the
bottom-left corner stops animating and turns green, then double-click
"Start PNW Moths" again.

If Docker Desktop is not installed yet, see step 1 of the instructions
that came with this folder.
'@
}

# 2. First run only: load the pre-built images so nothing has to be compiled.
$have = docker images --format '{{.Repository}}:{{.Tag}}' | Select-String -SimpleMatch 'pnwmoths-local-web:1.0'
if (-not $have) {
    Write-Host 'First run: unpacking the site. This takes a few minutes, once only...'
    docker load -i (Join-Path $root 'images\pnwmoths-local-images.tar')
    if ($LASTEXITCODE -ne 0) {
        Fail 'Could not unpack the site. The downloaded folder may be incomplete - try downloading it again.'
    }
}

# 3. Start the two containers.
docker compose -f docker-compose.offline.yml up -d
if ($LASTEXITCODE -ne 0) {
    Fail 'The site could not be started. Please send Jason the text in this window.'
}

# 4. Wait for it to answer. The very first run also imports the whole database,
#    so allow far longer than an ordinary start would need.
Write-Host ''
Write-Host 'Waiting for the site to be ready. The first time you do this it can take'
Write-Host 'up to fifteen minutes, because the whole database is being loaded.'
Write-Host 'After that it is usually under a minute.'
Write-Host ''

$deadline = (Get-Date).AddMinutes(20)
$ready = $false
while ((Get-Date) -lt $deadline) {
    try {
        # Windows PowerShell 5.1 follows the redirect the login-gated homepage
        # issues, so a 200 here means the site is up and answering. Keep this
        # call plain: 5.1 has no -SkipHttpErrorCheck, and an unknown parameter
        # would throw into the catch on every pass and never succeed.
        $r = Invoke-WebRequest 'http://localhost:8000/' -UseBasicParsing -TimeoutSec 20
        if ($r.StatusCode -eq 200) { $ready = $true; break }
    } catch {
    }
    Write-Host '  still loading...'
    Start-Sleep -Seconds 10
}

if (-not $ready) {
    Fail @'
The site did not finish starting.

Double-click "Stop PNW Moths", then try "Start PNW Moths" once more. If it
still does not work, send Jason the text in this window.
'@
}

Write-Host ''
Write-Host 'Ready. Opening the site in your browser.'
Write-Host ''
Write-Host 'It will ask you to sign in, exactly as the old dev site did.'
Write-Host '    User name:  merrill'
Write-Host '    Password:   pnwmoths'
Write-Host ''
Write-Host 'You can close this window. The site stays running.'
Write-Host 'When you are finished for the day, double-click "Stop PNW Moths".'
# The legacy homepage is flagged login-required in the database, so going
# straight to the sign-in page saves a confusing redirect on arrival.
Start-Process 'http://localhost:8000/accounts/login/?next=/'
Start-Sleep -Seconds 8
