#!/bin/bash
set -e

echo "🚀 Starting Ayan Remote Installer..."

# 1. Download the latest release zip from GitHub
ZIP_URL="https://github.com/shoully/ayan/releases/download/v1.3.0/Ayan_macOS.zip"
TEMP_DIR=$(mktemp -d)

echo "📥 Downloading Ayan..."
curl -L "$ZIP_URL" -o "$TEMP_DIR/Ayan_macOS.zip"

# 2. Extract
echo "📦 Extracting..."
unzip -q "$TEMP_DIR/Ayan_macOS.zip" -d "$TEMP_DIR"

# 3. Move to Applications
echo "📂 Moving Ayan to /Applications (may ask for password)..."
sudo cp -R "$TEMP_DIR/Ayan.app" /Applications/

# 4. Bypass Gatekeeper
echo "🔓 Removing quarantine flags..."
sudo xattr -cr /Applications/Ayan.app

echo "✅ Installation Complete!"
echo "------------------------------------------------"
echo "👉 1. Ayan is now in your Applications folder."
echo "👉 2. Open it and grant Accessibility permissions in System Settings."
echo "------------------------------------------------"

# 5. Cleanup
rm -rf "$TEMP_DIR"

# 6. Open the app
open /Applications/Ayan.app
