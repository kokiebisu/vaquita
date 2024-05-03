#!/bin/bash

echo "Running script to process the YouTube music playlist..."

PLAYLIST_URL="$1"

if [ -z "$PLAYLIST_URL" ]; then
    echo "No playlist URL provided."
    exit 1
fi

ruby ./lib/vaquita.rb --type music-playlist "$PLAYLIST_URL"

# Retrieve the resource path from resource_path.txt
RESOURCE_PATH=$(cat resource_path.txt)
PLAYLIST_NAME_PATH=$(cat playlist_name_path.txt)
PLAYLIST_COVER_IMG_URL_PATH=$(cat playlist_cover_img_url_path.txt)

truncate -s 0 playlist_cover_img_url_path.txt
truncate -s 0 playlist_name_path.txt
truncate -s 0 resource_path.txt

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

echo "$PASSWORD" | sudo -S osascript music_script.applescript "$RESOURCE_PATH" "$PLAYLIST_NAME_PATH" "$PLAYLIST_COVER_IMG_URL_PATH"
