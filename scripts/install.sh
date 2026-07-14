#!/bin/bash
#
# install.sh - download and install the latest VistaClock into /Applications.
#
# Fetching over the command line (not a browser) means the app is never tagged
# with macOS's download-quarantine flag, so Gatekeeper does not show the
# "Apple could not verify... Move to Trash" prompt. The app is ad-hoc signed and
# runs locally once installed.
#
# Easiest (read the script first, then run it):
#   curl -fsSL https://raw.githubusercontent.com/coursetrix/VistaClock/main/scripts/install.sh -o install.sh
#   less install.sh          # inspect it
#   bash install.sh
#
# One-liner (if you trust the source):
#   curl -fsSL https://raw.githubusercontent.com/coursetrix/VistaClock/main/scripts/install.sh | bash

set -euo pipefail

APP_NAME="VistaClock"
DMG_URL="https://github.com/coursetrix/VistaClock/releases/latest/download/VistaClock.dmg"
DEST="${VISTACLOCK_DEST:-/Applications}"

TMP_DIR="$(mktemp -d)"
MOUNT=""
cleanup() {
    [ -n "$MOUNT" ] && hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "==> Downloading $APP_NAME..."
curl -fL --progress-bar -o "$TMP_DIR/$APP_NAME.dmg" "$DMG_URL"

echo "==> Mounting disk image..."
MOUNT="$(hdiutil attach "$TMP_DIR/$APP_NAME.dmg" -nobrowse -noautoopen | grep -o '/Volumes/.*' | head -1)"
if [ -z "$MOUNT" ] || [ ! -d "$MOUNT/$APP_NAME.app" ]; then
    echo "error: $APP_NAME.app not found in the disk image" >&2
    exit 1
fi

# /Applications is admin-writable; fall back to sudo only if it isn't.
SUDO=""
if [ ! -w "$DEST" ]; then
    echo "==> $DEST needs administrator rights; you may be prompted for your password."
    SUDO="sudo"
fi

if [ -d "$DEST/$APP_NAME.app" ]; then
    echo "==> Replacing existing $APP_NAME..."
    osascript -e "quit app \"$APP_NAME\"" 2>/dev/null || true
    $SUDO rm -rf "$DEST/$APP_NAME.app"
fi

echo "==> Installing to $DEST..."
$SUDO cp -R "$MOUNT/$APP_NAME.app" "$DEST/"

# Belt-and-suspenders: strip any quarantine flag so the first launch is clean.
$SUDO xattr -dr com.apple.quarantine "$DEST/$APP_NAME.app" 2>/dev/null || true

echo "==> Launching $APP_NAME..."
open "$DEST/$APP_NAME.app"

echo "==> Done. $APP_NAME is installed in $DEST."
