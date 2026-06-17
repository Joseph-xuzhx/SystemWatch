#!/usr/bin/env bash
set -euo pipefail

APP_NAME="SystemWatch"
VERSION="${VERSION:-1.0.0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/dist/release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
STAGING_DIR="$RELEASE_DIR/dmg-staging"
DMG_PATH="$RELEASE_DIR/$APP_NAME-macOS.dmg"
VOLUME_NAME="$APP_NAME $VERSION"

cd "$ROOT_DIR"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Release app bundle not found. Building release package first..."
  "$ROOT_DIR/script/package_release.sh"
fi

echo "Preparing DMG staging folder..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
ditto "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

echo "Creating DMG..."
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

hdiutil imageinfo "$DMG_PATH" >/dev/null

echo
echo "DMG package ready:"
echo "  $DMG_PATH"
