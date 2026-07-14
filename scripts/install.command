#!/bin/bash
#
# install.command - installer bundled inside VistaClock.zip
#
# Run it from Terminal (see the README): it clears the macOS download-quarantine
# flag from the VistaClock.app sitting next to it, copies the app into
# /Applications, and launches it - so you never see the Gatekeeper "Apple could
# not verify... Move to Trash" warning.
#
# Run with:   bash install.command
# (Double-clicking it instead would make macOS prompt on the script itself.)

set -euo pipefail

APP_NAME="VistaClock"
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/$APP_NAME.app"
DEST="${VISTACLOCK_DEST:-/Applications}"

if [ ! -d "$SRC" ]; then
    echo "error: $APP_NAME.app was not found next to this installer." >&2
    echo "       Keep install.command and $APP_NAME.app in the same folder." >&2
    exit 1
fi

echo "==> Clearing the macOS download quarantine..."
xattr -dr com.apple.quarantine "$SRC" 2>/dev/null || true

SUDO=""
if [ ! -w "$DEST" ]; then
    echo "==> $DEST needs administrator rights; you may be asked for your password."
    SUDO="sudo"
fi

if [ -d "$DEST/$APP_NAME.app" ]; then
    echo "==> Replacing the existing $APP_NAME..."
    osascript -e "quit app \"$APP_NAME\"" 2>/dev/null || true
    $SUDO rm -rf "$DEST/$APP_NAME.app"
fi

echo "==> Installing to $DEST..."
$SUDO cp -R "$SRC" "$DEST/"
$SUDO xattr -dr com.apple.quarantine "$DEST/$APP_NAME.app" 2>/dev/null || true

echo "==> Launching $APP_NAME..."
open "$DEST/$APP_NAME.app"

echo "==> Done. $APP_NAME is in $DEST - you can delete this folder now."
