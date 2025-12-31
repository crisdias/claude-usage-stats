import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    Layout.minimumWidth: Kirigami.Units.gridUnit * 16
    Layout.minimumHeight: Kirigami.Units.gridUnit * 14
    Layout.preferredWidth: Kirigami.Units.gridUnit * 18
    Layout.preferredHeight: Kirigami.Units.gridUnit * 16

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Image {
                source: "../icons/claude-logo.png"
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaExtras.Heading {
                    text: "Claude Stats"
                    level: 4
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        width: Kirigami.Units.smallSpacing * 2
                        height: width
                        radius: width / 2
                        color: {
                            if (root.statusType === "demo") return "#ff9800"
                            if (root.statusType === "error") return "#f44336"
                            return "#4caf50"
                        }
                    }

                    PlasmaComponents.Label {
                        text: root.statusText
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.8
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing
        }

        // Content area
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing

            // 5-Hour Usage Section
            UsageSection {
                Layout.fillWidth: true
                title: "5-Hour Usage"
                usage: root.fiveHourUsage
                resetTime: root.fiveHourResetTime
            }

            // 7-Day Usage Section
            UsageSection {
                Layout.fillWidth: true
                title: "7-Day Usage"
                usage: root.sevenDayUsage
                resetTime: root.sevenDayResetTime
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // Footer with buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Button {
                icon.name: "view-refresh"
                text: root.refreshLabel
                onClicked: root.refresh()
                enabled: !root.isLoading

                PlasmaComponents.BusyIndicator {
                    anchors.centerIn: parent
                    running: root.isLoading
                    visible: root.isLoading
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                }
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents.Button {
                icon.name: "internet-web-browser"
                text: "Dashboard"
                onClicked: root.openDashboard()
            }

            PlasmaComponents.Button {
                icon.name: "configure"
                onClicked: root.openSettings()
                PlasmaComponents.ToolTip {
                    text: "Settings"
                }
            }
        }

    }

    // Usage Section Component
    component UsageSection: ColumnLayout {
        property string title: ""
        property int usage: 0
        property string resetTime: "--"

        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents.Label {
                text: title
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Badge
            Rectangle {
                implicitWidth: badgeText.implicitWidth + Kirigami.Units.smallSpacing * 2
                implicitHeight: badgeText.implicitHeight + Kirigami.Units.smallSpacing
                radius: Kirigami.Units.smallSpacing
                color: root.getBadgeColor(usage)

                PlasmaComponents.Label {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.getBadgeText(usage)
                    color: "white"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.bold: true
                }
            }
        }

        // Progress bar with percentage
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 0.6
                radius: height / 2
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    width: Math.max(0, (parent.width - 2) * usage / 100)
                    radius: parent.radius
                    color: root.getBadgeColor(usage)

                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                    }
                }
            }

            PlasmaComponents.Label {
                text: usage + "%"
                font.bold: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5
                horizontalAlignment: Text.AlignRight
            }
        }

        // Reset time
        PlasmaComponents.Label {
            text: "Resets in: " + resetTime
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
        }
    }
}
