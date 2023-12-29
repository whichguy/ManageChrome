property shouldLog : false -- Set to false to disable logging
property killChromeFirst : true -- Set to false to not kill Chrome at start
property shouldDisplayLog : true -- Set to false to disable display dialog
property friendlyProfileName : "FS" -- Replace with the actual friendly name


-- Custom Log Function
on customLog(message)
	if shouldLog then
		log message
		if shouldDisplayLog then
			display dialog message buttons {"OK"} default button "OK"
		end if
	end if
end customLog

-- Function to Gracefully Close Chrome and Force Quit if Necessary
on closeChromeGracefully()
	tell application "Google Chrome"
		if it is running then
			my customLog("Closing Google Chrome gracefully.")
			quit
			delay 5 -- Wait for Chrome to attempt to close gracefully
		end if
	end tell
	
	-- Check if Chrome is still running and force quit if necessary
	tell application "System Events"
		if (count of (every process whose name is "Google Chrome")) > 0 then
			my customLog("Google Chrome did not close. Force quitting.")
			do shell script "pkill -9 'Google Chrome'"
			delay 3 -- Wait a bit after force quit
		end if
	end tell
end closeChromeGracefully

-- Function to get display settings and return window bounds for the specified or first display
on getDisplayBounds(displayName)
	try
		-- Fetch display data
		set displayData to do shell script "system_profiler SPDisplaysDataType"
		set AppleScript's text item delimiters to {"Resolution: ", "UI Looks like: ", " @ ", " x ", "
"}
		set displayResolutions to text items of displayData
		
		-- Find the resolution of the specified or first display
		set displayIndex to 2 -- Default to the first display
		if displayName is not "" then
			set displayIndex to my findDisplayIndex(displayName, displayData)
		end if
		if displayIndex is not -1 then
			set screenWidth to item (displayIndex + 2) of displayResolutions
			set screenHeight to item (displayIndex + 3) of displayResolutions
		else
			set {screenWidth, screenHeight} to defaultResolution
		end if
		set AppleScript's text item delimiters to ""
		
		set windowBounds to {0, 25, screenWidth, screenHeight + 25}
		return windowBounds
	on error errMsg
		my customLog("Error fetching display settings: " & errMsg)
		return {0, 0, defaultResolution's item 1, (defaultResolution's item 2) + 25} -- Return default resolution
	end try
end getDisplayBounds

-- Function to find the index of a specific display in the system_profiler output
on findDisplayIndex(displayName, displayData)
	set AppleScript's text item delimiters to {displayName & ":", "Resolution: "}
	set displaySections to text items of displayData
	if (count of displaySections) > 2 then
		return (count of text items in item 1 of displaySections) + 1
	else
		return -1 -- Display not found
	end if
end findDisplayIndex

-- Function to Extract Profile Name from JSON Text
on extractProfileName(jsonText)
	try
		set AppleScript's text item delimiters to "\"name\":"
		set parts to text items of jsonText
		if (count of parts) > 1 then
			set namePart to item 2 of parts
			set AppleScript's text item delimiters to {",", "\""}
			set nameComponents to text items of namePart
			if (count of nameComponents) > 1 then
				set profileName to item 2 of nameComponents
				set AppleScript's text item delimiters to ""
				return profileName
			else
				error "Profile name component not found. Data inspected: " & namePart
			end if
		else
			error "Profile name delimiter '\"name\":' not found in JSON. Data inspected: " & jsonText
		end if
	on error errMsg
		my customLog("Error extracting profile name: " & errMsg)
		return "Unknown"
	end try
end extractProfileName



-- Function to Debug Profile Mappings
on debugProfileMappings()
	my customLog("Checking profile names...")
	set debugInfo to "Profile Path and Friendly Name Mapping:"
	set chromeDataPath to (path to application support folder from user domain as text) & "Google:Chrome"
	set profilePaths to paragraphs of (do shell script "ls '" & POSIX path of chromeDataPath & "' | grep 'Profile\\|Default'")
	repeat with profilePath in profilePaths
		set prefPath to chromeDataPath & ":" & profilePath & ":Preferences"
		set prefsContent to do shell script "cat '" & POSIX path of prefPath & "'"
		set profileName to my extractProfileName(prefsContent)
		set debugInfo to debugInfo & "
" & "Profile Path: " & profilePath & ", Friendly Name: " & profileName
	end repeat
	my customLog(debugInfo)
end debugProfileMappings



-- Function to Map Friendly Name to Chrome Profile Path
on mapProfileNameToFriendlyName(friendlyName)
	set chromeDataPath to (path to application support folder from user domain as text) & "Google:Chrome"
	try
		set profilePaths to paragraphs of (do shell script "ls '" & POSIX path of chromeDataPath & "' | grep 'Profile\\|Default'")
	on error errMsg
		my customLog("Error listing profile directories: " & errMsg)
		return ""
	end try
	
	repeat with profilePath in profilePaths
		try
			set prefPath to chromeDataPath & ":" & profilePath & ":Preferences"
			set prefsContent to do shell script "cat '" & POSIX path of prefPath & "'"
			set actualProfileName to my extractProfileName(prefsContent)
			if actualProfileName is friendlyName then
				return profilePath
			end if
		on error errMsg
			my customLog("Error reading profile: " & errMsg)
		end try
	end repeat
	
	return ""
