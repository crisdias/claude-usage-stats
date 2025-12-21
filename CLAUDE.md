# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Usage Stats is a GNOME Shell Extension that displays Claude AI usage statistics in the GNOME top bar. It fetches data from the undocumented Claude API to show utilization percentages and reset times.

## Development Commands

### Install extension locally
```zsh
./install.sh
```

### Compile GSettings schemas (after modifying .gschema.xml)
```zsh
glib-compile-schemas schemas/
```

### Enable/disable extension
```zsh
gnome-extensions enable claude-usage-panel@crisdias.com
gnome-extensions disable claude-usage-panel@crisdias.com
```

### Open preferences dialog
```zsh
gnome-extensions prefs claude-usage-panel@crisdias.com
```

### Restart GNOME Shell (X11 only)
Press Alt+F2, type `r`, press Enter. On Wayland, log out/in is required.

### View extension logs
```zsh
journalctl -f -o cat /usr/bin/gnome-shell
```

## Architecture

### Key Files
- **extension.js** - Main extension logic with `ClaudeStatsIndicator` (PanelMenu.Button subclass) that handles UI and API calls
- **prefs.js** - Preferences dialog using GTK4/LibAdwaita
- **schemas/org.gnome.shell.extensions.claude-usage-panel.gschema.xml** - GSettings schema for configuration

### Data Flow
1. Extension loads settings (session-key, demo-mode, refresh-interval)
2. If demo mode: shows mock data
3. Otherwise: fetches org ID from `/api/organizations`, then usage from `/api/organizations/{orgID}/usage`
4. Parses `five_hour` and `seven_day` usage windows from response
5. Displays remaining percentage (100 - utilization) and reset time

### Technologies
- **GJS** - GNOME JavaScript runtime
- **Soup 3.0** - HTTP requests
- **GTK4/LibAdwaita** - Preferences UI
- **St/Clutter** - Shell UI elements

## GSettings Keys
- `session-key` (string) - Claude.ai sessionKey cookie value
- `demo-mode` (boolean, default: true) - Show demo data instead of API calls
- `refresh-interval` (int, default: 5) - Minutes between refreshes

## Supported GNOME Shell Versions
45, 46, 47, 48, 49
