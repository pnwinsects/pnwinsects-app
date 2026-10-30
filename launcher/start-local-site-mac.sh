#!/bin/bash

# Started by "Start PNW Moths.command"; not meant to be run directly.

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin"
set -a
. "$root/bundle.env"
set +a

site_title="${SITE_TITLE:-PNW Moths}"
: "${WEB_IMAGE:?WEB_IMAGE is missing from bundle.env}"
: "${ADMIN_USER:?ADMIN_USER is missing from bundle.env}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD is missing from bundle.env}"
web_image="$WEB_IMAGE"
web_port="${WEB_PORT:-8000}"

fail() {
    echo
    echo "-----------------------------------------------------------"
    printf '%s\n' "$1"
    echo "-----------------------------------------------------------"
    echo
    read -r -p "Press Return to close this window"
    exit 1
}

echo "Starting the $site_title reference copy..."
echo

docker_path="$(command -v docker 2>/dev/null)"
if [ -z "$docker_path" ]; then
    fail "Docker Desktop does not appear to be installed on this Mac.

Install it from:
    https://www.docker.com/products/docker-desktop/

Choose the download for a Mac with Apple silicon. Accept the suggested
options, then open Docker Desktop and wait for it to say \"Engine running\"
before opening \"Start PNW Moths\" again."
fi

if ! "$docker_path" info >/dev/null 2>&1; then
    fail "Docker Desktop does not seem to be running.

Open Docker Desktop from Applications and wait for it to say
\"Engine running\", then open \"Start PNW Moths\" again.

\"Resource Saver\" is normal when the moth site is not running. Docker
will leave Resource Saver automatically when this file starts the site."
fi

if ! "$docker_path" images --format '{{.Repository}}:{{.Tag}}' |
    grep -Fqx "$web_image"; then
    echo "First run: unpacking the site. This takes a few minutes, once only..."
    if ! "$docker_path" load -i "$root/images/pnwinsects-local-images.tar"; then
        fail "Could not unpack the site. The downloaded folder may be incomplete.
Try downloading and unpacking it again."
    fi
fi

if ! "$docker_path" compose --env-file bundle.env -f docker-compose.offline.yml up -d; then
    fail "The site could not be started. Please send Jason the text in this window."
fi

echo
echo "Waiting for the site to be ready. The first time can take considerably"
echo "longer on a Mac because it is loading the whole database through"
echo "compatibility mode. Later starts should be much quicker."
echo

deadline=$(( $(date +%s) + 1800 ))
ready=false
while [ "$(date +%s)" -lt "$deadline" ]; do
    status="$(curl -L -s -o /dev/null -w '%{http_code}' --max-time 20 \
        "http://localhost:$web_port/" 2>/dev/null || true)"
    if [ "$status" = "200" ]; then
        ready=true
        break
    fi
    echo "  still loading..."
    sleep 10
done

if [ "$ready" != true ]; then
    fail "The site did not finish starting.

Open \"Stop PNW Moths\", then try \"Start PNW Moths\" once more. If it
still does not work, send Jason the text in this window."
fi

echo
echo "Ready. Opening the site in your browser."
echo
echo "Use the sign-in details sent with the private bundle."
echo
echo "You can close this window. The site stays running."
echo "When finished, open the Stop $site_title file."
open "http://localhost:$web_port/accounts/login/?next=/"
sleep 8
