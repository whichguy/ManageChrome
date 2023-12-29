on run {input, parameters}
	my logAndDisplay("AppleScript triggered from Calendar event has started.")
	
	if application "Google Chrome" is running then
		tell application "Google Chrome"
			my logAndDisplay("Starting script...")
			set found to false
			repeat with w from 1 to (count of windows)
				my logAndDisplay("Checking window " & w)
				set windowTabs to tabs of window w
				repeat with t from 1 to (count of windowTabs)
					set currentURL to URL of item t of windowTabs
					my logAndDisplay("Checking tab " & t & ": " & currentURL)
					if currentURL starts with "https://www.youtube.com" or currentURL starts with "https://youtu.be" then
						my logAndDisplay("YouTube video found in tab " & t & " of window " & w)
						set found to true
						set active tab index of window w to t
						activate
						set index of window w to 1
						delay 2
						tell application "System Events" to keystroke "k"
						exit repeat
					end if
				end repeat
				if found then exit repeat
			end repeat
			if not found then my logAndDisplay("No YouTube video found.")
		end tell
	else
		my logAndDisplay("Google Chrome is not running.")
	end if
	
	return input
end run

-- Custom Function for Logging and Displaying Dialog
on logAndDisplay(message)
	log message
	display dialog message buttons {"OK"} default button "OK"
end logAndDisplay
