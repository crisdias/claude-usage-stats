import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

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

    // Preferred representations
    preferredRepresentation: compactRepresentation
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
    function fetchOrgId(callback) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        if (data && data.length > 0 && data[0].uuid) {
                            orgId = data[0].uuid
                            callback(null, orgId)
                        } else {
                            callback("No organization found", null)
                        }
                    } catch (e) {
                        callback("Failed to parse response", null)
                    }
                } else {
                    callback("HTTP " + xhr.status, null)
                }
            }
        }
        xhr.open("GET", "https://claude.ai/api/organizations")
        xhr.setRequestHeader("Cookie", "sessionKey=" + sessionKey)
        xhr.setRequestHeader("Accept", "*/*")
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0")
        xhr.setRequestHeader("Referer", "https://claude.ai/")
        xhr.setRequestHeader("anthropic-client-platform", "web_claude_ai")
        xhr.setRequestHeader("anthropic-client-version", "1.0.0")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send()
    }

    // Fetch usage data
    function fetchUsage() {
        if (!orgId) {
            showError("No organization ID")
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoading = false
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        parseUsageData(data)
                        errorMessage = ""
                        lastRefreshTime = new Date()
                        updateRefreshLabel()
                    } catch (e) {
                        showError("Failed to parse data")
                    }
                } else {
                    showError("HTTP " + xhr.status)
                }
            }
        }
        xhr.open("GET", "https://claude.ai/api/organizations/" + orgId + "/usage")
        xhr.setRequestHeader("Cookie", "sessionKey=" + sessionKey)
        xhr.setRequestHeader("Accept", "*/*")
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0")
        xhr.setRequestHeader("Referer", "https://claude.ai/settings/usage")
        xhr.setRequestHeader("anthropic-client-platform", "web_claude_ai")
        xhr.setRequestHeader("anthropic-client-version", "1.0.0")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send()
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
            fetchOrgId(function(err, id) {
                if (err) {
                    isLoading = false
                    showError(err)
                } else {
                    fetchUsage()
                }
            })
        }
    }

    // Open dashboard in browser
    function openDashboard() {
        Qt.openUrlExternally("https://claude.ai/settings/usage")
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
