#!/bin/bash

if [ -z "$PASSWORD" ]; then
    echo -e "\033[0;31mError: PASSWORD is not set.\033[0m"
else
    echo -e "\033[0;32mPlease provide a link:\033[0m"
    read USER_INPUT

    echo -e "\033[0;32mRunning python main.py with link: $USER_INPUT\033[0m"
    python main.py "$USER_INPUT"

    MUSIC_FOLDER=$(cat output_dir.txt)
    export MUSIC_FOLDER

    echo -e "\033[0;36mRunning import_to_apple_music.sh...\033[0m"
    ./import_to_apple_music.sh "$MUSIgit C_FOLDER"

    # Cleanup
    rm -rf "$MUSIC_FOLDER"
    rm -rf "output_dir.txt"

    echo -e "\033[0;32mProcess completed successfully!\033[0m"
fi

# Reset terminal settings
stty sane
