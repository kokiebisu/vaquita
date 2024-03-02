#!/bin/bash

echo '''
                               
   _________  ____  __  _______
  / ___/ __ \/ __ \/ / / / ___/
 (__  ) /_/ / / / / /_/ (__  ) 
/____/\____/_/ /_/\__,_/____/                            
                                
A script to download YouTube playlists into albums to be imported into Apple Music.
'''

# Function to process playlists
process_playlists() {
    # Check if the lock file exists, indicating another instance is running
    if [ -e "process.lock" ]; then
        rm -f process.lock
        return
    fi

    # Create a lock file to indicate that processing is in progress
    touch process.lock

    # Read the first line from playlists.txt
    read -r PLAYLIST_URL < playlists.txt

    # Exit the function if playlists.txt is empty
    [ -z "$PLAYLIST_URL" ] && return

    echo "$PLAYLIST_URL"

    echo -e "\033[0;32mRunning python main.py with link: $PLAYLIST_URL\033[0m"
    python main.py "$PLAYLIST_URL"

    MUSIC_FOLDER=$(cat output_dir.txt)
    echo -e "\033[0;36mRunning import_to_apple_music.sh...\033[0m"

    # Execute the AppleScript file with administrator privileges for each MP3 file
    echo "$PASSWORD" | sudo -S find "$MUSIC_FOLDER" -name '*.mp3' -exec osascript -e 'tell application "Music" to add POSIX file "{}"' \;

    # Cleanup
    rm -rf "$MUSIC_FOLDER"
    rm -rf "output_dir.txt"

    # Remove the processed playlist URL from playlists.txt
    sed -i '' 1d playlists.txt

    # Remove the lock file to indicate that processing is completed
    rm -f process.lock
    echo -e "\033[0;32mProcess completed successfully!\033[0m"
}

# Continuously monitor and process playlists
while true; do
    process_playlists
    # Reset terminal settings
    stty sane
    sleep 2  # Adjust sleep duration as needed
done
