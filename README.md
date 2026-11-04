# CopilotUsage

![Swift](https://img.shields.io/badge/Swift-6-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A tiny native macOS menu bar app to keep an eye on your GitHub Copilot premium requests.

## Preview

```
                                   3,741 / 10,000
                                 ┌──────────────────────────────────────────┐
                                 │ ● On track · resets in 12 days           │
                                 │ ▓▓▓▓▓▓▓▓▓░░░░░░░░░│░░░░░░░░░░░░░         │
                                 │ 3,741 / 10,000 · 37.4% used              │
                                 │                                          │
                                 │ ┌─────────┐ ┌─────────┐ ┌─────────┐      │
                                 │ │Remaining│ │ Budget  │ │  Pace   │      │
                                 │ │  6,259  │ │ 521/day │ │ 312/day │      │
                                 │ └─────────┘ └─────────┘ └─────────┘      │
                                 │                                          │
                                 │ [ Cumulative | Per Day ]                 │
                                 │       (chart with quota line             │
                                 │        and projection)                   │
                                 │        ‹  October 2026  ›                │
                                 │                                          │
                                 │ ↻  ⚙  ⏻                 Updated 10:41    │
                                 └──────────────────────────────────────────┘
```

## Features

- **Always Visible**: Used and total premium requests right in your menu bar
- **Stays Current**: Updates every 5 minutes, after waking from sleep, or on demand
- **Status at a Glance**: A progress bar with a marker for how much of the month has passed, plus a one-line status
- **Forecast**: Daily budget until the reset and whether your current pace lasts, with a warning icon in the menu bar if it does not
- **History**: Charts of your usage per month right in the menu
- **Secure Token Storage**: Your GitHub token lives in the macOS keychain, never in a file
- **Starts at Login**: Runs as a Homebrew service, no Dock icon
- **Lightweight**: Native Swift and SwiftUI, no dependencies, under 1 MB binary

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

On first start the menu bar shows **Copilot: set token**. Open it and paste a
personal access token (classic) from [github.com/settings/tokens](https://github.com/settings/tokens).
No scopes are needed. The token is checked against GitHub before it is saved to your login keychain.
You can change or remove it later in the settings (⚙).

CopilotUsage is not signed with an Apple Developer ID, so macOS treats every new version as a new app.
After an update you are asked once whether CopilotUsage may access its keychain entry — choose
**Always Allow**.

### Forecast and History

The menu shows how many requests per day you can use until the quota resets and whether your current
pace lasts. The pace is based on the last 7 days, or on the average of the month while there is not
enough history yet. The status turns orange when the projection ends above 90% of your quota and red
when the quota runs out before the reset.

Every update is recorded in `~/Library/Application Support/CopilotUsage/history.json` (kept for 100 days).
The chart in the menu shows the current month and, with the arrows, earlier months. Use **Clear History…**
in the settings (⚙) to delete all recorded samples.

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
**Remove Token** and **Clear History…** in the settings (⚙). If you forgot, remove it manually:

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
4. Records each update to build the history and the forecast
5. Repeats every 5 minutes and after your Mac wakes up

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

## Authors

- Tom Hüttmann — [@tomhuettmann](https://github.com/tomhuettmann)
- Henry Pratsch — [@henrypratsch](https://github.com/henrypratsch)
