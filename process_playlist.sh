#!/bin/bash

echo "Running script to process the YouTube music playlist..."

PLAYLIST_URL="$1"

if [ -z "$PLAYLIST_URL" ]; then
    echo "No playlist URL provided."
    exit 1
fi

ruby ./lib/vaquita.rb --type music-playlist "$PLAYLIST_URL"

# Retrieve the resource path from output_dir.txt
RESOURCE_PATH=$(cat output_dir.txt)

if [ -z "$RESOURCE_PATH" ]; then
    echo "Resource path is not specified"
    exit 1
fi

PASSWORD=$(jq -r '.password' ./credentials.json)

if [ -z "$PASSWORD" ]; then
    exit 1
fi

export PASSWORD=$PASSWORD

echo -e "\033[0;36mRunning import_to_apple_music.sh...\033[0m"

RESOURCE_PATH_ESCAPED=$(printf "%q" "$RESOURCE_PATH")

echo "$PASSWORD" | sudo -S osascript music_script.applescript "$RESOURCE_PATH"

rm -rf "$RESOURCE_PATH"
rm "output_dir.txt"