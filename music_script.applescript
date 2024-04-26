on run argv
    try
        if (count of argv) < 1 then error "No folder specified."
        set resourcePath to item 1 of argv -- Get the first argument as folder path

        -- Explicitly convert the path to an alias
        tell application "System Events"
            set folderAlias to alias resourcePath
            set folderContents to files of folderAlias whose name extension is "mp3"
        end tell

        tell application "Music"
            repeat with aFile in folderContents
                set theFile to POSIX path of (aFile as alias)
                -- Import the file into Music
                add (POSIX file theFile as alias)
            end repeat
        end tell
    on error errorMessage number errorNumber
        display dialog "Error: " & errorMessage & " (Error code: " & errorNumber & ")"
    end try
end run
