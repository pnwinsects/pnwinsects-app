#!/bin/bash

# Started by "Stop PNW Moths.command"; not meant to be run directly.

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin"
set -a
. "$root/bundle.env"
set +a
site_title="${SITE_TITLE:-PNW Moths}"

echo "Stopping the $site_title reference copy..."
echo

docker_path="$(command -v docker 2>/dev/null)"
if [ -z "$docker_path" ] || ! "$docker_path" info >/dev/null 2>&1; then
    echo "Docker Desktop is not running, so the site is already stopped."
    sleep 4
    exit 0
fi

"$docker_path" compose --env-file bundle.env -f docker-compose.offline.yml stop

echo
echo "Stopped. Nothing has been deleted. Open the Start $site_title file"
echo "whenever you want it back."
sleep 6