end mapProfileNameToFriendlyName

-- Main Script
on run {input, parameters}
	-- Debugging Chrome Profile Mappings
	my debugProfileMappings()
	
	-- Determine which display to use
	set selectedDisplay to "" -- Default display
	if (count of parameters) > 0 and item 1 of parameters is not "" then
		set selectedDisplay to item 1 of parameters
	end if
	my customLog("Selected display: " & selectedDisplay)
	
	
	-- Kill Chrome if flag is set
	if killChromeFirst then
		my customLog("About to wait for Chrome to close.")
		my closeChromeGracefully()
	end if
	
	set youtubeURL to "https://www.youtube.com/watch?v=4R3Wha--xf4&list=PLDb25g2HgvQJ2k6Pl5TNS1D1XSs4RkTrH&t=906s&autoplay=1"
	my customLog("YouTube URL set.")
	set chromePath to "/Applications/Google Chrome.app"
	
	-- Define the profile name to use
	set profileDirectory to my mapProfileNameToFriendlyName(friendlyProfileName)
	
	if profileDirectory is "" then
		my customLog("Profile not found: " & friendlyProfileName)
		return "Profile not found"
	end if
	
	-- Fetch window bounds for the selected or first display
	set windowBounds to my getDisplayBounds(selectedDisplay)
	my customLog("Window bounds: " & windowBounds)
	
	tell application "System Events"
		set chromeRunning to (count of (every process whose name is "Google Chrome")) > 0
	end tell
	my customLog("Checked if Chrome is running: " & chromeRunning)
	
	set found to false
	if chromeRunning then
		tell application "Google Chrome"
			repeat with w from 1 to count of windows
				set windowTabs to tabs of window w
				repeat with t from 1 to count of windowTabs
					if URL of item t of windowTabs starts with "https://www.youtube.com" then
						my customLog("YouTube tab found in window " & w & ", tab " & t)
						set URL of item t of windowTabs to youtubeURL
						my customLog("Set URL of tab " & t & " of window " & w)
						activate
						my customLog("Activating Chrome and bringing window " & w & " to the front.")
						set index of window w to 1 -- Bring the window to the front
						set active tab index of window w to t
						my customLog("Set active tab index to " & t & " of window " & w)
						set bounds of window w to windowBounds
						my customLog("Set bounds of window " & w)
						set found to true
						exit repeat
					end if
				end repeat
				if found then
					set bounds of window w to windowBounds
					exit repeat
				end if
			end repeat
			if not found then
				my customLog("No YouTube tab found. Opening new window.")
				set newWindow to make new window
				tell newWindow
					set newTab to make new tab with properties {URL:youtubeURL}
					set bounds to windowBounds
				end tell
				delay 5 -- Increased delay to allow the YouTube video to fully load
				activate
				my customLog("Activating Chrome and setting index of new window to 1.")
				set index of newWindow to 1 -- Bring the window to the front
				repeat with t from (count of tabs of newWindow) to 1 by -1
					if URL of tab t of newWindow is "chrome://newtab/" then
						close tab t of newWindow
						my customLog("Closed new tab at position " & t)
					end if
				end repeat
				set active tab index of newWindow to 1
				my customLog("Set active tab index of new window to 1.")
			end if
		end tell
	else
		my customLog("Chrome is not running. Opening Chrome with profile.")
		do shell script "open -a '" & chromePath & "' --args --profile-directory='" & profileDirectory & "' --disable-session-crashed-bubble"
		
		delay 5 -- Increased delay to allow the YouTube video to fully load
		tell application "Google Chrome"
			my customLog("Creating new window in Chrome.")
			set newWindow to make new window
			tell newWindow
				set newTab to make new tab with properties {URL:youtubeURL}
				set bounds to windowBounds
			end tell
			delay 5 -- Increased delay to allow the YouTube video to fully load
			activate
			my customLog("Activating Chrome and setting index of new window to 1.")
			set index of newWindow to 1 -- Bring the window to the front
			repeat with t from (count of tabs of newWindow) to 1 by -1
				if URL of tab t of newWindow is "chrome://newtab/" then
					close tab t of newWindow
					my customLog("Closed new tab at position " & t)
				end if
			end repeat
			set active tab index of newWindow to 1
			my customLog("Set active tab index of new window to 1.")
		end tell
	end if
	
	delay 7 -- adjust delay for video to start and gain focus
	
	my customLog("Sending keystroke for fullscreen.")
	tell application "System Events"
		tell process "Google Chrome"
			keystroke "f" -- Fullscreen command
		end tell
	end tell
	
	my customLog("Script completed.")
	
	
	return input
end run
