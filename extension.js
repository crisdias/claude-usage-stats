// SPDX-License-Identifier: GPL-3.0-or-later
// Claude Usage Stats - GNOME Shell Extension

import GObject from 'gi://GObject';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Soup from 'gi://Soup?version=3.0';
import St from 'gi://St';
import Clutter from 'gi://Clutter';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

import { Extension, gettext as _ } from 'resource:///org/gnome/shell/extensions/extension.js';

const CLAUDE_API_BASE = 'https://claude.ai/api';

class ClaudeStatsIndicator extends PanelMenu.Button {
    static {
        GObject.registerClass(this);
    }

    _init(extension) {
        super._init(0.0, _('Claude Usage Stats'));

        this._extension = extension;
        this._settings = extension.getSettings();
        this._httpSession = new Soup.Session();
        this._refreshTimeout = null;
        this._orgId = null;

        // Panel button layout
        this._box = new St.BoxLayout({ style_class: 'panel-status-menu-box' });

        const iconPath = this._extension.path + '/icons/claude-logo.png';
        const iconFile = Gio.File.new_for_path(iconPath);
        const gicon = new Gio.FileIcon({ file: iconFile });
        this._icon = new St.Icon({
            gicon: gicon,
            style_class: 'system-status-icon',
        });

        this._label = new St.Label({
            text: '--%',
            y_align: Clutter.ActorAlign.CENTER,
        });

        this._box.add_child(this._icon);
        this._box.add_child(this._label);
        this.add_child(this._box);

        // Popup menu content
        this._buildMenu();

        // Connect settings changes
        this._settingsChangedId = this._settings.connect('changed', () => {
            this._refresh();
        });

        // Initial load
        this._refresh();
    }

