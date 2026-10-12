#!/bin/zsh
set -eu
project_root=${0:A:h:h}
"$project_root/scripts/build.sh"
destination="${1:-$HOME/Applications}/ChatGPT Plus.app"
if [[ -e "$destination" ]]; then
  print -u2 "Already exists: $destination. Move it aside before installing."
  exit 1
fi
mkdir -p "${destination:h}"
/usr/bin/ditto "$project_root/build/ChatGPT Plus.app" "$destination"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$destination"
/usr/bin/open -R "$destination"
print "Installed: $destination"
