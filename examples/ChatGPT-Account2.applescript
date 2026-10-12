on run
    set profileRoot to (POSIX path of (path to home folder)) & "Library/Application Support/ChatGPT-Account2"
    set locateCommand to "for app in /Applications/*.app \"$HOME\"/Applications/*.app; do id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \"$app/Contents/Info.plist\" 2>/dev/null); if [ \"$id\" = 'com.openai.codex' ]; then printf '%s' \"$app\"; exit 0; fi; done; exit 1"
    try
        set mainAppPath to do shell script locateCommand
    on error
        display alert "ChatGPT application not found" message "Install the main ChatGPT application in Applications, then try this launcher again." as critical
        return
    end try
    do shell script "/bin/mkdir -p " & (quoted form of (profileRoot & "/codex")) & " " & (quoted form of (profileRoot & "/browser"))
    set launcherCommand to "/usr/bin/open -n -a " & (quoted form of mainAppPath)
    set launcherCommand to launcherCommand & " --stdin /dev/null --env " & (quoted form of ("CODEX_HOME=" & profileRoot & "/codex"))
    set launcherCommand to launcherCommand & " --args " & (quoted form of ("--user-data-dir=" & profileRoot & "/browser"))
    do shell script launcherCommand
end run
