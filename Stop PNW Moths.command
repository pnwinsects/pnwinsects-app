#!/bin/bash

cd "$(dirname "$0")" || exit 1

if [ ! -f "launcher/stop-local-site-mac.sh" ] || [ ! -f "bundle.env" ]; then
    echo
    echo "-----------------------------------------------------------"
    echo "This folder is incomplete. Use the Stop file in the folder"
    echo "created when you double-clicked the downloaded zip."
    echo "-----------------------------------------------------------"
    echo
    read -r -p "Press Return to close this window"
    exit 1
fi

exec /bin/bash "launcher/stop-local-site-mac.sh"
