# CopilotUsage

![Swift](https://img.shields.io/badge/Swift-6-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A tiny native macOS menu bar app to keep an eye on your GitHub Copilot premium requests.

## Preview

```
                                   3,741 / 10,000   100% 🔋   Fri 10:42
                                 ┌──────────────────────────┐
                                 │ Remaining: 6,259 – 62.6% │
                                 │ Resets: Nov 1, 2026      │
                                 │ Updated: 10:41           │
                                 │ ──────────────────────── │
                                 │ Refresh Now          ⌘R  │
                                 │ Change Token…            │
                                 │ Remove Token             │
                                 │ ──────────────────────── │
                                 │ CopilotUsage 1.0.0       │
                                 │ Quit CopilotUsage    ⌘Q  │
                                 └──────────────────────────┘
```

## Features

- **Always Visible**: Used and total premium requests right in your menu bar
- **Stays Current**: Updates every 5 minutes, after waking from sleep, or on demand
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

### Commands

| Command | Action |
|---------|--------|
| `brew services start copilot-usage` | Start now and at every login |
| `brew services run copilot-usage` | Start now only |
| `brew services restart copilot-usage` | Restart, e.g. after `brew upgrade` |
| `brew services stop copilot-usage` | Stop and disable start at login |
| `brew uninstall copilot-usage` | Uninstall (use **Remove Token** first to clear the keychain) |

Logs are written to `$(brew --prefix)/var/log/copilot-usage.log`.

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
