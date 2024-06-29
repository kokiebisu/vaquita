#!/bin/bash

BASE_DIR=$(realpath ./downloads)

PASSWORD=$(jq -r '.password' ./credentials.json)
if [ -z "$PASSWORD" ]; then
    exit 1
fi
export PASSWORD=$PASSWORD

for SUBFOLDER in "$BASE_DIR"/*; do
    if [ -d "$SUBFOLDER" ]; then
        RESOURCE_PATH="$SUBFOLDER/songs"
        PLAYLIST_NAME_PATH=$(basename "$SUBFOLDER")
        PLAYLIST_COVER_PATH="$SUBFOLDER/playlist_cover.jpg"
        TYPE=$(jq -r '.type' "$SUBFOLDER/property.json")
        echo "$PASSWORD" | sudo -S osascript import_to_apple_music.applescript "$RESOURCE_PATH" "$PLAYLIST_NAME_PATH" "$PLAYLIST_COVER_PATH" "$TYPE" &
    fi
done
