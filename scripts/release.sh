#!/bin/bash
# Builds a universal, signed Volume Mixer zip and publishes it as a GitHub release.
#
#   scripts/release.sh notes.md             # build, check, tag v<version>, publish
#   scripts/release.sh notes.md --dry-run   # build and check only; nothing is tagged or uploaded
#
# The version is the project's MARKETING_VERSION, so bump that first. The notes file is the
# release description; the zip's SHA-256 is added to the end of it.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GH_REPO="coinwaredev/volume-mixer"
IDENTITY="FineTune NoDonate Signing"
DD="$REPO/build/ReleaseDD"
OUT="$REPO/build/release"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

NOTES="${1:?usage: scripts/release.sh notes.md [--dry-run]}"
DRY_RUN=false
[ "${2:-}" = "--dry-run" ] && DRY_RUN=true
[ -s "$NOTES" ] || { echo "Notes file $NOTES is missing or empty"; exit 1; }

VERSION=$(grep -m1 "MARKETING_VERSION = " "$REPO/FineTune.xcodeproj/project.pbxproj" | sed -E 's/.*= ([^;]+);/\1/')
TAG="v$VERSION"
ZIP="$OUT/Volume-Mixer-$VERSION.zip"
echo "==> Volume Mixer $VERSION ($TAG)"

echo "==> Checking the checkout"
cd "$REPO"
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "Commit or stash your changes first"; exit 1; }
git fetch -q origin
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "HEAD isn't what's on origin/main; push first"; exit 1; }
if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null; then
  echo "$TAG already exists on GitHub; bump MARKETING_VERSION"; exit 1
fi

echo "==> Building (Apple silicon + Intel)"
mkdir -p "$OUT"
xcodebuild -project "$REPO/FineTune.xcodeproj" -scheme FineTune -configuration Release \
  -derivedDataPath "$DD" -skipPackagePluginValidation -skipMacroValidation \
  ONLY_ACTIVE_ARCH=NO ARCHS="arm64 x86_64" \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO \
  clean build > "$OUT/build.log" 2>&1 || { tail -30 "$OUT/build.log"; exit 1; }
BUILT="$DD/Build/Products/Release/Volume Mixer.app"
[ "$(lipo -archs "$BUILT/Contents/MacOS/Volume Mixer")" = "x86_64 arm64" ] || { echo "Not a universal build"; exit 1; }

echo "==> Signing"
# Keep the build's entitlements, minus the debugging one a release shouldn't carry.
ENT="$OUT/entitlements.plist"
codesign -d --entitlements :- "$BUILT" > "$ENT" 2>/dev/null
/usr/libexec/PlistBuddy -c "Delete :com.apple.security.get-task-allow" "$ENT" 2>/dev/null || true
codesign --force --deep --sign "$IDENTITY" --entitlements "$ENT" "$BUILT"
codesign --verify --deep --strict "$BUILT"

echo "==> Zipping"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$BUILT" "$ZIP"
CHECK="$(mktemp -d)"
trap 'rm -rf "$CHECK"' EXIT
ditto -x -k "$ZIP" "$CHECK"
codesign --verify --deep --strict "$CHECK/Volume Mixer.app"
[ "$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$CHECK/Volume Mixer.app/Contents/Info.plist")" = "$VERSION" ] \
  || { echo "Zipped app reports the wrong version"; exit 1; }
SHA=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)
echo "    $ZIP"
echo "    SHA-256 $SHA"

if $DRY_RUN; then
  echo "==> Dry run: stopping before tagging and publishing"
  exit 0
fi

echo "==> Publishing $TAG"
FINAL_NOTES="$OUT/notes-$VERSION.md"
{ cat "$NOTES"; printf '\nSHA-256: `%s`\n' "$SHA"; } > "$FINAL_NOTES"
git tag -a "$TAG" -m "Volume Mixer $VERSION"
git push -q origin "$TAG"
gh release create "$TAG" "$ZIP" -R "$GH_REPO" --title "Volume Mixer $VERSION" --notes-file "$FINAL_NOTES" --verify-tag

echo "==> Checking the download"
gh release download "$TAG" -R "$GH_REPO" -p "$(basename "$ZIP")" -D "$CHECK/download"
[ "$(shasum -a 256 "$CHECK/download/$(basename "$ZIP")" | cut -d' ' -f1)" = "$SHA" ] || { echo "Uploaded zip doesn't match"; exit 1; }
echo "==> Released: https://github.com/$GH_REPO/releases/tag/$TAG"
