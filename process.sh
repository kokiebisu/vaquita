#!/bin/bash


PLAYLIST_URL="$1"

if [ -z "$PLAYLIST_URL" ]; then
    echo "No playlist URL provided."
    exit 1
fi

ruby ./lib/vaquita.rb --type url "$PLAYLIST_URL"

RESOURCE_PATH=$(cat output_dir.txt)
PASSWORD=$(jq -r '.password' ./credentials.json)

if [ -z "$PASSWORD" ]; then
    exit 1
fi

export PASSWORD=$PASSWORD

echo -e "\033[0;36mRunning import_to_apple_music.sh...\033[0m"
if [ -f "$RESOURCE_PATH" ]; then
    echo "$PASSWORD" | sudo -S osascript -e 'tell application "Music" to add POSIX file "'"$RESOURCE_PATH"'"'
    rm "$RESOURCE_PATH"
else
    echo "$PASSWORD" | sudo -S find "$RESOURCE_PATH" -name '*.mp3' -exec osascript -e 'tell application "Music" to add POSIX file "{}"' \;
    rm -rf "$RESOURCE_PATH"
fi

rm -rf "output_dir.txt"
