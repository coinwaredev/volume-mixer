#!/bin/bash
# Builds Volume Mixer from this checkout, signs it with the local "FineTune NoDonate Signing" certificate
# (keeps macOS's audio permission across rebuilds) and installs it to /Applications.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DEST="/Applications/Volume Mixer.app"
OLD_APP="/Applications/FineTune.app"   # pre-rename install
IDENTITY="FineTune NoDonate Signing"
DD="$REPO/build/DerivedData"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

echo "==> Building"
xcodebuild -project "$REPO/FineTune.xcodeproj" -scheme FineTune -configuration Release \
  -derivedDataPath "$DD" -skipPackagePluginValidation -skipMacroValidation \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO \
  build > "$REPO/build/build.log" 2>&1 || { tail -30 "$REPO/build/build.log"; exit 1; }
BUILT="$DD/Build/Products/Release/Volume Mixer.app"

echo "==> Signing"
ENT="$REPO/build/entitlements.plist"
codesign -d --entitlements :- "$BUILT" > "$ENT" 2>/dev/null || true
ENT_ARGS=()
[ -s "$ENT" ] && ENT_ARGS=(--entitlements "$ENT")
codesign --force --deep --sign "$IDENTITY" ${ENT_ARGS[@]+"${ENT_ARGS[@]}"} "$BUILT"
codesign --verify --deep "$BUILT"

echo "==> Installing"
osascript -e 'quit app id "com.coinwaredev.VolumeMixer"' 2>/dev/null || true
sleep 2
pkill -x "Volume Mixer" 2>/dev/null || true
pkill -x FineTune 2>/dev/null || true
[ -d "$OLD_APP" ] && [ ! -d "$REPO/build/FineTune-old.app" ] && mv "$OLD_APP" "$REPO/build/FineTune-old.app"
rm -rf "$OLD_APP"
rm -rf "$REPO/build/previous.app"
[ -d "$APP_DEST" ] && mv "$APP_DEST" "$REPO/build/previous.app"
ditto "$BUILT" "$APP_DEST"
open "$APP_DEST"

sleep 8
if ! pgrep -x "Volume Mixer" >/dev/null; then
  echo "Volume Mixer didn't stay running; restoring the previous build"
  rm -rf "$APP_DEST"
  [ -d "$REPO/build/previous.app" ] && ditto "$REPO/build/previous.app" "$APP_DEST" && open "$APP_DEST"
  exit 1
fi
echo "==> Installed and running"
