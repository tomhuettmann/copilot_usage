# CopilotUsage

![Swift](https://img.shields.io/badge/Swift-6-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A tiny native macOS menu bar app to keep an eye on your GitHub Copilot premium requests.

## Preview

```
                                   3,741 / 10,000   100% 🔋   Fri 10:42
                                 ┌────────────────────────────────────┐
                                 │ Remaining: 6,259 – 62.6%           │
                                 │ Resets: Nov 1, 2026                │
                                 │ Budget: 1,043/day until reset      │
                                 │ Pace: ~380/day · lasts until reset │
                                 │ ────────────────────────────────── │
                                 │ ▁▂▁▃▅▂▇  1,240 last 7 days         │
                                 │ Updated: 10:41                     │
                                 │ ────────────────────────────────── │
                                 │ Refresh Now                     ⌘R │
                                 │ Change Token…                      │
                                 │ Remove Token                       │
                                 │ ────────────────────────────────── │
                                 │ CopilotUsage 1.0.0                 │
                                 │ Quit CopilotUsage               ⌘Q │
                                 └────────────────────────────────────┘
```

## Features

- **Always Visible**: Used and total premium requests right in your menu bar
- **Stays Current**: Updates every 5 minutes, after waking from sleep, or on demand
- **Forecast**: Daily budget until the reset and whether your current pace lasts, with a warning icon in the menu bar if it does not
- **History**: Sparkline of the last 7 days in the menu, charts per month in a separate window
- **Secure Token Storage**: Your GitHub token lives in the macOS keychain, never in a file
- **Starts at Login**: Runs as a Homebrew service, no Dock icon
- **Lightweight**: Native Swift and SwiftUI, no dependencies, ~300 KB binary

## Installation

### Via Homebrew

```bash
brew tap tomhuettmann/tap
brew trust tomhuettmann/tap
brew install tomhuettmann/tap/copilot-usage
brew services start copilot-usage
```

### From Source

```bash
swift build -c release
.build/release/CopilotUsage
```

## Usage

### Token

On first start the menu bar shows **Copilot: set token**. Open it, choose **Set Token…** and paste a
personal access token (classic) from [github.com/settings/tokens](https://github.com/settings/tokens).
No scopes are needed. The token is checked against GitHub before it is saved to your login keychain.

CopilotUsage is not signed with an Apple Developer ID, so macOS treats every new version as a new app.
After an update you are asked once whether CopilotUsage may access its keychain entry — choose
**Always Allow**.

### Forecast and History

The menu shows how many requests per day you can use until the quota resets and whether your current
pace lasts. The pace is based on the last 7 days, or on the average of the month while there is not
enough history yet.

Every update is recorded in `~/Library/Application Support/CopilotUsage/history.json` (kept for 100 days).
Click the sparkline in the menu to open the history window with charts per month. Use **Clear History…**
there to delete all recorded samples.

### Commands

| Command | Action |
|---------|--------|
| `brew services start copilot-usage` | Start now and at every login |
| `brew services run copilot-usage` | Start now only |
| `brew services restart copilot-usage` | Restart, e.g. after `brew upgrade` |
| `brew services stop copilot-usage` | Stop and disable start at login |
| `brew uninstall copilot-usage` | Uninstall (see below) |

Logs are written to `$(brew --prefix)/var/log/copilot-usage.log`.

### Uninstall

Homebrew cannot remove data created by the app. Before `brew uninstall copilot-usage`, choose
**Remove Token** in the menu and **Clear History…** in the history window. If you forgot, remove it manually:

```bash
security delete-generic-password -s CopilotUsage -a github-token
rm -rf ~/Library/Application\ Support/CopilotUsage
```

## Requirements

- macOS 14 or later, arm64 (Apple Silicon)
- A GitHub account with a Copilot plan
- A personal access token (classic)

## How It Works

1. Reads your token from the login keychain
2. Fetches your Copilot quota from `api.github.com/copilot_internal/user`
3. Shows used and total premium requests in the menu bar
4. Repeats every 5 minutes and after your Mac wakes up

The endpoint is not officially documented by GitHub and may change.

## Development

```bash
swift run
swift test
swift build -c release
```

Release a new version with `./create-release.sh <version>`.

## License

MIT — see [LICENSE](LICENSE).

## Author

Tom Hüttmann — [@tomhuettmann](https://github.com/tomhuettmann)
