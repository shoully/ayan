#!/bin/bash
set -e

# 1. Build the App
echo "📦 Building Ayan for release..."
./build_app.sh

# 2. Define names
APP_NAME="Ayan.app"
ZIP_NAME="Ayan_macOS.zip"

# 3. Create the Installer Script (for inside the ZIP)
# This script will be renamed to Run_to_Install.command so it's double-clickable on macOS
echo "📝 Creating Automated Installer..."
cat <<'EOF' > Run_to_Install.command
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
chmod +x Run_to_Install.command

# 4. Create README_INSTALL for the ZIP
cat <<EOF > README_INSTALL.txt
# Ayan Installation

1. Double-click 'Run_to_Install.command' to automatically install Ayan to your Applications folder.
2. If prompted, enter your Mac password to grant permission.
3. Grant Ayan permission in: System Settings > Privacy & Security > Accessibility.

Manual alternative:
1. Move Ayan.app to /Applications.
2. Run 'xattr -cr /Applications/Ayan.app' in Terminal.
3. Open Ayan and grant Accessibility permissions.
EOF

# 5. Zip only the 3 specific items requested
echo "🗜️ Packaging into $ZIP_NAME..."
rm -f "$ZIP_NAME"
# We include Ayan.app, README_INSTALL.txt, and the installer script (which we'll call Run_to_Install.command)
zip -r "$ZIP_NAME" "$APP_NAME" README_INSTALL.txt Run_to_Install.command

# 6. Cleanup temp files
rm README_INSTALL.txt Run_to_Install.command

echo "✅ Done! Share $ZIP_NAME with your users."
