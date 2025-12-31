import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: compactRep

    Layout.minimumWidth: row.implicitWidth
    Layout.preferredWidth: row.implicitWidth

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Claude logo icon
        Image {
            id: icon
            source: "../icons/claude-logo.png"
            Layout.preferredHeight: parent.height * 0.75
            Layout.preferredWidth: Layout.preferredHeight
            Layout.alignment: Qt.AlignVCenter
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        // Percentage label
        PlasmaComponents.Label {
            id: label
            text: root.panelLabel
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
            visible: Plasmoid.configuration.showPercentageInPanel
            Layout.alignment: Qt.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.expanded = !root.expanded
            }
        }
    }

    // Tooltip
    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        mainText: "Claude Usage Stats"
        subText: {
            if (root.demoMode) return "Demo Mode"
            if (root.errorMessage) return "Error: " + root.errorMessage
            return "5h: " + root.fiveHourUsage + "% | 7d: " + root.sevenDayUsage + "%"
        }
    }
}
