on run argv
	set requestedAction to item 1 of argv
	set desiredPath to item 2 of argv
	set desiredFile to POSIX file desiredPath

	tell application "System Events"
		set desktopList to every desktop
		if (count of desktopList) is 0 then error "No macOS desktops were found"

		if requestedAction is "check" then
			repeat with desktopItem in desktopList
				try
					set currentPath to POSIX path of ((picture of desktopItem) as alias)
				on error
					return "false"
				end try
				if currentPath is not desiredPath then return "false"
			end repeat
			return "true"
		end if

		if requestedAction is "set" then
			repeat with desktopItem in desktopList
				set picture of desktopItem to desiredFile
			end repeat
			return "true"
		end if
	end tell

	error "Unsupported wallpaper action: " & requestedAction
end run
