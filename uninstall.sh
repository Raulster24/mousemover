#!/bin/bash
#
# uninstall.sh — completely remove MouseMover.
#
set -euo pipefail

LABEL="local.rahul.mousemover"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_NUM=$(id -u)

echo "• Stopping and removing login item…"
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
pkill -x MouseMover 2>/dev/null || true
rm -f "$PLIST"

echo "• Removing app…"
rm -rf /Applications/MouseMover.app

echo "• Clearing Accessibility grant…"
tccutil reset Accessibility "$LABEL" 2>/dev/null || true

echo "✔ MouseMover removed (app, login item, and permission entry)."