    _buildMenu() {
        // Header with title and status
        const headerItem = new PopupMenu.PopupBaseMenuItem({ reactive: false, style_class: 'claude-usage-panel-header' });
        const headerBox = new St.BoxLayout({ vertical: false, x_expand: true });

        // Load Claude logo from extension directory
        const iconPath = this._extension.path + '/icons/claude-logo.png';
        const iconFile = Gio.File.new_for_path(iconPath);
        const gicon = new Gio.FileIcon({ file: iconFile });
        this._headerIcon = new St.Icon({
            gicon: gicon,
            style_class: 'claude-usage-panel-header-icon',
        });

        const headerTextBox = new St.BoxLayout({ vertical: true, x_expand: true });
        const titleLabel = new St.Label({ text: 'Claude Stats', style_class: 'claude-usage-panel-title' });

        this._statusBox = new St.BoxLayout({ vertical: false });
        this._statusDot = new St.Icon({
            icon_name: 'radio-symbolic',
            style_class: 'claude-usage-panel-status-dot',
        });
        this._statusLabel = new St.Label({ text: _('Connecting...'), style_class: 'claude-usage-panel-status-text' });
        this._statusBox.add_child(this._statusDot);
        this._statusBox.add_child(this._statusLabel);

        headerTextBox.add_child(titleLabel);
        headerTextBox.add_child(this._statusBox);
        headerBox.add_child(this._headerIcon);
        headerBox.add_child(headerTextBox);
        headerItem.add_child(headerBox);
        this.menu.addMenuItem(headerItem);

        // === CURRENT SESSION Section ===
        const sessionSection = new PopupMenu.PopupBaseMenuItem({ reactive: false });
        const sessionBox = new St.BoxLayout({ vertical: true, x_expand: true, style_class: 'claude-usage-panel-section' });

        const sessionHeader = new St.BoxLayout({ vertical: false });
        const sessionIcon = new St.Icon({ icon_name: 'appointment-soon-symbolic', style_class: 'claude-usage-panel-section-icon' });
        const sessionTitle = new St.Label({ text: _('CURRENT SESSION'), style_class: 'claude-usage-panel-section-title' });
        sessionHeader.add_child(sessionIcon);
        sessionHeader.add_child(sessionTitle);
        sessionBox.add_child(sessionHeader);

        // 5-Hour Usage row
        const fiveHourRow = new St.BoxLayout({ vertical: false, x_expand: true, style_class: 'claude-usage-panel-usage-row' });
        const fiveHourLabel = new St.Label({ text: _('5-Hour Usage'), style_class: 'claude-usage-panel-usage-label', x_expand: true });
        this._fiveHourBadge = new St.Label({ text: 'Good', style_class: 'claude-usage-panel-badge claude-usage-panel-badge-good' });
        this._fiveHourPercent = new St.Label({ text: '--%', style_class: 'claude-usage-panel-percent' });
        fiveHourRow.add_child(fiveHourLabel);
        fiveHourRow.add_child(this._fiveHourBadge);
        fiveHourRow.add_child(this._fiveHourPercent);
        sessionBox.add_child(fiveHourRow);

        // 5-Hour progress bar
        this._fiveHourProgressBox = new St.BoxLayout({ style_class: 'claude-usage-panel-progress-container', x_expand: true });
        this._fiveHourProgressBar = new St.Widget({ style_class: 'claude-usage-panel-progress-bar' });
        this._fiveHourProgressBox.add_child(this._fiveHourProgressBar);
        sessionBox.add_child(this._fiveHourProgressBox);

        // 5-Hour reset time
        const fiveHourResetRow = new St.BoxLayout({ vertical: false, style_class: 'claude-usage-panel-reset-row' });
        const fiveHourResetIcon = new St.Icon({ icon_name: 'view-refresh-symbolic', style_class: 'claude-usage-panel-reset-icon' });
        this._fiveHourResetLabel = new St.Label({ text: _('Resets in --'), style_class: 'claude-usage-panel-reset-label' });
        fiveHourResetRow.add_child(fiveHourResetIcon);
        fiveHourResetRow.add_child(this._fiveHourResetLabel);
        sessionBox.add_child(fiveHourResetRow);

        sessionSection.add_child(sessionBox);
        this.menu.addMenuItem(sessionSection);

        // === WEEKLY LIMITS Section ===
        const weeklySection = new PopupMenu.PopupBaseMenuItem({ reactive: false });
        const weeklyBox = new St.BoxLayout({ vertical: true, x_expand: true, style_class: 'claude-usage-panel-section' });

        const weeklyHeader = new St.BoxLayout({ vertical: false });
        const weeklyIcon = new St.Icon({ icon_name: 'x-office-calendar-symbolic', style_class: 'claude-usage-panel-section-icon' });
        const weeklyTitle = new St.Label({ text: _('WEEKLY LIMITS'), style_class: 'claude-usage-panel-section-title' });
        weeklyHeader.add_child(weeklyIcon);
        weeklyHeader.add_child(weeklyTitle);
        weeklyBox.add_child(weeklyHeader);

        // 7-Day Usage row
        const sevenDayRow = new St.BoxLayout({ vertical: false, x_expand: true, style_class: 'claude-usage-panel-usage-row' });
        const sevenDayLabel = new St.Label({ text: _('7-Day Usage'), style_class: 'claude-usage-panel-usage-label', x_expand: true });
        this._sevenDayBadge = new St.Label({ text: 'Good', style_class: 'claude-usage-panel-badge claude-usage-panel-badge-good' });
        this._sevenDayPercent = new St.Label({ text: '--%', style_class: 'claude-usage-panel-percent' });
        sevenDayRow.add_child(sevenDayLabel);
        sevenDayRow.add_child(this._sevenDayBadge);
        sevenDayRow.add_child(this._sevenDayPercent);
        weeklyBox.add_child(sevenDayRow);

        // 7-Day progress bar
        this._sevenDayProgressBox = new St.BoxLayout({ style_class: 'claude-usage-panel-progress-container', x_expand: true });
        this._sevenDayProgressBar = new St.Widget({ style_class: 'claude-usage-panel-progress-bar' });
        this._sevenDayProgressBox.add_child(this._sevenDayProgressBar);
        weeklyBox.add_child(this._sevenDayProgressBox);

        // 7-Day reset time
        const sevenDayResetRow = new St.BoxLayout({ vertical: false, style_class: 'claude-usage-panel-reset-row' });
        const sevenDayResetIcon = new St.Icon({ icon_name: 'view-refresh-symbolic', style_class: 'claude-usage-panel-reset-icon' });
        this._sevenDayResetLabel = new St.Label({ text: _('Resets in --'), style_class: 'claude-usage-panel-reset-label' });
        sevenDayResetRow.add_child(sevenDayResetIcon);
        sevenDayResetRow.add_child(this._sevenDayResetLabel);
        weeklyBox.add_child(sevenDayResetRow);

        weeklySection.add_child(weeklyBox);
        this.menu.addMenuItem(weeklySection);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Footer with timestamp and buttons
        const footerItem = new PopupMenu.PopupBaseMenuItem({ reactive: false });
        const footerBox = new St.BoxLayout({ vertical: false, x_expand: true, style_class: 'claude-usage-panel-footer' });

        // Last refresh timestamp button
        this._refreshButton = new St.Button({ style_class: 'claude-usage-panel-footer-button claude-usage-panel-refresh-button' });
        const refreshButtonBox = new St.BoxLayout({ vertical: false });
        const refreshIcon = new St.Icon({ icon_name: 'view-refresh-symbolic', style_class: 'claude-usage-panel-footer-icon' });
        this._refreshLabel = new St.Label({ text: _('just now'), style_class: 'claude-usage-panel-footer-label' });
        refreshButtonBox.add_child(refreshIcon);
        refreshButtonBox.add_child(this._refreshLabel);
        this._refreshButton.set_child(refreshButtonBox);
        this._refreshButton.connect('clicked', () => this._refresh());

        // Dashboard button
        const dashboardButton = new St.Button({ style_class: 'claude-usage-panel-footer-button' });
        const dashboardBox = new St.BoxLayout({ vertical: false });
        const dashboardIcon = new St.Icon({ icon_name: 'view-grid-symbolic', style_class: 'claude-usage-panel-footer-icon' });
        const dashboardLabel = new St.Label({ text: _('Dashboard'), style_class: 'claude-usage-panel-footer-label' });
        dashboardBox.add_child(dashboardIcon);
        dashboardBox.add_child(dashboardLabel);
        dashboardButton.set_child(dashboardBox);
        dashboardButton.connect('clicked', () => {
            Gio.AppInfo.launch_default_for_uri('https://claude.ai/settings/usage', null);
            this.menu.close();
        });

        // Settings button (replaces Quit for better UX)
        const settingsButton = new St.Button({ style_class: 'claude-usage-panel-footer-button' });
        const settingsBox = new St.BoxLayout({ vertical: false });
        const settingsIcon = new St.Icon({ icon_name: 'emblem-system-symbolic', style_class: 'claude-usage-panel-footer-icon' });
        const settingsLabel = new St.Label({ text: _('Settings'), style_class: 'claude-usage-panel-footer-label' });
        settingsBox.add_child(settingsIcon);
        settingsBox.add_child(settingsLabel);
        settingsButton.set_child(settingsBox);
        settingsButton.connect('clicked', () => {
            this._extension.openPreferences();
            this.menu.close();
        });

        footerBox.add_child(this._refreshButton);
        footerBox.add_child(dashboardButton);
        footerBox.add_child(settingsButton);
        footerItem.add_child(footerBox);
        this.menu.addMenuItem(footerItem);

        // Track last refresh time
        this._lastRefreshTime = null;
    }

