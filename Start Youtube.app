property shouldLog : true -- Set to false to disable logging
property killChromeFirst : true -- Set to false to not kill Chrome at start
property shouldDisplayLog : false -- Set to false to disable display dialog
property friendlyProfileName : "FS" -- Replace with the actual friendly name
property firstDisplayURL : "https://www.youtube.com/watch?v=4R3Wha--xf4&list=PLDb25g2HgvQJ2k6Pl5TNS1D1XSs4RkTrH&t=906s&autoplay=1"
property secondDisplayURL : "https://app.wodify.com/WOD/WODDisplay.aspx?WodHeaderId=17152571&GymProgramId=13228&Date=10%2f15%2f2023&LocationId=2634"
property thirdDisplayURL : "https://athlete.trainheroic.com/#/training?pwId=44578695"

property displayOrder : {2, 1, 3} -- Manually set this based on your current setup

on sumToDisplayOne(displayDetails, arrangementOrder, index)
	-- Base case: if the end of the arrangementOrder is reached, return 0
	if index > (count of arrangementOrder) then
		return 0
	end if
	
	set currentDisplayNum to item index of arrangementOrder
	
	if currentDisplayNum is 1 then
		return 0
	end if
	
	-- Just get the current width sum
	set currentWidth to item 2 of item currentDisplayNum of displayDetails as number
	set aggregateWidth to (-1 * currentWidth)
	
	return aggregateWidth + sumToDisplayOne(displayDetails, arrangementOrder, index + 1)
	
end sumToDisplayOne

on getLeftBound(displayDetails, arrangementOrder, index, displayNumber, multiplier)
	-- Base case: if the end of the arrangementOrder is reached, return 0
	if index > (count of arrangementOrder) then
		return 0
	end if
	
	set currentDisplayNum to item index of arrangementOrder
	
	-- Just get the current width sum
	set currentWidth to item 2 of item currentDisplayNum of displayDetails as number
	
	if currentDisplayNum is 1 then
		set multiplier to 1
	end if
	
	set aggregateWidth to (multiplier * currentWidth)
	
	my customLog("Searching for left bound of Display:" & displayNumber & ", at index:" & index & " which is display: " & currentDisplayNum & ",  Width:" & aggregateWidth)
	
	if multiplier < 0 then
		if currentDisplayNum is not displayNumber then
			set toReturn to getLeftBound(displayDetails, arrangementOrder, index + 1, displayNumber, multiplier)
			my customLog("Returning " & toReturn & " for Display: " & displayNumber)
			return toReturn
		else
			set toReturn to aggregateWidth + sumToDisplayOne(displayDetails, arrangementOrder, index + 1)
			my customLog("Returning " & toReturn & " for Display: " & displayNumber)
			return toReturn
		end if
	else if currentDisplayNum is displayNumber then
		
		if currentDisplayNum is 1 then
			set aggregateWidth to 0
		end if
		
		my customLog("Searching for Display:" & displayNumber & ", Passed Display 1, and found " & displayNumber & " at index " & index & " returning 0")
		return 0
	else
		my customLog("Positive multipler, aggregate: " & aggregateWidth & ", searching for next display")
		set toReturn to aggregateWidth + getLeftBound(displayDetails, arrangementOrder, index + 1, displayNumber, multiplier)
		my customLog("Returning " & toReturn & " for Display: " & displayNumber)
		
		return toReturn
	end if
	
	
end getLeftBound


on getDisplayBounds(displayNumber)
	try
		-- Execute awk command to parse display data
		set awkCommand to "system_profiler SPDisplaysDataType | awk '/^ {8}([A-Za-z]+)/ { gsub(\":\", \"\"); display_name = $1; next ;}/^ {10}UI Looks like: ([0-9]+) x ([0-9]+) @ ([0-9]+)/ { print display_name\",\"$4\",\"$6 }'"
		
		-- my customLog(awkCommand)
		set displayData to do shell script awkCommand
		set displayLines to paragraphs of displayData
		
		-- Create a list to hold details of each display
		set displayDetails to {}
		
		-- Populate the displayDetails list
		repeat with displayLine in displayLines
			set AppleScript's text item delimiters to ","
			set details to text items of displayLine
			try
				-- Each element in displayDetails is a list with width and height of a display
				copy details to the end of displayDetails
			on error
				my customLog("Error parsing display data: " & displayLine)
			end try
		end repeat
		
		-- Construct a detailed debug message for displayDetails
		set debugMessage to "Display Details:
