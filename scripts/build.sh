#!/bin/zsh
set -eu
project_root=${0:A:h:h}
app_path="$project_root/build/ChatGPT Plus.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
/usr/bin/xcrun clang -Wall -Wextra -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 "$project_root/src/launcher.c" -o "$app_path/Contents/MacOS/launch-account2"
cp "$project_root/src/launch-account2.sh" "$app_path/Contents/Resources/launch-account2.sh"
cp "$project_root/src/Info.plist" "$app_path/Contents/Info.plist"
icon_found=false
for main_app in /Applications/*.app(N) "$HOME"/Applications/*.app(N); do
  bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$main_app/Contents/Info.plist" 2>/dev/null || true)
  if [[ "$bundle_id" == com.openai.codex ]]; then
    icon_file=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$main_app/Contents/Info.plist" 2>/dev/null || true)
    [[ "$icon_file" == *.icns ]] || icon_file="$icon_file.icns"
    if [[ -f "$main_app/Contents/Resources/$icon_file" ]]; then
      cp "$main_app/Contents/Resources/$icon_file" "$app_path/Contents/Resources/ChatGPT.icns"
      icon_found=true
    fi
    break
  fi
done
if [[ "$icon_found" == false ]]; then
  /usr/libexec/PlistBuddy -c 'Delete :CFBundleIconFile' "$app_path/Contents/Info.plist"
  print -u2 'Main app icon not found; using a generic icon.'
fi
/usr/bin/plutil -lint "$app_path/Contents/Info.plist"
/usr/bin/codesign --force --sign - "$app_path"
/usr/bin/codesign --verify --strict "$app_path"
print "Built: $app_path"
