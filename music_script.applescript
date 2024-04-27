on run argv
    try
        if (count of argv) < 3 then
            display dialog "Usage: <folder_path> <playlist_name> <cover_image_url>"
            return
        end if
        
        set resourcePath to item 1 of argv -- Folder containing music files
        set playlistName to item 2 of argv -- Name of the new playlist
        set coverImagePath to item 3 of argv -- URL or path to the cover image file
        
        -- Validate and read the cover image file
        set coverImageFile to POSIX file coverImagePath
        set coverImageData to read coverImageFile as picture
        
        -- Explicitly convert the path to an alias and filter mp3 files
        tell application "System Events"
            set folderAlias to alias resourcePath
            set folderContents to files of folderAlias whose name extension is "mp3"
        end tell
        
        tell application "Music"
            -- Create a new playlist
            set newPlaylist to make new playlist with properties {name:playlistName}
            
            -- Add tracks from the specified folder to the playlist
            repeat with aFile in folderContents
                set theFile to POSIX path of (aFile as alias)
                -- Import the file into Music and assign to the playlist
                add (POSIX file theFile as alias) to newPlaylist
            end repeat
        end tell
    on error errorMessage number errorNumber
        display dialog "Error: " & errorMessage & " (Error code: " & errorNumber & ")"
    end try
end run