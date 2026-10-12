# MultiChatGPT

Create independent ChatGPT desktop profiles, each with a Dock launcher named after a My Little Pony character.

```sh
multichatgpt clone chatgpt
# Created: ~/Applications/ChatGPT Twilight.app

multichatgpt clone chatgpt
# Created: ~/Applications/ChatGPT Rainbow.app
```

Names are random. Each command creates a fresh profile: its own browser storage, Codex home, and launcher identity. Open the new app and sign in with the account you want to use. Reopening it uses the same profile.

## Install with Homebrew

One-time setup, then install:

```sh
brew tap flavioaiello/multichatgpt https://github.com/flavioaiello/multichatgpt.git
brew trust --formula flavioaiello/multichatgpt/multichatgpt
brew install multichatgpt
```

This repository contains its own `Formula/` directory. The explicit tap URL is needed because its name does not start with `homebrew-`; the package is not in Homebrew core. See [Homebrew's tap documentation](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap).

Current Homebrew requires the formula trust step. Older releases without `brew trust` can omit that line.

Requires macOS, Homebrew, and the ChatGPT/Codex desktop application with bundle identifier `com.openai.codex`. Homebrew installs Python and compiles a native launcher for your Mac. A normal Homebrew build requires Apple's Command Line Tools (`xcode-select --install`).

## Use

```sh
# Create a fresh clone and open its login window
multichatgpt clone chatgpt --open

# Show clone names and paths
multichatgpt list

# Open one later (use a name from the list)
multichatgpt open Twilight
```

Each `.app` appears in `~/Applications`; drag it into your Dock. Names use a single word: Twilight, Rainbow, Pinkie, Fluttershy, Rarity, Applejack, and more. Existing names are skipped. After all names are used, a numeric suffix is added.

To select the main application explicitly or choose another installation directory:

```sh
multichatgpt clone chatgpt --app "/Applications/ChatGPT.app" --applications-dir /Applications
```

The source application is discovered by its bundle identifier, so it can also be named `ChatGPT Pro.app` or `Codex.app`. Each clone includes a local copy of that application and runs from its own named bundle. macOS therefore identifies the running app as **ChatGPT Twilight**, **ChatGPT Rainbow**, and so on, rather than grouping every profile under the original ChatGPT name.

## Profile separation

Each clone has a unique directory:

```text
~/Library/Application Support/multichatgpt/profiles/twilight/
├── browser/       # --user-data-dir
├── codex/         # CODEX_HOME
├── profile.json   # Name and launcher paths
└── launcher.log   # Main application's output
```

The profile directories are created with owner-only access. Browser cookies, authentication files, and Codex settings are not copied from another account.

A clone contains a local copy of the installed desktop app and a native launcher that sets its profile paths. APFS copies share file storage until modified; other volumes use a normal copy. The copied main executable and bundle are signed locally, and bundled vendor frameworks retain their signatures. OpenAI application binaries and icons are not shipped in this repository or the Homebrew package.

Each clone has a distinct app identity and profile paths. The desktop app controls its windows, login flow, and any shared macOS Keychain behavior. Testing against the compatible desktop build started a separate process with a fresh browser profile requiring sign-in, alongside the existing signed-in instance. Automated tests verify that simultaneous launchers pass distinct browser and Codex paths and keep running after the source app moves. Signing into two different accounts has not been automated. Opening an already running clone may focus its existing session. Clones do not register the original application's global document and URL handlers.

This is an unofficial tool for the compatible desktop build. The traditional ChatGPT app with a different bundle identifier is rejected rather than silently sharing account data. OpenAI documents [`CODEX_HOME`](https://learn.chatgpt.com/docs/config-file/config-advanced); its documentation does not establish this desktop multi-account launch method.

## Build and test from source

```sh
git clone git@github.com:flavioaiello/multichatgpt.git
cd multichatgpt
./bin/multichatgpt clone chatgpt
python3 -m unittest discover -s tests -v
```

Running from source requires Python 3.9+ and Xcode Command Line Tools. It compiles a universal Intel/Apple Silicon launcher when creating a clone. The Homebrew version uses a prebuilt launcher compiled during installation, so clone creation needs no compiler.

Tests use a fake desktop app and temporary directories. They check two independent launches, app names, profile reuse, refresh without losing profile data, source independence, name exhaustion, path quoting, missing apps, and rejection of incompatible applications. `brew test multichatgpt` also checks the installed CLI and native launcher end to end.

## Maintenance

```sh
brew update
brew upgrade multichatgpt

# Quit the clone, then copy the updated main app into it
multichatgpt refresh Twilight
```

Clones are self-contained and continue to work after removing the CLI or moving the source app. Run `refresh NAME` after upgrading the main app or CLI to update an existing clone while preserving its browser and Codex data. Refresh also converts older wrapper launchers to named app bundles. It refuses to replace a running clone. To remove a clone, delete its `.app` from `~/Applications`, its Dock entry, and (only if you want to erase its account data) the corresponding profile directory shown by `multichatgpt list`. To uninstall the CLI, run `brew uninstall multichatgpt`.

MIT licensed. My Little Pony names are used as profile labels; this project is not affiliated with Hasbro or OpenAI.
