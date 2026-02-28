#!/bin/bash
set -e

# 1. Build the App
echo "📦 Building Ayan for Universal (Intel + Apple Silicon)..."
./build_app.sh

# 2. Define names
APP_NAME="Ayan.app"
ZIP_NAME="Ayan_macOS.zip"

# 3. Create Install Instructions
echo "📝 Creating Install Instructions..."
cat <<EOF > INSTALL_INSTRUCTIONS.txt
# How to Install Ayan

Because Ayan requires deep system access (Accessibility APIs) to monitor your projects, macOS will initially block it. Please follow these steps:

1. Move Ayan.app to your /Applications folder.
2. Open Terminal and run this command:
   xattr -cr /Applications/Ayan.app
3. Right-click Ayan.app in your Applications folder and select 'Open'.
4. Go to System Settings > Privacy & Security > Accessibility and ensure Ayan is toggled ON.

Enjoy your zero-friction time tracking!
EOF

# 4. Zip the App and Instructions
echo "🗜️ Packaging into $ZIP_NAME..."
rm -f "$ZIP_NAME"
zip -r "$ZIP_NAME" "$APP_NAME" INSTALL_INSTRUCTIONS.txt

# 5. Cleanup
rm INSTALL_INSTRUCTIONS.txt

echo "✅ Done! Share $ZIP_NAME with your users."
