import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Window
import QtMultimedia
import Qt.labs.platform
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects
import ".."

PlasmoidItem {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    anchors.centerIn: parent
    preferredRepresentation: compactRepresentation
    property string cfg_languages: plasmoid.configuration.languages
    property string toDelete: ""
    property string lefttext: ""
    property string righttext: ""
    property var langlist: []
    property var codelist: []
    property var ttslist: []
    property var detectlist: [i18n("Autodetect")]
    property int sourceIndex: plasmoid.configuration.sourceIndex
    property int destinationIndex: plasmoid.configuration.destinationIndex
    property int popupIndex: -1
    property bool ind: false
    property string swapText: ""
    property int swapIndex: 0
    property string cfg_engine: plasmoid.configuration.engine
    property bool cfg_autodetect: plasmoid.configuration.autodetect
    property bool indlang: false
    property bool pins: false
    property bool pack: true
    property bool actl: false
    property bool actr: false
    property string windowtext
    property string tmpfolder: StandardPaths.writableLocation(
                                   StandardPaths.TempLocation).toString(
                                   ).replace("file://", "")

    hideOnWindowDeactivate: !root.pins

    LangModel {
        id: langModel
    }

    Window {
        id: info
        visible: false
        minimumWidth: Kirigami.Units.gridUnit * 15
        minimumHeight: Kirigami.Units.gridUnit * 15
        title: i18n("Translator")
        flags: Qt.WindowStaysOnTopHint
        color: Kirigami.Theme.backgroundColor
        onClosing: {
            windowtext = ""
            xselclear.connectSource('xsel --clear')
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
                    id: destpopup
                    text: i18n("Destination")
                    Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
                }
                ComboBox3 {
                    editable: true
                    id: destinationpopup
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
                    model: root.langlist
                    currentIndex: getLocale()
                    onCurrentIndexChanged: {
                        root.popupIndex = destinationpopup.currentIndex
                    }
                    onActivated: {
                        falsetime.start()
                    }
                }
                PlasmaComponents.ToolButton {
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    icon.name: "edit-copy"
                    enabled: windowarea.focus
                    QQC2.ToolTip.text: i18n("Copy")
                    QQC2.ToolTip.visible: hovered
                    onClicked: {
                        windowarea.selectAll()
                        windowarea.copy()
                        windowarea.deselect()
                    }
                }
            }
            PlasmaComponents.TextArea {
                id: windowarea
                Layout.fillWidth: true
                focus: true
                Layout.fillHeight: true
                wrapMode: Text.WordWrap
                readOnly: true
                text: root.windowtext
            }
        }

        Component.onCompleted: {
            setX(Screen.width / 2 - width / 2)
            setY(Screen.height / 2 - height / 2)
        }
        QQC2.Action {
            id: close
            shortcut: "Esc"
            onTriggered: {
                info.close()
            }
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function connectCmd(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }
    Plasma5Support.DataSource {
        id: checkpackage
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function connectCmd(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }
    Plasma5Support.DataSource {
        id: listen
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function connectCmd(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    Plasma5Support.DataSource {
        id: xsel
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function connectCmd(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }
    Plasma5Support.DataSource {
        id: xselclear
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function connectCmd(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    // Helper pour accéder au presse-papiers
    TextEdit {
        id: clipboardHelper
        width: 0
        height: 0
        opacity: 0
    }

    Plasma5Support.DataSource {
        id: detect
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var exitCode2 = data["exit code"]
            var exitStatus2 = data["exit status"]
            var stdout2 = data["stdout"]
            var stderr2 = data["stderr"]
            exited(sourceName, exitCode2, exitStatus2, stdout2, stderr2)
            disconnectSource(sourceName)
        }
        function connectCmd(cmd2) {
            if (cmd2) {
                connectSource(cmd2)
            }
        }
        signal exited(string cmd2, int exitCode2, int exitStatus2, string stdout2, string stderr2)
    }
    function checkPackage() {
        checkpackage.connectCmd("trans -V")
    }

    function detectsource() {
        root.detectlist = []
        var formattedText3 = root.lefttext.replace(/"/g,
                                                   '\\\"').replace("`", "\'")
        detect.connectCmd("trans " + formattedText3 + " -identify")
    }

    function translate() {
        root.ind = true
        var formattedText = root.lefttext.replace(/"/g,
                                                  '\\\"').replace("`", "\'")
        var autod = root.cfg_autodetect == true ? "" : root.codelist[root.sourceIndex]
        executable.connectCmd(
                    "trans {" + autod + "=" + root.codelist[root.destinationIndex]
                    + "} " + " " + "\"" + formattedText + "\"" + " -brief "
                    + "-e " + root.cfg_engine + " -no-bidi")
    }

    function listend(text, orig) {
        var formattedText2 = text.replace(/"/g, '\\\"')
        listen.connectCmd("trans " + orig + ":en " + "\"" + formattedText2 + "\""
                    + " -brief -no-translate -download-audio-as trans.mp3 && mv trans.mp3 "
                    + tmpfolder)
    }

    Connections {
        target: listen
        function onExited(cmd, exitCode, exitStatus, stdout, stderr) {
            playSound.source = tmpfolder + "/trans.mp3"
            playSound.play()
        }
    }
    Connections {
        target: executable
        function onExited(cmd, exitCode, exitStatus, stdout, stderr) {
            var formattedText = stdout.trim()
            var errorText = stderr
            root.righttext = formattedText.length
                    > 0 ? formattedText : "Unable to translate.\nError: " + errorText

            root.ind = false
        }
    }
    Connections {
        target: checkpackage
        function onExited(cmd, exitCode, exitStatus, stdout, stderr) {
            var formattedText = stdout.trim()
            var errorText = stderr.trim()
            if (errorText.indexOf("trans") !== -1) {
                root.pack = false
            } else {
                root.pack = true
            }
        }
    }

    Connections {
        target: xsel
        function onExited(cmd, exitCode, exitStatus, stdout, stderr) {
            var formattedText = stdout.trim()
            var errorText = stderr.trim()
            if (formattedText.length > 0 || errorText.length > 0) {
                windowtext = formattedText.length > 0 ? formattedText : errorText
                windowarea.text = windowtext
                info.show()
                windowarea.focus = true
            } else {
                root.expanded = true
            }
        }
    }

    Connections {
        target: detect
        function onExited(cmd2, exitCode2, exitStatus2, stdout2, stderr2) {
            var formattedText4 = stdout2.trim()
            var lang = formattedText4.split("\n")[1].replace("[22m",
                                                             "").replace(
                        "Name                  [1m", "").replace("[22m", "")
            var copy = []
            root.detectlist = []
            copy.push(lang)
            root.detectlist = copy
            root.indlang = true
        }
    }

    Component.onCompleted: {
        loadLangModel()
        root.sourceIndex = plasmoid.configuration.sourceIndex
        root.destinationIndex = plasmoid.configuration.destinationIndex
        checkPackage()
        xselclear.connectSource('xsel --clear')
    }

    Connections {
        target: plasmoid.configuration
        function onLanguagesChanged() {
            loadLangModel()
            root.sourceIndex = 0
            root.destinationIndex = cfg_autodetect ? 0 : 1
        }
    }

    Connections {
        target: Plasmoid
        function onActivated() {
            falsetime.start()
        }
    }
    Timer {
        id: falsetime
        interval: 0
        repeat: false
        onTriggered: {
            var v = root.popupIndex == -1 ? "" : root.codelist[root.popupIndex]
            root.expanded = false
            xsel.connectCmd('xsel -o | trans :' + v + ' -e ' + root.cfg_engine + ' -b  -no-bidi')
        }
    }

    compactRepresentation: MouseArea {
        id: compRoot
        onClicked: root.expanded = !root.expanded
        hoverEnabled: true

        Image {
            id: iconImage
            anchors.fill: parent
            source: Qt.resolvedUrl("../images/icon.svg")
            sourceSize: Qt.size(48, 48)
            visible: false
        }
        ColorOverlay {
            anchors.fill: iconImage
            source: iconImage
            color: Kirigami.Theme.textColor
        }
    }

    fullRepresentation: Item {

        id: fullRoot
        Layout.preferredWidth: Kirigami.Units.gridUnit * 30
        Layout.preferredHeight: Kirigami.Units.gridUnit * 15
        enabled: !root.ind
        Layout.fillHeight: true
        Layout.fillWidth: true

        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded) {
                    checkPackage()
                    time.start()
                }
            }
        }

        Timer {
            id: time
            onTriggered: {

                leftPanel.forceActiveFocus()
            }
            interval: 200
            running: false
            repeat: false
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            height: parent.height
            width: parent.width
            visible: root.langlist.length > 1 && root.pack == true
            GridLayout {
                columns: 3
                width: parent.width
                Layout.maximumWidth: parent.width

                ColumnLayout {

                    Layout.fillWidth: true
                    Layout.maximumWidth: (parent.width - sw.width) / 2 - Kirigami.Units.smallSpacing
                    RowLayout {
                        Layout.fillWidth: true
                        width: parent.width
                        PlasmaComponents.Label {
                            text: i18n("Source")
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
                        }

                        ComboBox3 {
                            id: sourceLang
                            editable: true
                            Layout.fillWidth: true
                            rightPadding: sw.width
                            enabled: !root.cfg_autodetect
                            model: root.cfg_autodetect ? root.detectlist : root.langlist
                            currentIndex: root.cfg_autodetect ? 0 : root.sourceIndex
                            onCurrentIndexChanged: {
                                root.sourceIndex = sourceLang.currentIndex
                                plasmoid.configuration.sourceIndex = root.sourceIndex
                            }
                        }

                        PlasmaComponents.ToolButton {
                            id: clearbutton
                            flat: true
                            icon.name: "edit-clear-all-symbolic"
                            enabled: leftPanel.text.length > 0
                            onClicked: {
                                clear.trigger()
                                root.indlang = false
                            }
                            QQC2.ToolTip.text: i18n("Clear all (Esc)")
                            QQC2.ToolTip.visible: hovered
                        }
                    }
                    PlasmaComponents.TextArea {
                        id: leftPanel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumWidth: parent.width
                        wrapMode: Text.WordWrap
                        text: root.lefttext
                        onTextChanged: {
                            root.lefttext = leftPanel.text
                            if (this.text.length == 0) {
                                var copy = ["Autodetect"]
                                root.detectlist = copy
                                root.indlang = false
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Layout.minimumWidth: parent.width
                        PlasmaComponents.ToolButton {
                            property bool act: root.actl
                            Layout.fillWidth: false
                            id: playsource
                            icon.name: root.ttslist[root.sourceIndex]
                                        == true ? isPlaying()
                                                  && this.act ? "media-playback-stop" : "player-volume" : "audio-volume-muted"
                            enabled: root.ttslist[root.sourceIndex]
                                     == true ? leftPanel.text.length > 0
                                               && leftPanel.text.length < 201 ? true : false : false
                            onClicked: {
                                if (isPlaying() && this.act) {
                                    playSound.stop()
                                } else {
                                    playSound.stop()
                                    root.actl = true
                                    listend(root.lefttext,
                                            root.codelist[root.sourceIndex])
                                }
                            }
                            QQC2.ToolTip.text: i18n("Listen")
                            QQC2.ToolTip.visible: hovered
                        }
                        PlasmaComponents.ToolButton {
                            Layout.fillWidth: false
                            transformOrigin: Item.Left
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            icon.name: "edit-paste"
                            enabled: true
                            onClicked: {
                                clipboardHelper.text = ""
                                clipboardHelper.paste()
                                leftPanel.text = clipboardHelper.text
                                clipboardHelper.text = ""
                            }
                            QQC2.ToolTip.text: i18n("Paste (Ctrl+V)")
                            QQC2.ToolTip.visible: hovered
                        }

                        PlasmaComponents.Label {
                            text: leftPanel.text.length + "/5000"
                            Layout.fillWidth: true
                            enabled: leftPanel.text.length > 0
                            color: leftPanel.text.length
                                   > 5000 ? "red" : Kirigami.Theme.textColor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    id: sw
                    PlasmaComponents.ToolButton {
                        Layout.fillWidth: false
                        icon.name: "document-swap"
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        enabled: !cfg_autodetect
                                 && root.sourceIndex !== root.destinationIndex
                        onClicked: {
                            swap.trigger()
                            playSound.stop()
                        }
                        QQC2.ToolTip.text: i18n("Swap panels (CTRL+S)")
                        QQC2.ToolTip.visible: hovered
                        QQC2.BusyIndicator {
                            id: busyIndicator
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            width: parent.width
                            height: parent.height
                            enabled: true
                            running: root.ind
                            visible: root.ind
                        }
                    }
                }

                ColumnLayout {
                    Layout.maximumWidth: (parent.width - sw.width) / 2 - Kirigami.Units.smallSpacing
                    Layout.fillWidth: true
                    RowLayout {
                        Layout.minimumWidth: parent.width
                        width: parent.width
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            id: des
                            text: i18n("Destination")
                            Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
                        }
                        ComboBox3 {
                            editable: true
                            id: destination
                            Layout.fillWidth: true
                            rightPadding: sw.width
                            Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
                            model: root.langlist
                            currentIndex: model ? root.destinationIndex : -1
                            onCurrentIndexChanged: {
                                root.destinationIndex = destination.currentIndex
                                plasmoid.configuration.destinationIndex = root.destinationIndex
                            }
                            onActivated: {
                                root.lefttext.length > 0 ? translate() : ""
                            }
                        }
                        PlasmaComponents.ToolButton {
                            id: pinbutton
                            visible: Plasmoid.location !== PlasmaCore.Types.Floating
                            flat: true
                            icon.name: "window-pin"
                            checked: root.pins
                            checkable: true
                            onCheckedChanged: checked ? root.pins = true : root.pins = false
                            QQC2.ToolTip.text: i18n("Pin window (CTRL+P)")
                            QQC2.ToolTip.visible: hovered
                        }
                    }
                    PlasmaComponents.TextArea {
                        id: rightPanel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        wrapMode: Text.WordWrap
                        readOnly: true
                        text: root.righttext
                        onTextChanged: {
                            root.righttext = rightPanel.text
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Layout.minimumWidth: parent.width
                        PlasmaComponents.ToolButton {
                            property bool act: root.actr
                            Layout.fillWidth: false
                            id: playdest
                            transformOrigin: Item.Left
                            icon.name: root.ttslist[root.destinationIndex]
                                        == true ? isPlaying()
                                                  && this.act ? "media-playback-stop" : "player-volume" : "audio-volume-muted"
                            enabled: root.ttslist[root.destinationIndex]
                                     == true ? rightPanel.text.length > 0
                                               && rightPanel.text.length
                                               < 201 ? true : false : false
                            onClicked: {
                                if (isPlaying() && this.act) {
                                    playSound.stop()
                                } else {
                                    playSound.stop()
                                    root.actr = true
                                    listend(root.righttext,
                                            root.codelist[root.destinationIndex])
                                }
                            }
                            QQC2.ToolTip.text: i18n("Listen")
                            QQC2.ToolTip.visible: hovered
                        }
                        PlasmaComponents.ToolButton {
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            icon.name: "edit-copy"
                            enabled: rightPanel.text.length > 0
                            onClicked: {
                                rightPanel.selectAll()
                                rightPanel.copy()
                                rightPanel.deselect()
                            }
                            QQC2.ToolTip.text: i18n("Copy (Ctrl+C)")
                            QQC2.ToolTip.visible: hovered
                        }
                        Item {
                            Layout.fillWidth: true
                        }

                        PlasmaComponents.ToolButton {
                            id: transbutton
                            Layout.alignment: Qt.AlignRight
                            flat: true
                            transformOrigin: Item.Right
                            icon.name: "globe"
                            text: i18n("Translate")
                            Layout.fillWidth: false
                            enabled: leftPanel.text.length > 0
                                     && leftPanel.text.length < 5001
                                     && root.sourceIndex !== root.destinationIndex
                                     || root.cfg_autodetect ? true : false
                            onClicked: {
                                trans.trigger()
                            }
                            QQC2.ToolTip.text: i18n("Translate (CTRL+Enter)")
                            QQC2.ToolTip.visible: hovered
                        }
                    }
                }
            }

            QQC2.Action {
                id: trans
                shortcut: "Ctrl+Return"
                onTriggered: {
                    rightPanel.focus = true
                    if (transbutton.enabled === true) {
                        checkPackage()
                        root.righttext = ""
                        root.lefttext = leftPanel.text
                        translate()
                        if (root.cfg_autodetect == true
                                && root.indlang == false) {
                            detectsource()
                        }
                    }
                }
            }

            QQC2.Action {
                id: transalt
                shortcut: "Ctrl+Enter"
                onTriggered: {
                    rightPanel.focus = true
                    if (transbutton.enabled === true) {
                        checkPackage()
                        root.righttext = ""
                        root.lefttext = leftPanel.text
                        translate()
                        if (root.cfg_autodetect == true
                                && root.indlang == false) {
                            detectsource()
                        }
                    }
                }
            }

            QQC2.Action {
                id: clear
                shortcut: "Esc"
                onTriggered: {
                    leftPanel.remove(0, leftPanel.text.length)
                    rightPanel.remove(0, rightPanel.text.length)
                    if (root.cfg_autodetect) {
                        var copy = ["Autodetect"]
                        root.detectlist = copy
                    }
                    leftPanel.focus = true
                }
            }

            QQC2.Action {
                id: swap
                shortcut: "Ctrl+S"
                onTriggered: {
                    root.swapText = root.lefttext
                    root.lefttext = root.righttext
                    root.righttext = root.swapText
                    root.swapIndex = root.sourceIndex
                    root.sourceIndex = root.destinationIndex
                    root.destinationIndex = root.swapIndex
                    leftPanel.focus = true
                }
            }
            QQC2.Action {
                id: copy
                shortcut: "Ctrl+C"
                onTriggered: {
                    rightPanel.selectAll()
                    rightPanel.copy()
                    rightPanel.deselect()
                }
            }
            QQC2.Action {
                id: paste
                shortcut: "Ctrl+V"
                onTriggered: {
                    clipboardHelper.text = ""
                    clipboardHelper.paste()
                    leftPanel.text = clipboardHelper.text
                    clipboardHelper.text = ""
                }
            }
            QQC2.Action {
                id: pinwindow
                shortcut: "Ctrl+P"
                onTriggered: {
                    root.pins = pinbutton.checked ? false : true
                }
            }
        }
        ColumnLayout {
            anchors.centerIn: parent
            visible: root.langlist.length < 2
            PlasmaComponents.Label {
                id: err
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                text: cfg_autodetect ? i18n("Please make sure that at least one language is selected.") : i18n(
                                           "Please make sure that at least two languages are selected.")
                color: "red"
                horizontalAlignment: Text.AlignHCenter
            }
            PlasmaComponents.Button {
                Layout.topMargin: 20
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Settings")
                onClicked: Plasmoid.internalAction("configure").trigger()
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            visible: root.pack == false
            PlasmaComponents.Label {
                id: install
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Please install translate-shell package and reboot or relog.")
                color: "red"
                horizontalAlignment: Text.AlignHCenter
            }
            PlasmaComponents.Button {
                Layout.topMargin: 20
                Layout.alignment: Qt.AlignHCenter
                text: i18n("How to install")
                onClicked: Qt.openUrlExternally(
                               "https://github.com/soimort/translate-shell/wiki/Distros/")
            }
        }
    }

    function loadLangModel() {
        var languages = JSON.parse(cfg_languages)
        var langcopy = []
        var codecopy = []
        var ttscopy = []
        for (var i = 0; i < languages.length; i++) {
            if (languages[i].active && languages[i].enabled) {
                langcopy.push(languages[i].lang)
                codecopy.push(languages[i].code)
                ttscopy.push(languages[i].tts)
            }
        }
        root.langlist = langcopy
        root.codelist = codecopy
        root.ttslist = ttscopy
    }

    function getLocale() {
        var myLocale = Qt.locale().name.split("_")[0]
        var myIndex = root.codelist.indexOf(myLocale)
        return myIndex
    }
    MediaPlayer {
        id: playSound
        audioOutput: AudioOutput { id: audioOutput }
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.StoppedState) {
                root.actl = false
                root.actr = false
                playSound.source = ""
            }
        }
        onErrorOccurred: function(error, errorString) {
            playSound.stop()
            playSound.source = ""
        }
    }
    function isPlaying() {
        return playSound.playbackState == MediaPlayer.PlayingState
    }
}
