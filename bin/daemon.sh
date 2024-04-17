#!/bin/bash

cleanup() {
    echo -e "\n\033[0;31mReceived interrupt signal. Cleaning up...\033[0m"
    rm -f process.lock
    exit 1
}

trap cleanup SIGINT


cat <<'EOF'
                                __/\ \__            
 __  __     __       __   __  __/\_\ \ ,_\    __     
/\ \/\ \  /'__`\   /'__`\/\ \/\ \/\ \ \ \/  /'__`\   
\ \ \_/ |/\ \L\.\_/\ \L\ \ \ \_\ \ \ \ \ \_/\ \L\.\_ 
 \ \___/ \ \__/.\_\ \___, \ \____/\ \_\ \__\ \__/.\_\
  \/__/   \/__/\/_/\/___/\ \/___/  \/_/\/__/\/__/\/_/
                        \ \_\                        
                         \/_/                        
                             
This is a Daemon process that monitors the playlists.txt.
Start adding playlist/song Youtube links in the file...
EOF

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

    echo -e "\033[0;32mRunning script with link: $PLAYLIST_URL\033[0m"
    ruby main.rb lib/vaquita.rb "$PLAYLIST_URL"

    RESOURCE_PATH=$(cat output_dir.txt)
    echo -e "\033[0;36mRunning import_to_apple_music.sh...\033[0m"
    # If RESOURCE_PATH is pointing to a single file
    if [ -f "$RESOURCE_PATH" ]; then
        # Execute the AppleScript file with administrator privileges for the MP3 file
        echo "$PASSWORD" | sudo -S osascript -e 'tell application "Music" to add POSIX file "'"$RESOURCE_PATH"'"'
        rm "$RESOURCE_PATH"
    else
        # Execute the AppleScript file with administrator privileges for each MP3 file
        echo "$PASSWORD" | sudo -S find "$RESOURCE_PATH" -name '*.mp3' -exec osascript -e 'tell application "Music" to add POSIX file "{}"' \;
        # Cleanup
        rm -rf "$RESOURCE_PATH"
    fi
    
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
