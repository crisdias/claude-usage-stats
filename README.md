# Claude Usage Stats

A desktop widget that displays Claude AI usage statistics for both **GNOME Shell** and **KDE Plasma**.

![GNOME Shell Extension](https://img.shields.io/badge/GNOME-Shell_Extension-blue)
![KDE Plasma Widget](https://img.shields.io/badge/KDE-Plasma_Widget-54a3d8)

> **Disclaimer**: This is an independent, unofficial project created by the community. It is not affiliated with, endorsed by, or connected to Anthropic or Claude AI in any way. This extension uses undocumented API endpoints that may change or be discontinued at any time.

## Features

- **Real-time Usage Display**: Shows your Claude AI usage percentage in the panel
- **Multiple Usage Windows**: Track both 5-hour and 7-day usage limits
- **Auto-refresh**: Configurable refresh interval (default: 5 minutes)
- **Demo Mode**: Test the widget without API credentials
- **Desktop Widget** (KDE): Can be placed on desktop with full UI
- **Clean UI**: Native look and feel for each desktop environment

## Screenshots

The widget displays:
- Current usage percentage in the panel
- Detailed breakdown of 5-hour and 7-day limits
- Reset times for each usage window
- Quick links to Claude dashboard

## Requirements

### GNOME
- GNOME Shell 45, 46, 47, 48, or 49
- A Claude.ai account with a valid session key

### KDE Plasma
- KDE Plasma 6.0 or later
- A Claude.ai account with a valid session key
- `curl` (usually pre-installed)

## Installation

### GNOME

1. Clone the repository:
```bash
git clone https://github.com/crisdias/claude-usage-stats.git
cd claude-usage-stats
```

2. Run the installation script:
```bash
./gnome/install.sh
```

3. Enable the extension:
```bash
gnome-extensions enable claude-usage-panel@crisdias.com
```

4. Restart GNOME Shell:
   - **X11**: Press Alt+F2, type `r`, press Enter
   - **Wayland**: Log out and log back in

### KDE Plasma

1. Clone the repository:
```bash
git clone https://github.com/crisdias/claude-usage-stats.git
cd claude-usage-stats
```

2. Run the installation script:
```bash
./kde/install.sh
```

3. Add the widget:
   - Right-click on panel → Add Widgets → Search for "Claude Usage Stats"
   - Or right-click on desktop → Add Widgets → Search for "Claude Usage Stats"

## Configuration

### Getting Your Session Key

1. Open [claude.ai](https://claude.ai) in your browser
2. Open Developer Tools (F12)
3. Go to Application → Cookies → https://claude.ai
4. Copy the value of the `sessionKey` cookie

### Setting Up (GNOME)

1. Open the preferences dialog:
```bash
gnome-extensions prefs claude-usage-panel@crisdias.com
```

2. Paste your session key in the "Session Key" field
3. Disable "Demo Mode"
4. Adjust the refresh interval if desired (default: 5 minutes)

### Setting Up (KDE)

1. Right-click the widget → Configure
2. Paste your session key in the "Session Key" field
3. Disable "Demo Mode"
4. Adjust the refresh interval if desired (default: 5 minutes)

## Project Structure

```
claude-usage-stats/
├── gnome/                    # GNOME Shell Extension
│   ├── extension.js          # Main extension logic
│   ├── prefs.js              # Preferences UI
│   ├── metadata.json         # Extension metadata
│   ├── stylesheet.css        # Custom styles
│   ├── install.sh            # Installation script
│   └── schemas/              # GSettings schemas
│       └── org.gnome.shell.extensions.claude-usage-panel.gschema.xml
├── kde/                      # KDE Plasma Widget
│   ├── install.sh            # Installation script
│   └── package/
│       ├── metadata.json     # Widget metadata
│       └── contents/
│           ├── config/       # Configuration schema
│           │   ├── config.qml
│           │   └── main.xml
│           ├── ui/           # QML UI files
│           │   ├── main.qml
│           │   ├── CompactRepresentation.qml
│           │   ├── FullRepresentation.qml
│           │   └── configGeneral.qml
│           └── icons/
│               └── claude-logo.png
├── icons/                    # Shared icons
│   └── claude-logo.png
└── README.md
```

## Development

### GNOME

**Compile GSettings schemas** (after modifying .gschema.xml):
```bash
glib-compile-schemas gnome/schemas/
```

**View extension logs**:
```bash
journalctl -f -o cat /usr/bin/gnome-shell
```

**Disable extension**:
```bash
gnome-extensions disable claude-usage-panel@crisdias.com
```

### KDE Plasma

**Install widget for development**:
```bash
./kde/install.sh
```

**Test with plasmoidviewer**:
```bash
plasmoidviewer -a kde/package
```

**Remove widget**:
```bash
kpackagetool6 -r com.github.crisdias.claude-usage-stats
```

## API Endpoints

The widget uses the following Claude.ai API endpoints:
- `GET /api/organizations` - Fetch organization ID
- `GET /api/organizations/{orgID}/usage` - Fetch usage statistics

Note: These are undocumented endpoints and may change without notice.

## Architecture

### GNOME

1. **ClaudeStatsIndicator** (`extension.js`): A `PanelMenu.Button` subclass that handles:
   - UI rendering in the top bar
   - API calls to Claude.ai (using Soup 3.0)
   - Data parsing and display
   - Automatic refresh scheduling

2. **Preferences Window** (`prefs.js`): A GTK4/LibAdwaita preferences dialog

### KDE Plasma

1. **PlasmoidItem** (`main.qml`): Main widget component that handles:
   - API calls via curl (using Plasma5Support.DataSource)
   - State management
   - Auto-refresh timer

2. **CompactRepresentation** (`CompactRepresentation.qml`): Panel view with icon and percentage

3. **FullRepresentation** (`FullRepresentation.qml`): Desktop/popup view with full UI

## Technologies

### GNOME
- **GJS** - GNOME JavaScript runtime
- **Soup 3.0** - HTTP client library
- **GTK4/LibAdwaita** - Preferences UI
- **St/Clutter** - Shell UI elements

### KDE Plasma
- **QML/Qt 6** - UI framework
- **Kirigami** - KDE UI components
- **Plasma5Support** - System integration (DataSource for curl)

## Configuration Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `session-key` / `sessionKey` | string | `""` | Claude.ai sessionKey cookie value |
| `demo-mode` / `demoMode` | boolean | `true` | Show demo data instead of real API calls |
| `refresh-interval` / `refreshInterval` | int | `5` | Minutes between API refreshes |
| `showPercentageInPanel` (KDE only) | boolean | `true` | Show percentage next to icon in panel |

## Troubleshooting

### GNOME

**Extension not showing in top bar**
- Check if enabled: `gnome-extensions list --enabled`
- Check logs: `journalctl -f -o cat /usr/bin/gnome-shell`

### KDE Plasma

**Widget not appearing**
- Check if installed: `kpackagetool6 -l | grep claude`
- Try removing and reinstalling

### Common Issues

**"No Data Available" or error message**
- Verify your session key is correct
- Check if demo mode is disabled
- Ensure you have internet connectivity

**Usage not updating**
- Check the refresh interval in preferences
- Verify the session key hasn't expired (re-copy from browser)

## License

GPL-3.0-or-later

## Credits

Developed by Cristiano Dias ([@crisdias](https://github.com/crisdias))

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
