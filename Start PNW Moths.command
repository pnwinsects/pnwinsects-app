#!/bin/bash
cd "$(dirname "$0")" || exit 1

if [ ! -f "launcher/start-local-site-mac.sh" ] ||
   [ ! -f "images/pnwinsects-local-images.tar" ] ||
   [ ! -f "data/site.sql" ] ||
   [ ! -f "bundle.env" ]; then
    echo
    echo "-----------------------------------------------------------"
    echo "This folder is incomplete."
    echo
    echo "Close this window, move the downloaded zip file to a folder"
    echo "with at least 8 GB free, and double-click the zip to unpack"
    echo "the complete site. Then use the Start file in that folder."
    echo "-----------------------------------------------------------"
    echo
    read -r -p "Press Return to close this window"
    exit 1
fi

exec /bin/bash "launcher/start-local-site-mac.sh"
