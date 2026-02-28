#!/bin/bash
set -e

# 1. Build the App
echo "📦 Building Ayan for release..."
./build_app.sh

# 2. Define names
APP_NAME="Ayan.app"
ZIP_NAME="Ayan_macOS.zip"

# 3. Create the Installer Script (Simplified for Terminal)
echo "📝 Creating Terminal Installer..."
cat <<'EOF' > install.sh
#!/bin/bash
cd "$(dirname "$0")"
echo "🚀 Installing Ayan..."

# Check if app exists in current dir
if [ ! -d "Ayan.app" ]; then
    echo "❌ Error: Ayan.app not found in this folder."
    exit 1
fi

# 1. Move to Applications
echo "📂 Moving Ayan to /Applications (may ask for password)..."
sudo cp -R Ayan.app /Applications/

# 2. Bypass Gatekeeper
echo "🔓 Removing quarantine flags..."
sudo xattr -cr /Applications/Ayan.app

echo "✅ Installation Complete!"
echo "------------------------------------------------"
echo "👉 1. Ayan has been moved to your Applications folder."
echo "👉 2. Go to: System Settings > Privacy & Security > Accessibility."
echo "👉 3. Add 'Ayan' and ensure it's toggled ON."
echo "------------------------------------------------"

# 3. Open the app
open /Applications/Ayan.app
EOF
chmod +x install.sh

# 4. Create README_INSTALL for the ZIP
cat <<EOF > README_INSTALL.txt
# Ayan Installation

To install Ayan and bypass macOS security blocks:

1. Open your Terminal (Cmd + Space, type 'Terminal').
2. Drag the 'install.sh' file from this folder into the Terminal window.
3. Press Enter.
4. If prompted, enter your Mac password and press Enter again.
5. Grant Accessibility permissions in: System Settings > Privacy & Security > Accessibility.

Why this is needed:
Ayan tracks window titles to detect projects. macOS requires these steps to trust any app downloaded outside the App Store.
EOF

# 5. Zip the 3 items
echo "🗜️ Packaging into $ZIP_NAME..."
rm -f "$ZIP_NAME"
zip -r "$ZIP_NAME" "$APP_NAME" README_INSTALL.txt install.sh

# 6. Cleanup
rm README_INSTALL.txt install.sh

echo "✅ Done! Share $ZIP_NAME with your users."
