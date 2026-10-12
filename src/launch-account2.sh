#!/bin/zsh
profile_root="$HOME/Library/Application Support/ChatGPT-Account2"
mkdir -p "$profile_root/codex" "$profile_root/browser"
for app_path in /Applications/*.app(N) "$HOME"/Applications/*.app(N); do
  app_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist" 2>/dev/null)
  if [[ "$app_id" == com.openai.codex ]]; then
    app_executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app_path/Contents/Info.plist")
    export CODEX_HOME="$profile_root/codex"
    exec "$app_path/Contents/MacOS/$app_executable" "--user-data-dir=$profile_root/browser" </dev/null >>"$profile_root/launcher.log" 2>&1
  fi
done
/usr/bin/osascript -e 'display alert "ChatGPT application not found in Applications"'
exit 1
