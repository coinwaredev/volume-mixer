#!/bin/bash
# Builds this checkout, signs it with the local "FineTune NoDonate Signing" certificate
# (keeps macOS's audio permission across rebuilds) and installs it to /Applications.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DEST="/Applications/FineTune.app"
IDENTITY="FineTune NoDonate Signing"
DD="$REPO/build/DerivedData"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

echo "==> Building"
xcodebuild -project "$REPO/FineTune.xcodeproj" -scheme FineTune -configuration Release \
  -derivedDataPath "$DD" -skipPackagePluginValidation -skipMacroValidation \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO \
  build > "$REPO/build/build.log" 2>&1 || { tail -30 "$REPO/build/build.log"; exit 1; }
BUILT="$DD/Build/Products/Release/FineTune.app"

echo "==> Signing"
ENT="$REPO/build/entitlements.plist"
codesign -d --entitlements :- "$BUILT" > "$ENT" 2>/dev/null || true
ENT_ARGS=()
[ -s "$ENT" ] && ENT_ARGS=(--entitlements "$ENT")
codesign --force --deep --sign "$IDENTITY" ${ENT_ARGS[@]+"${ENT_ARGS[@]}"} "$BUILT"
codesign --verify --deep "$BUILT"

echo "==> Installing"
osascript -e 'quit app "FineTune"' 2>/dev/null || true
sleep 2
pkill -x FineTune 2>/dev/null || true
rm -rf "$REPO/build/FineTune-previous.app"
[ -d "$APP_DEST" ] && mv "$APP_DEST" "$REPO/build/FineTune-previous.app"
ditto "$BUILT" "$APP_DEST"
open "$APP_DEST"

sleep 8
if ! pgrep -x FineTune >/dev/null; then
  echo "FineTune didn't stay running; restoring the previous build"
  rm -rf "$APP_DEST"
  ditto "$REPO/build/FineTune-previous.app" "$APP_DEST" && open "$APP_DEST"
  exit 1
fi
echo "==> Installed and running"
