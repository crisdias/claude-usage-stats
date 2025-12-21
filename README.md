# Claude Usage Stats

A GNOME Shell Extension that displays Claude AI usage statistics directly in your top bar.

![GNOME Shell Extension](https://img.shields.io/badge/GNOME-Shell_Extension-blue)

> **Disclaimer**: This is an independent, unofficial project created by the community. It is not affiliated with, endorsed by, or connected to Anthropic or Claude AI in any way. This extension uses undocumented API endpoints that may change or be discontinued at any time.

## Features

- **Real-time Usage Display**: Shows your Claude AI usage percentage in the top bar
- **Multiple Usage Windows**: Track both 5-hour and 7-day usage limits
- **Auto-refresh**: Configurable refresh interval (default: 5 minutes)
- **Demo Mode**: Test the extension without API credentials
- **Clean UI**: Built with GTK4 and LibAdwaita for native GNOME look and feel

## Screenshots

The extension displays:
- Current usage percentage in the top bar
- Detailed breakdown of 5-hour and 7-day limits
- Reset times for each usage window
- Quick links to Claude dashboard

## Requirements

- GNOME Shell 45, 46, 47, 48, or 49
- A Claude.ai account with a valid session key

## Installation

### Local Installation

1. Clone the repository:
```zsh
git clone https://github.com/yourusername/claude-usage-stats.git
cd claude-usage-stats
```

2. Run the installation script:
```zsh
./install.sh
```

3. Enable the extension:
```zsh
gnome-extensions enable claude-usage-panel@crisdias.com
```

4. Restart GNOME Shell:
   - **X11**: Press Alt+F2, type `r`, press Enter
   - **Wayland**: Log out and log back in

## Configuration

### Getting Your Session Key

1. Open [claude.ai](https://claude.ai) in your browser
2. Open Developer Tools (F12)
3. Go to Application → Cookies → https://claude.ai
4. Copy the value of the `sessionKey` cookie

### Setting Up the Extension

1. Open the preferences dialog:
```zsh
gnome-extensions prefs claude-usage-panel@crisdias.com
```

2. Paste your session key in the "Session Key" field
3. Disable "Demo Mode"
4. Adjust the refresh interval if desired (default: 5 minutes)

## Development

### Project Structure

```
claude-usage-stats/
├── extension.js          # Main extension logic
├── prefs.js             # Preferences UI
├── metadata.json        # Extension metadata
├── stylesheet.css       # Custom styles
├── schemas/             # GSettings schemas
│   └── org.gnome.shell.extensions.claude-usage-panel.gschema.xml
└── icons/               # Extension icons
    └── claude-logo.png
```

### Development Commands

**Compile GSettings schemas** (after modifying .gschema.xml):
```zsh
glib-compile-schemas schemas/
```

**View extension logs**:
```zsh
journalctl -f -o cat /usr/bin/gnome-shell
```

**Disable extension**:
```zsh
gnome-extensions disable claude-usage-panel@crisdias.com
```

### API Endpoints

The extension uses the following Claude.ai API endpoints:
- `GET /api/organizations` - Fetch organization ID
- `GET /api/organizations/{orgID}/usage` - Fetch usage statistics

Note: These are undocumented endpoints and may change without notice.

## Architecture

The extension consists of two main components:

1. **ClaudeStatsIndicator** (`extension.js`): A `PanelMenu.Button` subclass that handles:
   - UI rendering in the top bar
   - API calls to Claude.ai
   - Data parsing and display
   - Automatic refresh scheduling

2. **Preferences Window** (`prefs.js`): A GTK4/LibAdwaita preferences dialog for:
   - Session key configuration
   - Demo mode toggle
   - Refresh interval adjustment

## Technologies

- **GJS** - GNOME JavaScript runtime
- **Soup 3.0** - HTTP client library
- **GTK4/LibAdwaita** - Preferences UI
- **St/Clutter** - Shell UI elements

## Configuration Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `session-key` | string | `""` | Claude.ai sessionKey cookie value |
| `demo-mode` | boolean | `true` | Show demo data instead of real API calls |
| `refresh-interval` | int | `5` | Minutes between API refreshes |

## Troubleshooting

**Extension not showing in top bar**
- Check if enabled: `gnome-extensions list --enabled`
- Check logs: `journalctl -f -o cat /usr/bin/gnome-shell`

**"No Data Available" message**
- Verify your session key is correct
- Check if demo mode is disabled
- Ensure you have internet connectivity

**Usage not updating**
- Check the refresh interval in preferences
- Verify the session key hasn't expired

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
