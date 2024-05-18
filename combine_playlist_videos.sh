#!/bin/bash

DOWNLOADS_FOLDER=/usr/src/app/downloads

for PLAYLIST_FOLDER in "$DOWNLOADS_FOLDER"/*; do
    if [ -d "$PLAYLIST_FOLDER" ]; then
        PLAYLIST_NAME=$(basename "$PLAYLIST_FOLDER")
        echo "Processing playlist: $PLAYLIST_NAME"
        
        FILE_LIST="/tmp/${PLAYLIST_NAME}_filelist.txt"
        : > "$FILE_LIST"

        for VIDEO_FILE in "$PLAYLIST_FOLDER"/*.mp4; do
            echo "file '$VIDEO_FILE'" >> "$FILE_LIST"
        done
        
        # Combine the videos using ffmpeg
        ffmpeg -f concat -safe 0 -i "$FILE_LIST" -c copy "$DOWNLOADS_FOLDER/$PLAYLIST_NAME.mp4"
        
        rm "$FILE_LIST"
    fi
done
