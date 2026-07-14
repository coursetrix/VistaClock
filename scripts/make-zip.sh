#!/bin/bash
#
# make-zip.sh - build the self-contained VistaClock.zip installer bundle
#
# Produces a zip containing VistaClock.app plus install.command, so a user can
# download it, unzip, and run the bundled installer (which clears quarantine and
# installs to /Applications). Uses only built-in tools (xcodebuild, ditto).
#
# Output: build/VistaClock-<version>.zip  (build/ is gitignored)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

CONFIG=Release
APP_NAME=VistaClock
DERIVED="$PROJECT_DIR/build/zip-derived"

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

# Stage a folder holding the app + the bundled installer.
STAGE_ROOT="$(mktemp -d)"
STAGE="$STAGE_ROOT/$APP_NAME"
mkdir -p "$STAGE"
cp -R "$APP_PATH" "$STAGE/"
cp "$PROJECT_DIR/scripts/install.command" "$STAGE/"
chmod +x "$STAGE/install.command"

ZIP_PATH="$PROJECT_DIR/build/$APP_NAME-$VERSION.zip"
rm -f "$ZIP_PATH"

echo "==> Zipping (ditto preserves the app signature)..."
# --keepParent keeps the top-level "VistaClock" folder; --sequesterRsrc is the
# recommended way to zip an app bundle so its code signature survives.
ditto -c -k --sequesterRsrc --keepParent "$STAGE" "$ZIP_PATH"

rm -rf "$STAGE_ROOT"
echo "==> Done: $ZIP_PATH"