    async _refresh() {
        // Clear existing timeout
        if (this._refreshTimeout) {
            GLib.source_remove(this._refreshTimeout);
            this._refreshTimeout = null;
        }

        const sessionKey = this._settings.get_string('session-key');
        const demoMode = this._settings.get_boolean('demo-mode');

        if (demoMode) {
            this._showDemoData();
        } else if (!sessionKey) {
            this._showError(_('No session key configured'));
        } else {
            try {
                await this._fetchData(sessionKey);
            } catch (e) {
                this._showError(e.message);
            }
        }

        // Schedule next refresh
        const interval = this._settings.get_int('refresh-interval') * 60; // Convert to seconds
        this._refreshTimeout = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, interval, () => {
            this._refresh();
            return GLib.SOURCE_REMOVE;
        });
    }

    async _fetchData(sessionKey) {
        // First, get organization ID if we don't have it
        if (!this._orgId) {
            this._orgId = await this._fetchOrgId(sessionKey);
        }

        // Now fetch usage stats
        const usageUrl = `${CLAUDE_API_BASE}/organizations/${this._orgId}/usage`;
        const message = Soup.Message.new('GET', usageUrl);
        message.request_headers.append('Cookie', `sessionKey=${sessionKey}`);
        message.request_headers.append('Accept', '*/*');
        message.request_headers.append('User-Agent', 'Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0');
        message.request_headers.append('Referer', 'https://claude.ai/settings/usage');
        message.request_headers.append('anthropic-client-platform', 'web_claude_ai');
        message.request_headers.append('anthropic-client-version', '1.0.0');
        message.request_headers.append('content-type', 'application/json');

        const bytes = await this._httpSession.send_and_read_async(message, GLib.PRIORITY_DEFAULT, null);

        if (message.status_code !== 200) {
            throw new Error(`API Error: ${message.status_code}`);
        }

        const decoder = new TextDecoder('utf-8');
        const text = decoder.decode(bytes.get_data());
        const data = JSON.parse(text);

        this._updateDisplay(data);
    }

    async _fetchOrgId(sessionKey) {
        const orgsUrl = `${CLAUDE_API_BASE}/organizations`;
        const message = Soup.Message.new('GET', orgsUrl);
        message.request_headers.append('Cookie', `sessionKey=${sessionKey}`);
        message.request_headers.append('Accept', '*/*');
        message.request_headers.append('User-Agent', 'Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0');
        message.request_headers.append('Referer', 'https://claude.ai/');
        message.request_headers.append('anthropic-client-platform', 'web_claude_ai');
        message.request_headers.append('anthropic-client-version', '1.0.0');
        message.request_headers.append('content-type', 'application/json');

        const bytes = await this._httpSession.send_and_read_async(message, GLib.PRIORITY_DEFAULT, null);

        if (message.status_code !== 200) {
            throw new Error(`Failed to fetch organizations: ${message.status_code}`);
        }

        const decoder = new TextDecoder('utf-8');
        const text = decoder.decode(bytes.get_data());
        const orgs = JSON.parse(text);

        if (!orgs || orgs.length === 0) {
            throw new Error('No organizations found');
        }

        // Return the first org's UUID
        return orgs[0].uuid;
    }

    _updateDisplay(data) {
        // Real Claude API format:
        // { five_hour: { utilization: 1.0, resets_at: "..." }, seven_day: { utilization: 62.0, resets_at: "..." } }
        // utilization is percentage USED (not remaining)

        const fiveHour = data.five_hour;
        const sevenDay = data.seven_day;

        if (!fiveHour && !sevenDay) {
            this._showError(_('Invalid API response'));
            return;
        }

        // Update status to connected
        this._statusLabel.set_text(_('Account Session'));
        this._statusDot.style_class = 'claude-usage-panel-status-dot claude-usage-panel-status-connected';

        // Use five_hour as primary for panel label
        const fiveHourUsed = Math.round(fiveHour?.utilization ?? 0);
        const sevenDayUsed = Math.round(sevenDay?.utilization ?? 0);
        const remainingPercent = Math.round(100 - fiveHourUsed);

        // Update panel label (show remaining %)
        this._label.set_text(`${remainingPercent}%`);

        // Update 5-Hour section
        this._fiveHourPercent.set_text(`${fiveHourUsed}%`);
        this._updateBadge(this._fiveHourBadge, fiveHourUsed);
        this._updateProgressBar(this._fiveHourProgressBar, fiveHourUsed);
        this._updateResetTime(this._fiveHourResetLabel, fiveHour?.resets_at);

        // Update 7-Day section
        this._sevenDayPercent.set_text(`${sevenDayUsed}%`);
        this._updateBadge(this._sevenDayBadge, sevenDayUsed);
        this._updateProgressBar(this._sevenDayProgressBar, sevenDayUsed);
        this._updateResetTime(this._sevenDayResetLabel, sevenDay?.resets_at);

        // Update last refresh time
        this._lastRefreshTime = new Date();
        this._refreshLabel.set_text(_('just now'));
    }

    _updateBadge(badge, usedPercent) {
        // Remove all badge classes
        badge.style_class = 'claude-usage-panel-badge';

        if (usedPercent >= 80) {
            badge.set_text(_('Critical'));
            badge.add_style_class_name('claude-usage-panel-badge-critical');
        } else if (usedPercent >= 50) {
            badge.set_text(_('Warning'));
            badge.add_style_class_name('claude-usage-panel-badge-warning');
        } else {
            badge.set_text(_('Good'));
            badge.add_style_class_name('claude-usage-panel-badge-good');
        }
    }

    _updateProgressBar(progressBar, usedPercent) {
        const percentage = Math.max(0, Math.min(100, usedPercent));
        let colorClass = 'claude-usage-panel-progress-good';

        if (usedPercent >= 80) {
            colorClass = 'claude-usage-panel-progress-critical';
        } else if (usedPercent >= 50) {
            colorClass = 'claude-usage-panel-progress-warning';
        }

        progressBar.style_class = `claude-usage-panel-progress-bar ${colorClass}`;
        // Use absolute width based on container min-width (250px)
        const barWidth = Math.round(250 * percentage / 100);
        progressBar.set_style(`width: ${barWidth}px;`);
    }

    _updateResetTime(label, resetsAt) {
        if (!resetsAt) {
            label.set_text(_('Resets in --'));
            return;
        }

        const resetDate = new Date(resetsAt);
        const now = new Date();
        const diffMs = resetDate - now;

        if (diffMs <= 0) {
            label.set_text(_('Resets in: Soon'));
            return;
        }

        const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));
        const hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));

        if (days > 0) {
            label.set_text(_(`Resets in ${days}d ${hours}h`));
        } else {
            label.set_text(_(`Resets in ${hours}h ${minutes}m`));
        }
    }

    _showDemoData() {
        // Demo data matching reference image
        this._statusLabel.set_text(_('Demo Mode'));
        this._statusDot.style_class = 'claude-usage-panel-status-dot claude-usage-panel-status-demo';

        // Panel label
        this._label.set_text('92%');

        // 5-Hour: 8% used (Good)
        this._fiveHourPercent.set_text('8%');
        this._updateBadge(this._fiveHourBadge, 8);
        this._updateProgressBar(this._fiveHourProgressBar, 8);
        this._fiveHourResetLabel.set_text(_('Resets in 2h 53m'));

        // 7-Day: 77% used (Critical)
        this._sevenDayPercent.set_text('77%');
        this._updateBadge(this._sevenDayBadge, 77);
        this._updateProgressBar(this._sevenDayProgressBar, 77);
        this._sevenDayResetLabel.set_text(_('Resets in 2d 11h'));

        // Update refresh timestamp
        this._lastRefreshTime = new Date();
        this._refreshLabel.set_text(_('just now'));
    }

    _showError(message) {
        this._statusLabel.set_text(message);
        this._statusDot.style_class = 'claude-usage-panel-status-dot claude-usage-panel-status-error';

        // Panel label
        this._label.set_text('--');

        // Reset 5-Hour section
        this._fiveHourPercent.set_text('--%');
        this._fiveHourBadge.set_text('--');
        this._fiveHourBadge.style_class = 'claude-usage-panel-badge';
        this._fiveHourProgressBar.set_style('width: 0px;');
        this._fiveHourResetLabel.set_text(_('Resets in --'));

        // Reset 7-Day section
        this._sevenDayPercent.set_text('--%');
        this._sevenDayBadge.set_text('--');
        this._sevenDayBadge.style_class = 'claude-usage-panel-badge';
        this._sevenDayProgressBar.set_style('width: 0px;');
        this._sevenDayResetLabel.set_text(_('Resets in --'));
    }

    destroy() {
        if (this._refreshTimeout) {
            GLib.source_remove(this._refreshTimeout);
            this._refreshTimeout = null;
        }

        if (this._settingsChangedId) {
            this._settings.disconnect(this._settingsChangedId);
            this._settingsChangedId = null;
        }

        super.destroy();
    }
}


export default class ClaudeUsageStatsExtension extends Extension {
    enable() {
        this._indicator = new ClaudeStatsIndicator(this);
        Main.panel.addToStatusArea(this.uuid, this._indicator);
    }

    disable() {
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}
