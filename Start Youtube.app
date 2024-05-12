    tell application "Google Chrome"
        set numberOfWindows to count of windows
        repeat with i from 1 to numberOfWindows
            set theWindow to window i
            tell theWindow
                activate
                delay 2 -- Ensure the window is active and ready to receive keystrokes
                try
                    tell application "System Events" to keystroke "f" -- Attempt to toggle fullscreen
                    my customLog("Keystroke 'f' sent successfully to window " & i & ".")
                on error errMsg number errNum
                    my customLog("Failed to send keystroke 'f' to window " & i & ": " & errMsg & " (Error Number: " & errNum & ")")
                end try
            end tell
            delay 1 -- Brief delay after sending the keystroke to avoid rapid switching
        end repeat
    end tell
