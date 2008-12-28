-- main.applescript
-- AutomatorCompress

--  Created by Grayson Hansard on 8/5/06.
--  Copyright 2006 From Concentrate Software. All rights reserved.

on run {input, parameters}
	set f to {}
	repeat with i in input
		if ((class of i) as string is "document file") then
			set f to f & {POSIX path of (i as alias)}
		else if (class of i is alias) then
			set f to f & {POSIX path of i}
		else if (class of i is string) then
			if (i contains ":") then -- HFS+ style path?
				set f to f & {POSIX path of (i as alias)}
			else
				set f to f & {i}
			end if
		end if
	end repeat
	
	tell application "Compress"
		activate
		set x to make new document
		tell x
			set files to f
			set name to |name| of parameters
			set compression method to |method| of parameters
		end tell
	end tell
	
	return input
end run