"
		repeat with i from 1 to count of displayDetails
			set detail to item i of displayDetails
			set debugMessage to debugMessage & "Display " & i & ": Name: " & item 1 of detail & ", Width: " & item 2 of detail & ", Height: " & item 3 of detail & "
"
		end repeat
		-- my customLog(debugMessage)
		
		-- Call the recursive function to get the left position
		set leftPosition to getLeftBound(displayDetails, displayOrder, 1, displayNumber, -1)
		
		-- Get width and height for the specified display
		set currentDisplayWidth to item 2 of item displayNumber of displayDetails as number
		set currentDisplayHeight to item 3 of item displayNumber of displayDetails as number
		
		-- Calculate the right position
		set rightPosition to leftPosition + currentDisplayWidth
		
		-- Set window bounds
		set windowBounds to {leftPosition, 0, rightPosition, currentDisplayHeight}
		set AppleScript's text item delimiters to ""
		return windowBounds
	on error errMsg
		my customLog("Error fetching display settings: " & errMsg)
		return {0, 0, 0, 0} -- Return default resolution on error
	end try
end getDisplayBounds



-- Helper function to find index of an item in a list
on findIndexInList(itemToFind, theList)
	repeat with i from 1 to count of theList
		if item i of theList is itemToFind then
			return i
		end if
	end repeat
	return 0
end findIndexInList





-- Custom Log Function
on customLog(message)
	if shouldLog then
		-- Retrieve the name of the script
		set scriptName to name of me
		
		-- Log to the AppleScript log
		log message
		
		-- Write the message to syslog with the script name
		-- do shell script "logger -t '" & scriptName & "' '" & message & "'"
		
		-- Display dialog if the setting is enabled
		if shouldDisplayLog then
			try
				display dialog message buttons {"Cancel", "OK"} default button "OK" cancel button "Cancel"
			on error number -128
				error "Script cancelled by user."
			end try
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

-- Function to decide the URL based on current time, day, and display number
on decideURL(displayNumber)
	set currentTime to current date
	set currentHour to hours of currentTime
	set currentMinutes to minutes of currentTime
	set currentDay to weekday of currentTime
	
	-- Define labels with corresponding display URLs using lists of records
	set morningCrossfit to {{display:1, URL:secondDisplayURL}, {display:2, URL:firstDisplayURL}, {display:3, URL:secondDisplayURL}}
	set advancedClass to {{display:1, URL:secondDisplayURL}, {display:2, URL:firstDisplayURL}, {display:3, URL:firstDisplayURL}}
	set crossfit to {{display:1, URL:secondDisplayURL}, {display:2, URL:firstDisplayURL}, {display:3, URL:secondDisplayURL}}
	set barbellClass to {{display:1, URL:secondDisplayURL}, {display:2, URL:firstDisplayURL}, {display:3, URL:firstDisplayURL}}
	
	-- Determine the appropriate label based on current time and day
	set label to {}
	if currentDay is not Saturday and currentDay is not Sunday and (currentHour ≥ 5 and currentHour < 15) then
		set label to morningCrossfit
	else if ((currentDay is Monday or currentDay is Wednesday or currentDay is Friday) and (currentHour ≥ 15 and currentHour < 17)) then
		set label to advancedClass
	else if ((currentDay is Monday or currentDay is Wednesday or currentDay is Friday) and currentHour ≥ 17) then
		set label to crossfit
	else if ((currentDay is Tuesday or currentDay is Thursday) and (currentHour ≥ 15 and currentHour < 19)) then
		set label to barbellClass
	else if currentDay is Saturday then
		if currentHour = 8 and currentMinutes < 55 then
			set label to morningCrossfit
		else if currentHour = 8 and currentMinutes ≥ 55 then
			set label to barbellClass
		else
			set label to advancedClass
		end if
	else if currentDay is Sunday then
		set label to morningCrossfit
	end if
	
	-- Get URL for the specific display number
	repeat with currentSetting in label
		if (display of currentSetting) is displayNumber then
			return (URL of currentSetting)
		end if
	end repeat
	
	-- Default URL if no label matches
	return firstDisplayURL
