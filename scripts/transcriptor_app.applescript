on run
	set appPath to POSIX path of (path to me)
	set launcherPath to appPath & "Contents/Resources/launcher.command"
	do shell script "chmod +x " & quoted form of launcherPath
	do shell script "open -a Terminal " & quoted form of launcherPath
end run
