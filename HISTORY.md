# Implementation history

1. Compiled the supplied AppleScript as an application and copied the main app's icon. It initially depended on `/Applications/ChatGPT.app`.
2. The main application was renamed to `ChatGPT Pro.app`, breaking the fixed path. Updated the path, then the app was renamed back.
3. Replaced fixed filenames with discovery by `com.openai.codex` in Applications folders.
4. Replaced the AppleScript wrapper with a direct shell command. The main app reported that it was opening an existing browser session; independent account behavior was not confirmed.
5. Removed conflicting Script Editor asset metadata and used a clean Info.plist with the main app's ICNS icon.
6. A compatibility warning appeared with the script-only application wrapper. Replaced its entry point with a universal Mach-O executable supporting x86_64 and arm64, which invokes the bundled shell script.
7. Packaged the final sources and reproducible build/install scripts in this repository. Build, plist, and code-signature checks validate the wrapper, not account isolation.

Local backup artifacts and personal account data are deliberately excluded. Earlier failed wrapper versions are described here rather than distributed as usable applications.
