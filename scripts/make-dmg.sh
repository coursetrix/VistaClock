#!/bin/bash
#
# make-dmg.sh — build a distributable VistaClock.dmg
#
# Produces a compressed disk image containing VistaClock.app plus a drag-to-
# /Applications shortcut. Uses only built-in tools (xcodebuild, hdiutil).
#
# The app is ad-hoc signed ("Sign to Run Locally"), NOT notarized — notarization
# needs a paid Apple Developer account and is out of scope for this fork. On
# another Mac the first launch will hit Gatekeeper; see the Install section of
# README.md for how recipients allow it.
#
# Output: build/VistaClock-<version>.dmg  (build/ is gitignored)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

CONFIG=Release
APP_NAME=VistaClock
DERIVED="$PROJECT_DIR/build/dmg-derived"

echo "==> Building $APP_NAME ($CONFIG)…"
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

# Stage the app + an Applications shortcut for the drag-to-install layout.
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

DMG_PATH="$PROJECT_DIR/build/$APP_NAME-$VERSION.dmg"
rm -f "$DMG_PATH"

echo "==> Creating disk image…"
hdiutil create \
    -volname "$APP_NAME $VERSION" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG_PATH"

echo "==> Done: $DMG_PATH"
