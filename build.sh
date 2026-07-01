#!/bin/bash
#
# build.sh — compile MouseMover.app from source.
# No dependencies beyond the Xcode Command Line Tools (swiftc, sips, iconutil,
# qlmanage — all ship with macOS / CLT).
#
set -euo pipefail
cd "$(dirname "$0")"

APP="MouseMover.app"
BUILD="build"
rm -rf "$APP" "$BUILD"
mkdir -p "$BUILD"

echo "• Compiling…"
swiftc -O -o "$BUILD/MouseMover" MouseMover.swift \
    -framework Cocoa -framework IOKit -framework CoreGraphics -framework ApplicationServices

echo "• Rendering icon…"
# Render SVG -> PNG with QuickLook (handles gradients; present on every Mac).
qlmanage -t -s 1024 -o "$BUILD" icon.svg >/dev/null 2>&1 || true
MASTER="$BUILD/icon.svg.png"
if [ -f "$MASTER" ]; then
    SET="$BUILD/MouseMover.iconset"
    mkdir -p "$SET"
    sips -z 16   16   "$MASTER" --out "$SET/icon_16x16.png"      >/dev/null
    sips -z 32   32   "$MASTER" --out "$SET/icon_16x16@2x.png"   >/dev/null
    sips -z 32   32   "$MASTER" --out "$SET/icon_32x32.png"      >/dev/null
    sips -z 64   64   "$MASTER" --out "$SET/icon_32x32@2x.png"   >/dev/null
    sips -z 128  128  "$MASTER" --out "$SET/icon_128x128.png"    >/dev/null
    sips -z 256  256  "$MASTER" --out "$SET/icon_128x128@2x.png" >/dev/null
    sips -z 256  256  "$MASTER" --out "$SET/icon_256x256.png"    >/dev/null
    sips -z 512  512  "$MASTER" --out "$SET/icon_256x256@2x.png" >/dev/null
    sips -z 512  512  "$MASTER" --out "$SET/icon_512x512.png"    >/dev/null
    cp "$MASTER"      "$SET/icon_512x512@2x.png"
    iconutil -c icns "$SET" -o "$BUILD/MouseMover.icns"
else
    echo "  (icon render skipped — app will use a default icon)"
fi

echo "• Assembling app bundle…"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD/MouseMover" "$APP/Contents/MacOS/MouseMover"
cp Info.plist          "$APP/Contents/Info.plist"
[ -f "$BUILD/MouseMover.icns" ] && cp "$BUILD/MouseMover.icns" "$APP/Contents/Resources/MouseMover.icns"

echo "• Signing (ad-hoc)…"
codesign --force --deep --sign - "$APP"

rm -rf "$BUILD"
echo "✔ Built ./$APP"
