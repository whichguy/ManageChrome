on run {input, parameters}
	
	set youtubeURL to "https://www.youtube.com/watch?v=4R3Wha--xf4&list=PLDb25g2HgvQJ2k6Pl5TNS1D1XSs4RkTrH&t=906s&autoplay=1"
	log "YouTube URL set."
	set chromePath to "/Applications/Google Chrome.app"
	set profilePath to "Profile 3" -- Adjust the profile name as needed
	set windowBounds to {0, 25, 1900, 1060} -- The desired window position and size
	log "Chrome path, profile, and window bounds set."
	
	tell application "System Events"
		set chromeRunning to (count of (every process whose name is "Google Chrome")) > 0
	end tell
	log "Checked if Chrome is running: " & chromeRunning
	
	if chromeRunning then
		set found to false
		tell application "Google Chrome"
			repeat with w from 1 to count of windows
				set windowTabs to tabs of window w
				repeat with t from 1 to count of windowTabs
					if URL of item t of windowTabs starts with "https://www.youtube.com" then
						log "YouTube tab found in window " & w & ", tab " & t
						set URL of item t of windowTabs to youtubeURL
						log "Set URL of tab " & t & " of window " & w
						activate
						log "Activating Chrome and bringing window " & w & " to the front."
						set index of window w to 1 -- Bring the window to the front
						set active tab index of window w to t
						log "Set active tab index to " & t & " of window " & w
						set bounds of window w to windowBounds
						log "Set bounds of window " & w
						set found to true
						exit repeat
					end if
				end repeat
				if found then exit repeat
			end repeat
			if not found then
				log "No YouTube tab found. Opening new window."
				set newWindow to make new window
				tell newWindow
					set newTab to make new tab with properties {URL:youtubeURL}
					set bounds to windowBounds
				end tell
				delay 5 -- Increased delay to allow the YouTube video to fully load
				activate
				log "Activating Chrome and setting index of new window to 1."
				set index of newWindow to 1 -- Bring the window to the front
				repeat with t from (count of tabs of newWindow) to 1 by -1
					if URL of tab t of newWindow is "chrome://newtab/" then
						close tab t of newWindow
						log "Closed new tab at position " & t
					end if
				end repeat
				set active tab index of newWindow to 1
				log "Set active tab index of new window to 1."
			end if
		end tell
	else
		log "Chrome is not running. Opening Chrome with profile."
		do shell script "open -a '" & chromePath & "' --args --profile-directory='" & profilePath & "'"
		delay 5 -- Increased delay to allow the YouTube video to fully load
		tell application "Google Chrome"
			log "Creating new window in Chrome."
			set newWindow to make new window
			tell newWindow
				set newTab to make new tab with properties {URL:youtubeURL}
				set bounds to windowBounds
			end tell
			delay 5 -- Increased delay to allow the YouTube video to fully load
			activate
			log "Activating Chrome and setting index of new window to 1."
			set index of newWindow to 1 -- Bring the window to the front
			repeat with t from (count of tabs of newWindow) to 1 by -1
				if URL of tab t of newWindow is "chrome://newtab/" then
					close tab t of newWindow
					log "Closed new tab at position " & t
				end if
			end repeat
			set active tab index of newWindow to 1
			log "Set active tab index of new window to 1."
		end tell
	end if
	
	delay 10 -- adjust delay for video to start and gain focus
	log "Sending keystroke for fullscreen."
	tell application "System Events"
		tell process "Google Chrome"
			keystroke "f" -- Fullscreen command
		end tell
	end tell
	log "Script completed."
	
	
	return input
end run
