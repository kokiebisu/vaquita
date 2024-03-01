#!/bin/bash

# Access the MUSIC_FOLDER environment variable
music_folder="$MUSIC_FOLDER"

# Check if the variable is set
if [ -z "$music_folder" ]; then
    echo "Error: MUSIC_FOLDER is not set."
    exit 1
fi

# Execute the AppleScript file with administrator privileges for each MP3 file
echo "$PASSWORD" | sudo -S find "$music_folder" -name '*.mp3' -exec osascript -e 'tell application "Music" to add POSIX file "{}"' \;
