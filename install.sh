#!/bin/bash
#
# install.sh — build, install to /Applications, enable auto-start at login,
# and open the Accessibility settings pane so you can grant permission.
#
set -euo pipefail
cd "$(dirname "$0")"

LABEL="local.rahul.mousemover"
APP="MouseMover.app"
DEST="/Applications/MouseMover.app"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_NUM=$(id -u)

# 1. Build from source
./build.sh

# 2. Stop any running instance
echo "• Stopping any running instance…"
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
pkill -x MouseMover 2>/dev/null || true
sleep 1

# 3. Install to /Applications
echo "• Installing to /Applications…"
rm -rf "$DEST"
cp -R "$APP" "$DEST"
codesign --force --deep --sign - "$DEST"   # re-sign at final location

# 4. Install the login item (LaunchAgent)
echo "• Installing login item…"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array><string>/Applications/MouseMover.app/Contents/MacOS/MouseMover</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><false/>
    <key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
PLISTEOF

# 5. Clear any stale Accessibility grant so the prompt is fresh for THIS build
echo "• Resetting stale Accessibility grant…"
tccutil reset Accessibility "$LABEL" 2>/dev/null || true

# 6. Launch
echo "• Launching…"
launchctl bootstrap "gui/$UID_NUM" "$PLIST"
sleep 2

open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true

cat <<'MSG'

============================================================
 ✔ MouseMover installed and running (coffee-cup menu bar icon).
============================================================

REQUIRED for Teams/Slack "active" status:
  System Settings -> Privacy & Security -> Accessibility
  -> turn ON "MouseMover"   (the pane was just opened for you)

Then reload it so the permission takes effect:
  launchctl kickstart -k gui/$(id -u)/local.rahul.mousemover

The screen-stays-awake + visible mouse movement already works
without that permission. To pause/quit, use the menu bar icon.
MSG
