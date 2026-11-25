import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Window
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// One translation result. Closed windows stay alive so a late answer can see
// that its request was cancelled, and so the next shortcut can show them again.
Window {
    id: selectionWindow

    // The widget: language lists, and clearSelection() when this window closes
    property var host: null
    // Cascade step, applied once so a reused window keeps the user's position
    property int slot: 0
    // Id of the translation this window is waiting on. 0 means it is not
    // waiting: the window was closed or the result was empty. lastRequestId
    // only grows, so a recycled window never reuses an id a late answer holds.
    property int requestId: 0
    property int lastRequestId: 0
    property bool busy: false
    property string resultText: ""
    readonly property var languageNames: host ? host.langlist : []
    readonly property var languageCodes: host ? host.codelist : []

    visible: false
    width: 430
    height: 330
    minimumWidth: Kirigami.Units.gridUnit * 15
    minimumHeight: Kirigami.Units.gridUnit * 15
    title: i18n("Translator")
    flags: Qt.WindowStaysOnTopHint
    color: Kirigami.Theme.backgroundColor

    function begin() {
        lastRequestId += 1
        requestId = lastRequestId
        busy = true
        resultText = ""
        present()
        return requestId
    }

    // Error text, or any message that is not a translation in flight
    function showMessage(text) {
        requestId = 0
        busy = false
        resultText = text
        present()
    }

    function showResult(text, targetCode) {
        busy = false
        var idx = languageCodes.indexOf(targetCode)
        if (idx !== -1)
            destinationBox.currentIndex = idx
        resultText = text
        present()
    }

    // show() does nothing while this window is already mapped, which is why a
    // shortcut looked ignored when the previous translation stayed open behind
    // another window. Remap it unless it is already the active window.
    function present() {
        if (visibility === Window.Minimized || !visible) {
            showNormal()
        } else if (!active) {
            hide()
            show()
        }
        raise()
        requestActivate()
        windowArea.forceActiveFocus()
    }

    onClosing: {
        requestId = 0
        busy = false
        resultText = ""
        if (host)
            host.clearSelection()
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        width: parent.width
        height: parent.height
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.bottom: parent.bottom
        RowLayout {
            Layout.minimumWidth: parent.width
            width: parent.width
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: i18n("Destination")
                Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
            }
            ComboBox3 {
                id: destinationBox
                editable: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
                model: selectionWindow.languageNames
                // Only a choice made here is kept for the next texts: the
                // index also changes to show the language a text went to
                currentIndex: {
                    if (!selectionWindow.host)
                        return -1
                    return selectionWindow.languageCodes.indexOf(selectionWindow.host.nativeCode())
                }
                onActivated: function(index) {
                    if (!selectionWindow.host)
                        return
                    selectionWindow.host.popupIndex = index
                    selectionWindow.host.requestSelection(selectionWindow)
                }
            }
            PlasmaComponents.ToolButton {
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                icon.name: "edit-copy"
                enabled: windowArea.focus
                QQC2.ToolTip.text: i18n("Copy")
                QQC2.ToolTip.visible: hovered
                onClicked: {
                    windowArea.selectAll()
                    windowArea.copy()
                    windowArea.deselect()
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            PlasmaComponents.ScrollView {
                anchors.fill: parent
                // Text wraps, so only vertical scrolling is needed
                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                PlasmaComponents.TextArea {
                    id: windowArea
                    focus: true
                    wrapMode: Text.Wrap
                    readOnly: true
                    text: selectionWindow.resultText
                }
            }
            QQC2.BusyIndicator {
                anchors.centerIn: parent
                running: selectionWindow.busy
                visible: running
            }
        }
    }

    Component.onCompleted: {
        var margin = Kirigami.Units.gridUnit
        var step = slot % 6
        setX(Math.max(0, Screen.width / 2 - width / 2 + step * margin))
        setY(Math.max(0, Screen.height / 2 - height / 2 + step * margin))
    }

    QQC2.Action {
        shortcut: "Esc"
        onTriggered: selectionWindow.close()
    }
}
