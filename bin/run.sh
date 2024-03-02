#!/bin/bash

echo '''
    _       __                     __
| |     / /___ __   _____  ____/ /
| | /| / / __ `/ | / / _ \/ __  / 
| |/ |/ / /_/ /| |/ /  __/ /_/ /  
|__/|__/\__,_/ |___/\___/\__,_/   
                                
A script to download Youtube videos to be imported into Music Libraries (e.g., Apple Music)
'''

if [ -z "$PASSWORD" ]; then
    echo -e "\033[0;31mError: PASSWORD is not set.\033[0m"
else
    echo -e "\033[0;32mPlease provide the link to the Youtube Playlist (ex. https://www.youtube.com/playlist?list=XXXX):\033[0m"
    read USER_INPUT

    echo -e "\033[0;32mRunning python main.py with link: $USER_INPUT\033[0m"
    python main.py "$USER_INPUT"

    MUSIC_FOLDER=$(cat output_dir.txt)
    echo -e "\033[0;36mRunning import_to_apple_music.sh...\033[0m"
    
    # Execute the AppleScript file with administrator privileges for each MP3 file
    echo "$PASSWORD" | sudo -S find "$MUSIC_FOLDER" -name '*.mp3' -exec osascript -e 'tell application "Music" to add POSIX file "{}"' \;


    # Cleanup
    rm -rf "$MUSIC_FOLDER"
    rm -rf "output_dir.txt"

    echo -e "\033[0;32mProcess completed successfully!\033[0m"
fi

# Reset terminal settings
stty sane
