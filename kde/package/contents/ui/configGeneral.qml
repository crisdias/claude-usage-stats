import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_sessionKey: sessionKeyField.text
    property alias cfg_demoMode: demoModeSwitch.checked
    property alias cfg_refreshInterval: refreshIntervalSpinBox.value
    property alias cfg_showPercentageInPanel: showPercentageSwitch.checked

    // Plasma injects these automatically, declare to silence warnings
    property bool cfg_demoModeDefault: true
    property bool cfg_expanding: false

    Kirigami.FormLayout {
        // Authentication Section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Authentication")
        }

        QQC2.TextField {
            id: sessionKeyField
            Kirigami.FormData.label: i18n("Session Key:")
            placeholderText: i18n("Paste your sessionKey cookie value")
            echoMode: TextInput.Password
            Layout.fillWidth: true
        }

        QQC2.Label {
            text: i18n("To get your session key:\n1. Go to claude.ai and log in\n2. Open DevTools (F12) → Application → Cookies\n3. Copy the 'sessionKey' value")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        QQC2.Switch {
            id: demoModeSwitch
            Kirigami.FormData.label: i18n("Demo Mode:")
            text: checked ? i18n("Enabled") : i18n("Disabled")
        }

        QQC2.Label {
            text: i18n("Demo mode shows sample data without making API calls")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        // Behavior Section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Behavior")
        }

        QQC2.SpinBox {
            id: refreshIntervalSpinBox
            Kirigami.FormData.label: i18n("Refresh Interval:")
            from: 1
            to: 60
            stepSize: 1
            textFromValue: function(value) {
                return i18np("%1 minute", "%1 minutes", value)
            }
            valueFromText: function(text) {
                return parseInt(text)
            }
        }

        // Appearance Section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Appearance")
        }

        QQC2.CheckBox {
            id: showPercentageSwitch
            Kirigami.FormData.label: i18n("Show percentage in panel:")
            text: i18n("Show percentage next to icon")
        }
    }
}
