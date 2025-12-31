import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    // Configuration bindings
    readonly property string sessionKey: Plasmoid.configuration.sessionKey
    readonly property bool demoMode: Plasmoid.configuration.demoMode
    readonly property int refreshInterval: Plasmoid.configuration.refreshInterval
    readonly property bool showPercentageInPanel: Plasmoid.configuration.showPercentageInPanel

    // State properties
    property string orgId: ""
    property bool isLoading: false
    property string errorMessage: ""
    property var lastRefreshTime: null

    // Debug log
    property string debugLog: ""
    function log(msg) {
        console.log("[Claude Stats] " + msg)
        debugLog = debugLog + "\n" + msg
        if (debugLog.length > 2000) debugLog = debugLog.substring(debugLog.length - 2000)
    }

    // DataSource for running curl commands
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(source, data) {
            var stdout = data["stdout"].trim()
            var stderr = data["stderr"].trim()
            var exitCode = data["exit code"]

            log("Curl exit code: " + exitCode)

            if (source.indexOf("api/organizations\"") !== -1 && source.indexOf("/usage") === -1) {
                // This is the org ID request
                handleOrgIdResponse(stdout, exitCode)
            } else if (source.indexOf("/usage") !== -1) {
                // This is the usage request
                handleUsageResponse(stdout, exitCode)
            }

            disconnectSource(source)
        }
    }

    function handleOrgIdResponse(response, exitCode) {
        log("Org response: " + response.substring(0, 200))
        if (exitCode !== 0 || !response) {
            isLoading = false
            showError("Curl failed")
            return
        }

        try {
            var data = JSON.parse(response)
            if (data && data.length > 0 && data[0].uuid) {
                orgId = data[0].uuid
                log("Got org ID: " + orgId)
                fetchUsage()
            } else if (data.error) {
                isLoading = false
                showError(data.error.message || "API error")
            } else {
                isLoading = false
                showError("No organization found")
            }
        } catch (e) {
            isLoading = false
            showError("Failed to parse response")
        }
    }

    function handleUsageResponse(response, exitCode) {
        isLoading = false
        log("Usage response: " + response.substring(0, 300))

        if (exitCode !== 0 || !response) {
            showError("Curl failed")
            return
        }

        try {
            var data = JSON.parse(response)
            if (data.error) {
                showError(data.error.message || "API error")
            } else {
                parseUsageData(data)
                errorMessage = ""
                lastRefreshTime = new Date()
                updateRefreshLabel()
            }
        } catch (e) {
            showError("Failed to parse data")
        }
    }

    // Usage data
    property int fiveHourUsage: 0
    property string fiveHourResetTime: "--"
    property date fiveHourResetDate: new Date()

    property int sevenDayUsage: 0
    property string sevenDayResetTime: "--"
    property date sevenDayResetDate: new Date()

    // Panel label (shows 5-hour percentage)
    property string panelLabel: "--%"

    // Status
    property string statusText: demoMode ? "Demo Mode" : (errorMessage ? errorMessage : "Connected")
    property string statusType: demoMode ? "demo" : (errorMessage ? "error" : "connected")

    // Preferred representations - use full on desktop, compact in panel
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    // Auto-refresh timer
    Timer {
        id: refreshTimer
        interval: root.refreshInterval * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // Refresh label update timer
    Timer {
        id: refreshLabelTimer
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.updateRefreshLabel()
    }

    // Helper function to get badge status
    function getBadgeStatus(usage) {
        if (usage < 50) return "good"
        if (usage < 80) return "warning"
        return "critical"
    }

    // Helper function to get badge color
    function getBadgeColor(usage) {
        if (usage < 50) return "#4caf50" // Green
        if (usage < 80) return "#ff9800" // Orange
        return "#f44336" // Red
    }

    // Helper function to get badge text
    function getBadgeText(usage) {
        if (usage < 50) return "Good"
        if (usage < 80) return "Warning"
        return "Critical"
    }

    // Format reset time
    function formatResetTime(resetDate) {
        var now = new Date()
        var diffMs = resetDate - now

        if (diffMs <= 0) return "Soon"

        var days = Math.floor(diffMs / (1000 * 60 * 60 * 24))
        var hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
        var minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60))

        if (days > 0) {
            return days + "d " + hours + "h"
        }
        return hours + "h " + minutes + "m"
    }

    // Update refresh label
    property string refreshLabel: "Never"
    function updateRefreshLabel() {
        if (!lastRefreshTime) {
            refreshLabel = "Never"
            return
        }

        var now = new Date()
        var diffMs = now - lastRefreshTime
        var minutes = Math.floor(diffMs / 60000)

        if (minutes < 1) {
            refreshLabel = "just now"
        } else if (minutes === 1) {
            refreshLabel = "1 min ago"
        } else {
            refreshLabel = minutes + " min ago"
        }
    }

    // Load demo data
    function loadDemoData() {
        fiveHourUsage = 8
        sevenDayUsage = 77
        panelLabel = "8%"

        var now = new Date()
        fiveHourResetDate = new Date(now.getTime() + (2 * 60 + 53) * 60 * 1000)
        sevenDayResetDate = new Date(now.getTime() + (2 * 24 + 11) * 60 * 60 * 1000)

        fiveHourResetTime = formatResetTime(fiveHourResetDate)
        sevenDayResetTime = formatResetTime(sevenDayResetDate)

        errorMessage = ""
        lastRefreshTime = new Date()
        updateRefreshLabel()
    }

    // Fetch organization ID
    function fetchOrgId() {
        log("Fetching org ID...")
        log("Session key length: " + sessionKey.length)

        var cmd = 'curl -s "https://claude.ai/api/organizations" ' +
            '-H "Cookie: sessionKey=' + sessionKey + '" ' +
            '-H "Accept: */*" ' +
            '-H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0" ' +
            '-H "Referer: https://claude.ai/" ' +
            '-H "anthropic-client-platform: web_claude_ai" ' +
            '-H "anthropic-client-version: 1.0.0" ' +
            '-H "Content-Type: application/json"'

        executable.connectSource(cmd)
    }

    // Fetch usage data
    function fetchUsage() {
        if (!orgId) {
            showError("No organization ID")
            return
        }

        log("Fetching usage for org: " + orgId)

        var cmd = 'curl -s "https://claude.ai/api/organizations/' + orgId + '/usage" ' +
            '-H "Cookie: sessionKey=' + sessionKey + '" ' +
            '-H "Accept: */*" ' +
            '-H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0" ' +
            '-H "Referer: https://claude.ai/settings/usage" ' +
            '-H "anthropic-client-platform: web_claude_ai" ' +
            '-H "anthropic-client-version: 1.0.0" ' +
            '-H "Content-Type: application/json"'

        executable.connectSource(cmd)
    }

    // Parse usage data from API response
    function parseUsageData(data) {
        var fiveHour = data.five_hour || {}
        var sevenDay = data.seven_day || {}

        fiveHourUsage = Math.round(fiveHour.utilization || 0)
        sevenDayUsage = Math.round(sevenDay.utilization || 0)

        panelLabel = fiveHourUsage + "%"

        if (fiveHour.resets_at) {
            fiveHourResetDate = new Date(fiveHour.resets_at)
            fiveHourResetTime = formatResetTime(fiveHourResetDate)
        }

        if (sevenDay.resets_at) {
            sevenDayResetDate = new Date(sevenDay.resets_at)
            sevenDayResetTime = formatResetTime(sevenDayResetDate)
        }
    }

    // Show error
    function showError(message) {
        errorMessage = message
        panelLabel = "--%"
        fiveHourUsage = 0
        sevenDayUsage = 0
        fiveHourResetTime = "--"
        sevenDayResetTime = "--"
    }

    // Main refresh function
    function refresh() {
        if (demoMode) {
            loadDemoData()
            return
        }

        if (!sessionKey) {
            showError("No session key")
            return
        }

        isLoading = true

        if (orgId) {
            fetchUsage()
        } else {
            fetchOrgId()
        }
    }

    // Open dashboard in browser
    function openDashboard() {
        Qt.openUrlExternally("https://claude.ai/settings/usage")
    }

    // Open widget settings
    function openSettings() {
        Plasmoid.internalAction("configure").trigger()
    }

    // Initial load
    Component.onCompleted: {
        refresh()
    }

    // Refresh when configuration changes
    Connections {
        target: Plasmoid.configuration
        function onSessionKeyChanged() { orgId = ""; root.refresh() }
        function onDemoModeChanged() { root.refresh() }
        function onRefreshIntervalChanged() { refreshTimer.interval = root.refreshInterval * 60 * 1000 }
    }
}
