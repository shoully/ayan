#!/bin/bash
set -e

echo "Building Ayan for release..."
swift build -c release --arch arm64 --arch x86_64

APP_NAME="Ayan.app"
EXECUTABLE_NAME="Ayan"
BUILT_EXECUTABLE_PATH=".build/apple/Products/Release/$EXECUTABLE_NAME"
PLIST_PATH="Info.plist"

echo "Creating .app bundle structure..."
rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"

echo "Copying executable..."
cp "$BUILT_EXECUTABLE_PATH" "$APP_NAME/Contents/MacOS/$EXECUTABLE_NAME"

echo "Copying Info.plist..."
cp "$PLIST_PATH" "$APP_NAME/Contents/"

echo "Copying App Icon..."
cp "AppIcon.icns" "$APP_NAME/Contents/Resources/"

echo "Signing the application bundle..."
codesign --force --deep --options runtime --sign "Apple Development: SAHAR MOHAMED ARRAYEH (TW5UCGHC68)" "$APP_NAME"

echo "Build complete! Find the application at ./$APP_NAME"
