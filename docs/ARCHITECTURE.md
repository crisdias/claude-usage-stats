# Architecture Documentation

## Overview

The **Claude Usage Stats** (claude-usage-panel) is a GNOME Shell Extension that displays usage statistics for Anthropic's Claude AI service directly in the GNOME top bar. It fetches data from the undocumented Claude API to show utilization percentages and reset times.

## Project Structure

```
claude-usage-panel/
├── extension.js      # Main extension logic (UI & API interaction)
├── prefs.js          # Preferences dialog (GTK4/LibAdwaita)
├── metadata.json     # Extension metadata
├── stylesheet.css    # Custom styling for the extension
├── install.sh        # Installation script
├── schemas/          # GSettings schemas
└── docs/             # Documentation
```

## Key Components

### 1. Extension Logic (`extension.js`)
The core of the extension is implemented in the `ClaudeUsagePanelExtension` class, which manages the lifecycle of the `ClaudeStatsIndicator`.

*   **Lifecycle**: `enable()` initializes the indicator and adds it to the panel. `disable()` cleans up resources.
*   **ClaudeStatsIndicator**: A `PanelMenu.Button` subclass.
    *   **Panel**: Icon + percentage label in the top bar.
    *   **Dropdown Menu**:
        *   **Header**: "Claude Stats" title with connection status indicator (green dot).
        *   **Current Session**: 5-Hour Usage with badge, progress bar, and reset timer.
        *   **Weekly Limits**: 7-Day Usage with badge, progress bar, and reset timer.
        *   **Footer**: Refresh button (with timestamp), Dashboard button (opens claude.ai), Settings button.
    *   **Badges**: Color-coded status indicators (Good < 50%, Warning 50-79%, Critical ≥ 80%).
    *   **API Client**: Uses `libsoup` (Soup 3.0) for HTTP requests to `https://claude.ai/api`.
    *   **Refresh Loop**: Automatically refreshes data based on the configured interval.

### 2. Preferences (`prefs.js`)
Handles the configuration UI using LibAdwaita.
*   Allows users to set their **Session Key**.
*   Toggles **Demo Mode** for testing.
*   Sets the **Refresh Interval**.

### 3. Configuration (GSettings)
The extension uses `org.gnome.shell.extensions.claude-usage-panel` schema to persist settings.

### 4. Styling (`stylesheet.css`)
CSS classes for the GNOME Shell UI components:
*   **Status colors**: Green (#22c55e), Yellow (#f59e0b), Red (#ef4444) for Good/Warning/Critical states.
*   **Badges**: Semi-transparent backgrounds with colored text.
*   **Progress bars**: Animated width transitions, color matches badge state.
*   **Sections**: Rounded containers with subtle background.

## Data Flow

1.  **Initialization**: Extension loads settings (Session Key, Interval).
2.  **API Request**:
    *   If `Demo Mode` is on, it uses mock data.
    *   Otherwise, it requests the Organization ID from `https://claude.ai/api/organizations`.
    *   Then, it requests usage stats from `https://claude.ai/api/organizations/{orgID}/usage`.
3.  **Parsing**: The JSON response contains `five_hour` and `seven_day` usage windows with `utilization` (percentage used) and `resets_at` (ISO timestamp).
4.  **Display**:
    *   Panel label shows remaining percentage (100 - 5h utilization).
    *   Each section displays: utilization %, badge (Good/Warning/Critical), progress bar, reset countdown.
    *   Reset times are formatted as "Xh Ym" or "Xd Yh" depending on duration.

## Technologies Used

*   **GJS (GNOME JavaScript)**: The runtime environment.
*   **GTK4 / LibAdwaita**: For the preferences window.
*   **Soup 3.0**: For HTTP requests.
*   **St / Clutter**: For the GNOME Shell UI elements.