end decideURL

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

on openChromeWindowWithURL(theURL, theBounds)
	tell application "Google Chrome"
		-- Create a new window and open the URL
		set newWindow to make new window
		tell newWindow
			set newTab to make new tab with properties {URL:theURL}
			activate newWindow
			
			-- Wait for the new tab to finish loading
			set loadWaitTime to 0
			repeat until (title of newTab is not "New Tab") or (loadWaitTime is greater than 30) -- 30 seconds timeout
				delay 1
				set loadWaitTime to loadWaitTime + 1
			end repeat
			
			-- Set the bounds of the new window
			set bounds of newWindow to theBounds
			-- delay 2
			-- set bounds of newWindow to theBounds
		end tell
		
		
		
		-- Close the default "new tab" if it is present
		delay 1 -- Wait for the window and tabs to initialize
		if (count of tabs of newWindow) > 1 then
			repeat with t from (count of tabs of newWindow) to 1 by -1
				if URL of tab t of newWindow is "chrome://newtab/" then
					close tab t of newWindow
				end if
			end repeat
		end if
		
		-- Optional: Fullscreen keystroke
		--delay 3 -- Additional delay before fullscreen command
		--tell application "System Events"
		--	tell process "Google Chrome"
		--		keystroke "f" using {command down, control down} -- Fullscreen command
		--	end tell
		--end tell
	end tell
end openChromeWindowWithURL


-- Main Script
on run {input, parameters}
	my customLog("Starting the script execution.")
	
	-- Kill and restart Chrome at the beginning of the script
	if killChromeFirst then
		my customLog("Attempting to close and restart Google Chrome.")
		my closeChromeGracefully()
	end if
	
	
	-- Fetch window bounds and open windows on each display
	my customLog("Fetching window bounds for each display.")
	set windowBounds1 to my getDisplayBounds(1)
	set windowBounds2 to my getDisplayBounds(2)
	set windowBounds3 to my getDisplayBounds(3)
	
	-- Log the window bounds for each display in a formatted manner
	my customLog("Display bounds: " & "Display 1: {Left: " & item 1 of windowBounds1 & ", Top: " & item 2 of windowBounds1 & ", Right: " & item 3 of windowBounds1 & ", Bottom: " & item 4 of windowBounds1 & "}, Display 2: {Left: " & item 1 of windowBounds2 & ", Top: " & item 2 of windowBounds2 & ", Right: " & item 3 of windowBounds2 & ", Bottom: " & item 4 of windowBounds2 & "}, Display 3: {Left: " & item 1 of windowBounds3 & ", Top: " & item 2 of windowBounds3 & ", Right: " & item 3 of windowBounds3 & ", Bottom: " & item 4 of windowBounds3 & "}")
	
	
	set URL1 to my decideURL(1)
	set URL2 to my decideURL(2)
	set URL3 to my decideURL(3)
	
	-- Log URLs for each display
	my customLog("Display URLs: Display 1 URL: " & URL1 & ", Display 2 URL: " & URL2 & ", Display 3 URL: " & URL3)
	
	my customLog("Launching Google Chrome with the specified profile: " & friendlyProfileName)
	set chromePath to "/Applications/Google Chrome.app"
	set profileDirectory to my mapProfileNameToFriendlyName(friendlyProfileName)
	if profileDirectory is "" then
		my customLog("Profile not found: " & friendlyProfileName)
		return "Profile not found"
	end if
	
	do shell script "open -a '" & chromePath & "' --args --profile-directory='" & profileDirectory & "' --disable-session-crashed-bubble"
	-- wait for chrome to launch
	delay 1
	
	my customLog("Opening Chrome windows on each display.")
	my openChromeWindowWithURL(URL1, windowBounds1)
	my openChromeWindowWithURL(URL2, windowBounds2)
	my openChromeWindowWithURL(URL3, windowBounds3)
	
	my customLog("Script execution completed.")
	return input
end run
