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
import "servers/servers.js" as Servers
import "shell.js" as Shell
import "lang.js" as Lang

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
    // True when the engine is a user-defined server instead of translate-shell
    readonly property bool usesServer: Servers.isServerEngine(cfg_engine)
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

    ServerClient {
        id: serverClient
    }

    Window {
        id: info
        visible: false
        width: 430
        height: 330
        minimumWidth: Kirigami.Units.gridUnit * 15
        minimumHeight: Kirigami.Units.gridUnit * 15
        title: i18n("Translator")
        flags: Qt.WindowStaysOnTopHint
        color: Kirigami.Theme.backgroundColor
        onClosing: {
            windowtext = ""
            root.selectionBusy = false
            root.selectionRequest++ // drops the translation still running
            root.clearSelection()
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
                    currentIndex: root.codelist.indexOf(nativeCode())
                    // Only a choice made here is kept for the next texts: the
                    // index also changes to show the language a text went to
                    onActivated: function(index) {
                        root.popupIndex = index
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
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                PlasmaComponents.ScrollView {
                    anchors.fill: parent
                    // Text wraps, so only vertical scrolling is needed
                    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                    PlasmaComponents.TextArea {
                        id: windowarea
                        focus: true
                        wrapMode: Text.Wrap
                        readOnly: true
                        text: root.windowtext
                    }
                }
                QQC2.BusyIndicator {
                    anchors.centerIn: parent
                    running: root.selectionBusy
                    visible: running
                }
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

    // Runs a shell command, then calls done(stdout, stderr, exitCode)
    Plasma5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        onNewData: function(sourceName, data) {
            var done = callbacks[sourceName]
            delete callbacks[sourceName]
            disconnectSource(sourceName)
            if (done) {
                done(data["stdout"], data["stderr"], data["exit code"])
            }
        }
        function run(cmd, done) {
            callbacks[cmd] = done
            connectSource(cmd)
        }
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
        // "--" keeps a text starting with "-" from being read as an option
        detect.connectCmd("trans -identify -- " + Shell.quote(root.lefttext))
    }

    function langName(code) {
        var languages = JSON.parse(cfg_languages)
        for (var i = 0; i < languages.length; i++) {
            if (languages[i].code === code) {
                return languages[i].lang
            }
        }
        return ""
    }

    // done(result, server) with result = { text, detected } or { error, detail }
    function translateWithServer(text, source, target, done) {
        var server = Servers.findServer(Servers.parseList(plasmoid.configuration.servers),
                                        plasmoid.configuration.engine)
        if (!server) {
            done({ error: "noserver" }, null)
            return
        }
        serverClient.translate(server, {
            text: text,
            source: source,
            target: target,
            sourceName: langName(source),
            targetName: langName(target)
        }, function(result) {
            done(result, server)
        })
    }

    function serverFailure(result, server) {
        return i18n("Unable to translate.") + "\n" + serverClient.errorText(result, server)
    }

    function translate() {
        root.ind = true
        if (root.usesServer) {
            var source = root.cfg_autodetect ? "auto" : root.codelist[root.sourceIndex]
            translateWithServer(root.lefttext, source, root.codelist[root.destinationIndex],
                                function(result, server) {
                if (result.error) {
                    root.righttext = serverFailure(result, server)
                } else {
                    root.righttext = result.text
                    if (root.cfg_autodetect && result.detected) {
                        root.detectlist = [langName(result.detected) || result.detected]
                        root.indlang = true
                    }
                }
                root.ind = false
            })
            return
        }
        var autod = root.cfg_autodetect == true ? "" : root.codelist[root.sourceIndex]
        executable.connectCmd(
                    "trans {" + autod + "=" + root.codelist[root.destinationIndex]
                    + "} -brief -e " + root.cfg_engine + " -no-bidi -- "
                    + Shell.quote(root.lefttext))
    }

    function listend(text, orig) {
        listen.connectCmd("trans " + orig + ":en -brief -no-translate -download-audio-as trans.mp3 -- "
                    + Shell.quote(text) + " && mv trans.mp3 " + Shell.quote(tmpfolder))
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

    // The primary selection is read with wl-clipboard on Wayland, xsel on X11
    readonly property bool wayland: Qt.platform.pluginName === "wayland"
    readonly property string selectionPackage: wayland ? "wl-clipboard" : "xsel"
    // wl-paste reports an empty selection on stderr, which must not be shown
    readonly property string selectionCmd: wayland ? "wl-paste --primary --no-newline 2>/dev/null"
                                                   : "xsel -o"
    readonly property string clearSelectionCmd: wayland ? "wl-copy --primary --clear" : "xsel --clear"
    // Updated each time the selection is cleared (startup, selection window closed)
    property bool selectionToolFound: true
    // A selected text is being translated: the window is open, empty, with a spinner
    property bool selectionBusy: false
    // Only the answer to the latest request is shown
    property int selectionRequest: 0

    function clearSelection() {
        runner.run(root.clearSelectionCmd, function(stdout, stderr, exitCode) {
            // 127: the shell did not find the command
            root.selectionToolFound = exitCode !== 127
        })
    }

    function showSelectionWindow(text) {
        windowtext = text
        windowarea.text = windowtext
        info.show()
        windowarea.focus = true
    }

    // Translates a selected text into the popup's language (the native one
    // by default). A text that comes back nearly unchanged was already in that
    // language: it goes to Lang.otherTarget instead.
    function translateSelection(text) {
        if (text.length === 0) {
            root.expanded = true
            return
        }
        var nativeLang = nativeCode()
        var popup = root.popupIndex == -1 ? nativeLang : root.codelist[root.popupIndex]
        var favorite = root.codelist[root.destinationIndex] || popup
        // LLMs take a few seconds: open the window at once
        var request = ++root.selectionRequest
        showSelectionWindow("")
        root.selectionBusy = true
        translateTo(text, popup, function(output, ok) {
            var other = Lang.otherTarget(popup, favorite, nativeLang)
            if (ok && other !== popup && Lang.unchanged(text, output)) {
                translateTo(text, other, function(output2) {
                    showTranslation(output2, other, request)
                })
            } else {
                showTranslation(output, popup, request)
            }
        })
    }

    function showTranslation(output, target, request) {
        if (request !== root.selectionRequest) {
            return // window closed or another language chosen meanwhile
        }
        root.selectionBusy = false
        if (output.length === 0) {
            info.hide()
            root.expanded = true
            return
        }
        destinationpopup.currentIndex = root.codelist.indexOf(target)
        showSelectionWindow(output)
    }

    // Same call for every engine: done(output, ok), output being the
    // translation, or the error to show when ok is false
    function translateTo(text, target, done) {
        if (root.usesServer) {
            translateWithServer(text, "auto", target, function(result, server) {
                done(result.error ? serverFailure(result, server) : result.text, !result.error)
            })
            return
        }
        runner.run("trans :" + target + " -brief -e " + root.cfg_engine + " -no-bidi -- "
                   + Shell.quote(text), function(stdout, stderr) {
            var output = stdout.trim()
            done(output || stderr.trim(), output.length > 0)
        })
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
        clearSelection()
    }

    Connections {
        target: plasmoid.configuration
        function onLanguagesChanged() {
            loadLangModel()
            root.sourceIndex = 0
            root.destinationIndex = cfg_autodetect ? 0 : 1
        }
        function onEngineChanged() {
            reloadKeepingSelection()
        }
        function onServersChanged() {
            reloadKeepingSelection()
        }
    }

    // The language list depends on the engine: keep the chosen languages
    // when they are still offered.
    function reloadKeepingSelection() {
        var source = root.codelist[root.sourceIndex]
        var destination = root.codelist[root.destinationIndex]
        loadLangModel()
        var s = root.codelist.indexOf(source)
        var d = root.codelist.indexOf(destination)
        root.sourceIndex = s !== -1 ? s : 0
        root.destinationIndex = d !== -1 ? d : Math.min(1, root.codelist.length - 1)
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
            root.expanded = false
            if (!root.selectionToolFound) {
                showSelectionWindow(i18n("Reading the selected text needs %1, which is not installed.",
                                         root.selectionPackage))
                return
            }
            runner.run(root.selectionCmd, function(stdout) {
                translateSelection(stdout.trim())
            })
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
            visible: root.langlist.length > 1 && (root.pack || root.usesServer)
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
                    PlasmaComponents.ScrollView {
                        // Text wraps, so only vertical scrolling is needed
                        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumWidth: parent.width
                        PlasmaComponents.TextArea {
                            id: leftPanel
                            wrapMode: Text.Wrap
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
                    PlasmaComponents.ScrollView {
                        // Text wraps, so only vertical scrolling is needed
                        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        PlasmaComponents.TextArea {
                            id: rightPanel
                            wrapMode: Text.Wrap
                            readOnly: true
                            text: root.righttext
                            onTextChanged: {
                                root.righttext = rightPanel.text
                            }
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
                        // Servers report the detected language with the translation
                        if (root.cfg_autodetect == true
                                && root.indlang == false && !root.usesServer) {
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
                        // Servers report the detected language with the translation
                        if (root.cfg_autodetect == true
                                && root.indlang == false && !root.usesServer) {
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
            visible: !root.pack && !root.usesServer
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
        // Read the configuration directly: this runs from its change
        // handlers, possibly before the cfg_* bindings are updated.
        var engine = plasmoid.configuration.engine
        var server = Servers.findServer(Servers.parseList(plasmoid.configuration.servers), engine)
        var serverCodes = server ? Servers.enabledCodes(server) : null
        var langcopy = []
        var codecopy = []
        var ttscopy = []
        for (var i = 0; i < languages.length; i++) {
            var supported = Servers.isServerEngine(engine)
                    ? serverCodes === null || serverCodes.indexOf(languages[i].code) !== -1
                    : languages[i][engine] !== false
            if (languages[i].active && supported) {
                langcopy.push(languages[i].lang)
                codecopy.push(languages[i].code)
                ttscopy.push(languages[i].tts)
            }
        }
        root.langlist = langcopy
        root.codelist = codecopy
        root.ttslist = ttscopy
    }

    function nativeCode() {
        return Lang.nativeCode(plasmoid.configuration.nativeLanguage, Qt.locale().name, root.codelist)
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
