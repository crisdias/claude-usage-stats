#!/bin/bash
# Claude Usage Stats - Install Script

EXTENSION_UUID="claude-usage-panel@crisdias.com"
INSTALL_DIR="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"

echo "Installing Claude Usage Stats extension..."

# Create install directory
mkdir -p "$INSTALL_DIR/schemas"
mkdir -p "$INSTALL_DIR/icons"

# Copy files
cp metadata.json "$INSTALL_DIR/"
cp extension.js "$INSTALL_DIR/"
cp prefs.js "$INSTALL_DIR/"
cp stylesheet.css "$INSTALL_DIR/"
cp schemas/*.xml "$INSTALL_DIR/schemas/"
cp icons/*.png "$INSTALL_DIR/icons/" 2>/dev/null || true

# Compile schemas in the install location
glib-compile-schemas "$INSTALL_DIR/schemas/"

echo "Extension installed to: $INSTALL_DIR"
echo ""
echo "To enable the extension:"
echo "  1. Restart GNOME Shell (Alt+F2, type 'r', press Enter) OR log out/in"
echo "  2. Enable via: gnome-extensions enable $EXTENSION_UUID"
echo "  3. Or use GNOME Extensions app"
echo ""
echo "To configure:"
echo "  gnome-extensions prefs $EXTENSION_UUID"
