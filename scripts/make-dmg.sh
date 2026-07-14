#!/bin/bash
#
# make-dmg.sh - build a styled, distributable VistaClock.dmg
#
# Produces a disk image with a custom background (drag arrow + first-launch
# instructions), the app, and a drag-to-/Applications shortcut. Uses only
# built-in tools (xcodebuild, swift, tiffutil, hdiutil, osascript) - no
# third-party packaging dependency.
#
# The app is ad-hoc signed ("Sign to Run Locally"), NOT notarized - notarization
# needs a paid Apple Developer account and is out of scope for this fork. The
# DMG background walks the user through the one-time Gatekeeper approval.
#
# Output: build/VistaClock-<version>.dmg  (build/ is gitignored)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

CONFIG=Release
APP_NAME=VistaClock
DERIVED="$PROJECT_DIR/build/dmg-derived"

# --- window / icon layout (tweak these to nudge the look) ---
WIN_W=680; WIN_H=520          # background size, in points
TITLEBAR=28                   # allowance so the window content matches WIN_H
APP_X=180;  APP_Y=215         # app icon center
APPS_X=500; APPS_Y=215        # Applications folder icon center
ICON_SIZE=128

echo "==> Building $APP_NAME ($CONFIG)..."
xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" \
    -configuration "$CONFIG" -derivedDataPath "$DERIVED" build

APP_PATH="$DERIVED/Build/Products/$CONFIG/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
    echo "error: built app not found at $APP_PATH" >&2
    exit 1
fi

echo "==> Verifying architecture (must be arm64):"
file "$APP_PATH/Contents/MacOS/$APP_NAME"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"

WORK="$(mktemp -d)"
MOUNT=""
cleanup() {
    [ -n "$MOUNT" ] && hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
    rm -rf "$WORK"
}
trap cleanup EXIT

echo "==> Rendering background..."
xcrun swift "$PROJECT_DIR/scripts/dmg-background.swift" "$WORK/bg.png" 1
xcrun swift "$PROJECT_DIR/scripts/dmg-background.swift" "$WORK/bg@2x.png" 2
tiffutil -cathidpicheck "$WORK/bg.png" "$WORK/bg@2x.png" -out "$WORK/background.tiff" >/dev/null

VOL="$APP_NAME $VERSION"
TMP_DMG="$WORK/rw.dmg"
FINAL_DMG="$PROJECT_DIR/build/$APP_NAME-$VERSION.dmg"

echo "==> Creating writable image..."
hdiutil detach "/Volumes/$VOL" -force >/dev/null 2>&1 || true   # clear any stale mount of the same name
hdiutil create -size 80m -fs HFS+ -volname "$VOL" -ov "$TMP_DMG" >/dev/null
MOUNT="$(hdiutil attach "$TMP_DMG" -nobrowse -noautoopen -noverify | grep -o '/Volumes/.*' | head -1)"
# Use the volume's ACTUAL name (macOS suffixes it if a dupe is mounted), so the
# AppleScript below targets the disk we just created, not some leftover.
VOLNAME="$(basename "$MOUNT")"

cp -R "$APP_PATH" "$MOUNT/"
ln -s /Applications "$MOUNT/Applications"
mkdir "$MOUNT/.background"
cp "$WORK/background.tiff" "$MOUNT/.background/background.tiff"

RIGHT=$((200 + WIN_W))
BOTTOM=$((120 + WIN_H + TITLEBAR))

echo "==> Styling the Finder window (volume: $VOLNAME)..."
osascript <<OSA
tell application "Finder"
  tell disk "$VOLNAME"
    open
    delay 2
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, $RIGHT, $BOTTOM}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to $ICON_SIZE
    set text size of opts to 12
    set background picture of opts to file ".background:background.tiff"
    set position of item "$APP_NAME.app" of container window to {$APP_X, $APP_Y}
    set position of item "Applications" of container window to {$APPS_X, $APPS_Y}
    update without registering applications
    delay 4
    close
  end tell
end tell
OSA

sync; sync
sleep 2
for _ in 1 2 3 4 5; do
    hdiutil detach "$MOUNT" -quiet && break || sleep 2
done
MOUNT=""

echo "==> Converting to compressed image..."
rm -f "$FINAL_DMG"
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -ov -o "$FINAL_DMG" >/dev/null

echo "==> Done: $FINAL_DMG"
