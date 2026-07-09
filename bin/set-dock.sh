#!/usr/bin/env bash
# Pin the macOS dock to the apps I actually use.
# Run this manually whenever you add/remove a cask that should live on the dock.
set -euo pipefail

if ! command -v /opt/homebrew/bin/dockutil >/dev/null 2>&1; then
  echo "dockutil not found. Install it via Homebrew first."
  exit 1
fi

DOCKUTIL="/opt/homebrew/bin/dockutil"

echo "Clearing dock..."
$DOCKUTIL --remove all --no-restart 2>/dev/null || true

echo "Adding apps..."
$DOCKUTIL --add /Applications/Ghostty.app --no-restart
$DOCKUTIL --add /Applications/Spotify.app --no-restart
$DOCKUTIL --add /Applications/Visual\ Studio\ Code.app --no-restart
$DOCKUTIL --add /Applications/Notion.app --no-restart
$DOCKUTIL --add /Applications/Todoist.app --no-restart

echo "Restarting Dock..."
killall Dock
