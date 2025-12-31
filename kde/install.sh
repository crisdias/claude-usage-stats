#!/bin/bash
# Claude Usage Stats - KDE Plasma Widget Install Script

# Change to script directory
cd "$(dirname "$0")"

WIDGET_ID="com.github.crisdias.claude-usage-stats"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$WIDGET_ID"

manual_install() {
    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # Copy package contents
    cp -r package/* "$INSTALL_DIR/"

    echo "Widget manually installed to: $INSTALL_DIR"
}

echo "Installing Claude Usage Stats Plasma widget..."

# Check if kpackagetool6 is available (Plasma 6)
if command -v kpackagetool6 &> /dev/null; then
    # Try to remove existing installation first
    kpackagetool6 -t Plasma/Applet -r "$WIDGET_ID" 2>/dev/null || true

    # Install the package
    kpackagetool6 -t Plasma/Applet -i package/

    if [ $? -eq 0 ]; then
        echo "Widget installed successfully using kpackagetool6!"
    else
        echo "kpackagetool6 failed, falling back to manual installation..."
        manual_install
    fi
else
    echo "kpackagetool6 not found, using manual installation..."
    manual_install
fi

echo ""
echo "Installation complete!"
echo ""
echo "To use the widget:"
echo "  1. Right-click on your desktop or panel"
echo "  2. Select 'Add Widgets...'"
echo "  3. Search for 'Claude Usage Stats'"
echo "  4. Drag it to your panel or desktop"
echo ""
echo "To configure:"
echo "  Right-click on the widget → Configure..."
echo ""
echo "If the widget doesn't appear, restart Plasma:"
echo "  kquitapp6 plasmashell && plasmashell &"
