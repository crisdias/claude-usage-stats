// SPDX-License-Identifier: GPL-3.0-or-later
// Claude Usage Stats - Preferences

import Adw from 'gi://Adw';
import Gio from 'gi://Gio';
import Gtk from 'gi://Gtk';

import { ExtensionPreferences, gettext as _ } from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class ClaudeUsageStatsPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();

        // Create a preferences page
        const page = new Adw.PreferencesPage({
            title: _('General'),
            icon_name: 'dialog-information-symbolic',
        });
        window.add(page);

        // Authentication group
        const authGroup = new Adw.PreferencesGroup({
            title: _('Authentication'),
            description: _('Configure your Claude.ai session key'),
        });
        page.add(authGroup);

        // Session key entry
        const sessionKeyRow = new Adw.EntryRow({
            title: _('Session Key'),
            show_apply_button: true,
        });
        sessionKeyRow.set_text(settings.get_string('session-key'));
        sessionKeyRow.connect('apply', () => {
            settings.set_string('session-key', sessionKeyRow.get_text());
        });
        authGroup.add(sessionKeyRow);

        // Demo mode toggle
        const demoModeRow = new Adw.SwitchRow({
            title: _('Demo Mode'),
            subtitle: _('Show demo data without real API calls'),
        });
        settings.bind('demo-mode', demoModeRow, 'active', Gio.SettingsBindFlags.DEFAULT);
        authGroup.add(demoModeRow);

        // Behavior group
        const behaviorGroup = new Adw.PreferencesGroup({
            title: _('Behavior'),
            description: _('Configure refresh interval and display'),
        });
        page.add(behaviorGroup);

        // Refresh interval
        const refreshRow = new Adw.SpinRow({
            title: _('Refresh Interval'),
            subtitle: _('Minutes between automatic refreshes'),
            adjustment: new Gtk.Adjustment({
                lower: 1,
                upper: 60,
                step_increment: 1,
                page_increment: 5,
                value: settings.get_int('refresh-interval'),
            }),
        });
        settings.bind('refresh-interval', refreshRow, 'value', Gio.SettingsBindFlags.DEFAULT);
        behaviorGroup.add(refreshRow);

        // Help group
        const helpGroup = new Adw.PreferencesGroup({
            title: _('Help'),
            description: _('How to get your session key'),
        });
        page.add(helpGroup);

        // Instructions
        const instructionsRow = new Adw.ActionRow({
            title: _('Getting your Session Key'),
            subtitle: _('1. Login to claude.ai\n2. Open DevTools (F12)\n3. Go to Application → Cookies\n4. Copy the "sessionKey" value'),
        });
        helpGroup.add(instructionsRow);
    }
}
