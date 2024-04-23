#!/bin/bash

echo "Running script to process by yt music playlist..."

PLAYLIST_URL="$1"

if [ -z "$PLAYLIST_URL" ]; then
    echo "No playlist URL provided."
    exit 1
fi

ruby ./lib/vaquita.rb --type music-playlist "$PLAYLIST_URL"

RESOURCE_PATH=$(cat output_dir.txt)

if [ -z "$RESOURCE_PATH" ]; then[
    echo "Resource path is not specified"
    exit 1
]

PASSWORD=$(jq -r '.password' ./credentials.json)

if [ -z "$PASSWORD" ]; then
    exit 1
fi

export PASSWORD=$PASSWORD

echo -e "\033[0;36mRunning import_to_apple_music.sh...\033[0m"

echo "$PASSWORD" | sudo -S osascript -e 'tell application "Music" to add POSIX file "'"$RESOURCE_PATH"'"'
rm "$RESOURCE_PATH"

rm -rf "output_dir.txt"
