#!/usr/bin/env bash
set -euo pipefail

APP_NAME="SystemWatch"
BUNDLE_ID="com.codex.SystemWatch"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/dist/release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
PKG_INFO="$APP_CONTENTS/PkgInfo"
ZIP_PATH="$RELEASE_DIR/$APP_NAME-macOS.zip"

cd "$ROOT_DIR"

export SWIFT_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-module-cache"

echo "Building $APP_NAME $VERSION ($BUILD_NUMBER) for release..."
swift build -c release --disable-sandbox
BUILD_BINARY="$(swift build -c release --disable-sandbox --show-bin-path)/$APP_NAME"

echo "Staging app bundle..."
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

/usr/libexec/PlistBuddy -c "Clear dict" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_NAME" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDevelopmentRegion string en" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleInfoDictionaryVersion string 6.0" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleSupportedPlatforms array" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleSupportedPlatforms:0 string MacOSX" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_NUMBER" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string $MIN_SYSTEM_VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSPrincipalClass string NSApplication" "$INFO_PLIST"
printf 'APPL????' > "$PKG_INFO"

echo "Signing app bundle with ad-hoc identity..."
codesign --force --sign - "$APP_BUNDLE" >/dev/null
codesign --verify --deep --strict "$APP_BUNDLE"

echo "Creating zip package..."
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo
echo "Release package ready:"
echo "  $APP_BUNDLE"
echo "  $ZIP_PATH"
echo
echo "Screenshot directory:"
echo "  $ROOT_DIR/docs/screenshots"
echo
echo "Suggested screenshot names:"
echo "  overview.png"
echo "  processes.png"
echo "  menu-bar.png"
