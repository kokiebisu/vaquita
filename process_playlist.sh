#!/bin/bash

echo "Running script to process the YouTube music playlist..."

# Ensure a playlist URL is provided
PLAYLIST_URL="$1"

if [ -z "$PLAYLIST_URL" ]; then
    echo "No playlist URL provided."
    exit 1
fi

# Process the playlist using a Ruby script
ruby ./lib/vaquita.rb --type music-playlist "$PLAYLIST_URL"

# Retrieve the resource path from output_dir.txt
RESOURCE_PATH=$(cat output_dir.txt)

if [ -z "$RESOURCE_PATH" ]; then
    echo "Resource path is not specified"
    exit 1
fi

# Extract the password from credentials.json using jq
PASSWORD=$(jq -r '.password' ./credentials.json)

if [ -z "$PASSWORD" ]; then
    echo "Password not specified."
    exit 1
fi

export PASSWORD=$PASSWORD

# Print a message with color-coded output
echo -e "\033[0;36mRunning import_to_apple_music.sh...\033[0m"

# Use the password to run a sudo command that tells the Music application to add a file
echo "$PASSWORD" | sudo -S osascript -e 'tell application "Music" to add POSIX file "'"$RESOURCE_PATH"'"'

# Clean up by removing the resource path and temporary files
rm "$RESOURCE_PATH"
rm -rf "output_dir.txt"