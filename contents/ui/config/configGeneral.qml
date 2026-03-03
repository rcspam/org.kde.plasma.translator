import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt.labs.platform
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import ".."

Item {
    id: configGeneral
    Layout.fillWidth: true
    property string cfg_languages: plasmoid.configuration.languages
    property bool cfg_checkall: plasmoid.configuration.checkall
    property string cfg_engine: plasmoid.configuration.engine
    property var enginemodel: ["google", "yandex", "bing", "apertium"]
    property bool cfg_autodetect: plasmoid.configuration.autodetect

    // Properties injected by Plasma config system
    property string cfg_languagesDefault
    property bool cfg_checkallDefault
    property string cfg_engineDefault
    property bool cfg_autodetectDefault
    property int cfg_sourceIndex
    property int cfg_sourceIndexDefault
    property int cfg_destinationIndex
    property int cfg_destinationIndexDefault
    property int cfg_mode
    property int cfg_modeDefault
    property string title: i18n("General")
    // Column widths shared between header and delegates
    property real col0Width: 40
    property real col3Width: 80
    property real colMiddleWidth: 100

    onWidthChanged: recalcColumns()
    function recalcColumns() {
        var avail = width - col0Width - col3Width
        colMiddleWidth = avail > 0 ? avail / 2 : 100
    }

    property string metadataFilepath: Qt.resolvedUrl("../../metadata.json")
    property string localversion: ""
    property string serverversion: ""
    property string serverlink: ""
    property string serverpage: ""
    property string appdata: ""
    property string updatepath: ""
    property string tmpfolder: ""

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function connectCmd(cmd) {
            connectSource(cmd)
        }
        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }

    Plasma5Support.DataSource {
        id: update
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function connectCmd(cmd) {
            connectSource(cmd)
        }
        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }

    Plasma5Support.DataSource {
        id: versionReader
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var stdout = data["stdout"]
            disconnectSource(sourceName)
            try {
                var meta = JSON.parse(stdout)
                localversion = meta.KPlugin.Version || ""
            } catch(e) {
                localversion = ""
            }
        }
        function readVersion() {
            var path = metadataFilepath.toString().replace("file://", "")
            connectSource("cat " + path)
        }
    }

    Connections {
        target: executable
        function onExited(exitCode, exitStatus, stdout, stderr) {
            if (localversion != stdout.replace('\n', ' ').trim()) {
                localversion = stdout.replace('\n', ' ').trim()
            }
        }
    }

    Connections {
        target: update
        function onExited(exitCode, exitStatus, stdout, stderr) {
            if (exitCode == 0) {
                t.state = "success"
                closenotif.start()
                versionReader.readVersion()
            } else {
                t.state = "fail"
            }
        }
    }
    Timer {
        id: closenotif
        running: false
        repeat: false
        interval: 5000
        onTriggered: {
            anim2.start()
        }
    }

    function fetchUpdateInfo() {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var responseText = xhr.responseText
                    var versionMatch = responseText.match(/<version>(.*?)<\/version>/)
                    var downloadMatch = responseText.match(/<downloadlink1>(.*?)<\/downloadlink1>/)
                    var homepageMatch = responseText.match(/<homepage>(.*?)<\/homepage>/)

                    if (versionMatch) serverversion = versionMatch[1]
                    if (downloadMatch) serverlink = downloadMatch[1]
                    if (homepageMatch) serverpage = homepageMatch[1]

                    if (localversion != serverversion && updatepath.startsWith(appdata)) {
                        t.state = 'notif'
                    } else if (localversion != serverversion && !updatepath.startsWith(appdata)) {
                        t.state = "fail"
                    }
                }
            }
        }
        xhr.open("GET", "https://api.kde-look.org/ocs/v1/content/data/1395666")
        xhr.send()
    }

    Component.onCompleted: {
        recalcColumns()
        versionReader.readVersion()
        changeEngine()
        var s = StandardPaths.writableLocation(
                    StandardPaths.AppDataLocation).toString()
        appdata = s.slice(0, s.lastIndexOf("/")).replace("file://", "")
        var metaPath = metadataFilepath.toString().replace("file://", "")
        updatepath = metaPath.substr(0, metaPath.indexOf(plasmoid.pluginName))
        tmpfolder = StandardPaths.writableLocation(
                    StandardPaths.TempLocation).toString().replace("file://",
                                                                   "")
        fetchUpdateInfo()
    }
    Connections {
        target: plasmoid.configuration
        function onEngineChanged() {
            changeEngine()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        Layout.alignment: Qt.AlignTop | Qt.AlignRight
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            SequentialAnimation {
                id: anim
                NumberAnimation {
                    target: t
                    property: "Layout.preferredHeight"
                    duration: Kirigami.Units.longDuration
                    from: 0
                    to: updatetext.paintedHeight + Kirigami.Units.largeSpacing * 1.5
                    loops: 1
                }
                NumberAnimation {
                    target: t
                    property: "opacity"
                    duration: Kirigami.Units.longDuration * 2
                    from: 0
                    to: 1
                    loops: 1
                }
            }
            SequentialAnimation {
                id: anim2
                NumberAnimation {
                    target: t
                    property: "opacity"
                    duration: Kirigami.Units.longDuration * 2
                    from: 1
                    to: 0
                    loops: 1
                }
                NumberAnimation {
                    target: t
                    property: "Layout.preferredHeight"
                    duration: Kirigami.Units.longDuration
                    from: updatetext.paintedHeight + Kirigami.Units.largeSpacing * 1.5
                    to: 0
                    loops: 1
                }
            }
            Rectangle {
                id: t
                visible: false
                opacity: 0
                Layout.fillWidth: true
                Layout.preferredHeight: updatetext.paintedHeight + Kirigami.Units.largeSpacing * 1.5
                color: "transparent"
                radius: Kirigami.Units.smallSpacing / 2
                onStateChanged: {
                    if (state == "notif") {
                        anim.start()
                    }
                }
                states: [
                    State {
                        name: "notif"
                        PropertyChanges {
                            target: t
                            border.color: Kirigami.Theme.highlightColor
                            visible: true
                        }
                        PropertyChanges {
                            target: fill
                            color: Kirigami.Theme.highlightColor
                        }
                        PropertyChanges {
                            target: ico
                            source: "update-none"
                        }
                        PropertyChanges {
                            target: updatetext
                            text: i18n("Update is available") + ' (' + serverversion + ').'
                        }
                        PropertyChanges {
                            target: upd
                            visible: true
                        }
                        PropertyChanges {
                            target: cng
                            visible: true
                        }
                    },
                    State {
                        name: "success"
                        PropertyChanges {
                            target: t
                            border.color: Kirigami.Theme.positiveTextColor
                            visible: true
                        }
                        PropertyChanges {
                            target: fill
                            color: Kirigami.Theme.positiveTextColor
                        }
                        PropertyChanges {
                            target: ico
                            source: "checkbox"
                        }
                        PropertyChanges {
                            target: updatetext
                            text: i18n("Update finished. Please restart the session.")
                            anchors.right: parent.right
                        }
                        PropertyChanges {
                            target: busy
                            visible: false
                            running: false
                        }
                    },
                    State {
                        name: "fail"
                        PropertyChanges {
                            target: t
                            border.color: Kirigami.Theme.negativeTextColor
                            visible: true
                        }
                        PropertyChanges {
                            target: fill
                            color: Kirigami.Theme.negativeTextColor
                        }
                        PropertyChanges {
                            target: ico
                            source: "dialog-close"
                        }
                        PropertyChanges {
                            target: updatetext
                            text: i18n("Update failed. Make sure that the widget is install in user's home directory.")
                            anchors.right: parent.right
                        }
                        PropertyChanges {
                            target: busy
                            visible: false
                            running: false
                        }
                    }
                ]

                Rectangle {
                    id: fill
                    anchors.fill: parent
                    opacity: 0.2
                    radius: Kirigami.Units.smallSpacing / 2 * 0.6
                }

                Kirigami.Icon {
                    id: ico
                    source: ""
                    height: parent.height
                    anchors.left: parent.left
                    anchors.leftMargin: Kirigami.Units.smallSpacing
                }

                QQC2.Label {
                    id: updatetext
                    opacity: 1
                    Layout.fillHeight: true
                    anchors.left: ico.right
                    anchors.leftMargin: Kirigami.Units.smallSpacing
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: t.width - ico.width - upd.width - cng.width - Kirigami.Units.largeSpacing
                    text: ""
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }
                QQC2.BusyIndicator {
                    id: busy
                    visible: false
                    running: true
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height / 2
                    anchors.right: upd.left
                }

                QQC2.Button {
                    visible: false
                    id: upd
                    text: i18n("Update")
                    icon.name: "update-none"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: cng.left
                    anchors.rightMargin: Kirigami.Units.smallSpacing / 2
                    onClicked: {
                        applyUpdate()
                        this.enabled = false
                    }
                }
                QQC2.Button {
                    id: cng
                    visible: false
                    text: i18n("Changelog")
                    icon.name: "globe"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    onClicked: {
                        Qt.openUrlExternally(
                                    "https://store.kde.org/p/1395666#updates-panel")
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            width: parent.width
            QQC2.Label {
                text: i18n("Translate engine:")
            }
            QQC2.ComboBox {
                Layout.fillWidth: false
                implicitWidth: 90
                id: engine
                model: configGeneral.enginemodel
                currentIndex: engine.model.indexOf(
                                  plasmoid.configuration.engine)
                onActivated: {
                    configGeneral.cfg_engine = model[index]
                    plasmoid.configuration.engine = model[index]
                }
            }
            Item {
                Layout.fillWidth: true
            }

            QQC2.CheckBox {
                id: autosource
                Layout.alignment: Qt.AlignRight
                text: i18n("Autodetect source")
                checked: cfg_autodetect
                onClicked: {
                    cfg_autodetect = checked
                }
            }
        }

        QQC2.Label {
            id: notif
            text: cfg_autodetect ? i18n("Please make sure that at least one language is selected.") : i18n(
                                       "Please make sure that at least two languages are selected.")
        }
        QQC2.TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: i18n("Filter...")
            Kirigami.Icon {
                source: "edit-clear"
                visible: searchField.text.length > 0
                height: parent.height
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.smallSpacing
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        searchField.text = ""
                    }
                }
            }
        }

        // Fixed header row
        Row {
            id: headerRow
            Layout.fillWidth: true
            height: headerLabel0.implicitHeight + Kirigami.Units.smallSpacing * 2

            Item {
                width: configGeneral.col0Width
                height: parent.height
                QQC2.Label {
                    id: headerLabel0
                    anchors.centerIn: parent
                    font.bold: true
                    text: "👁"
                }
            }
            Item {
                width: configGeneral.colMiddleWidth
                height: parent.height
                QQC2.Label {
                    anchors.centerIn: parent
                    font.bold: true
                    text: i18n("Name")
                }
            }
            Item {
                width: configGeneral.colMiddleWidth
                height: parent.height
                QQC2.Label {
                    anchors.centerIn: parent
                    font.bold: true
                    text: i18n("Native Name")
                }
            }
            Item {
                width: configGeneral.col3Width
                height: parent.height
                QQC2.Label {
                    anchors.centerIn: parent
                    font.bold: true
                    text: i18n("Code")
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        ListView {
            id: langTable
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true

            property int currentSelectedIndex: -1

            model: ListModel {
                id: filteredModel
            }

            delegate: Rectangle {
                width: langTable.width
                height: delegateContent.implicitHeight + Kirigami.Units.smallSpacing
                color: index === langTable.currentSelectedIndex ? Kirigami.Theme.highlightColor : (index % 2 === 0 ? "transparent" : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03))

                Row {
                    id: delegateContent
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width

                    Item {
                        width: configGeneral.col0Width
                        height: check.visible ? check.height : errorIcon.height
                        QQC2.CheckBox {
                            id: check
                            anchors.centerIn: parent
                            visible: model.enabled
                            checked: model.active
                            onClicked: {
                                model.active = checked
                                var srcIndex = model.sourceIndex
                                langModel.set(srcIndex, { "active": checked })
                                if (!checked) {
                                    configGeneral.cfg_checkall = false
                                }
                                cfg_languages = JSON.stringify(getLanguagesArray())
                                getLangNumbers()
                            }
                        }
                        Kirigami.Icon {
                            id: errorIcon
                            source: "error"
                            visible: !check.visible
                            width: 16
                            height: 16
                            anchors.centerIn: parent
                        }
                    }

                    Item {
                        width: configGeneral.colMiddleWidth
                        height: nameLabel.implicitHeight
                        QQC2.Label {
                            id: nameLabel
                            anchors.centerIn: parent
                            width: parent.width
                            text: model.lang
                            enabled: model.enabled
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        width: configGeneral.colMiddleWidth
                        height: nativeLabel.implicitHeight
                        QQC2.Label {
                            id: nativeLabel
                            anchors.centerIn: parent
                            width: parent.width
                            text: model.nativelang
                            enabled: model.enabled
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        width: configGeneral.col3Width
                        height: codeLabel.implicitHeight
                        QQC2.Label {
                            id: codeLabel
                            anchors.centerIn: parent
                            width: parent.width
                            text: model.code
                            enabled: model.enabled
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: {
                        langTable.currentSelectedIndex = index
                        moveUp.enabled = true
                        moveDown.enabled = true
                    }
                }
            }
        }

        RowLayout {
            id: buttonsRow
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.fillWidth: true

            QQC2.CheckBox {
                id: checkAll
                text: this.checked ? i18n("Uncheck all") : i18n("Check all")
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignLeft

                checked: configGeneral.cfg_checkall
                onClicked: {
                    var i
                    if (this.checked === false) {
                        for (i = 0; i < langModel.count; ++i) {
                            langModel.set(i, {
                                              "active": false
                                          })
                        }
                    } else {
                        for (i = 0; i < langModel.count; ++i) {
                            langModel.set(i, {
                                              "active": true
                                          })
                        }
                    }
                    cfg_languages = JSON.stringify(getLanguagesArray())
                    langModel.clear()
                    var languages = JSON.parse(cfg_languages)
                    for (i = 0; i < languages.length; i++) {
                        langModel.append(languages[i])
                        getLangNumbers()
                    }
                    applyFilter()
                }
            }
            Item {
                Layout.fillWidth: true
            }
            QQC2.Button {
                id: moveUp
                text: i18n("Move up")
                icon.name: "go-up"
                enabled: false
                Layout.fillWidth: false
                onClicked: {
                    var idx = langTable.currentSelectedIndex
                    if (idx <= 0) {
                        return
                    }
                    // Get source indices
                    var srcIdx = filteredModel.get(idx).sourceIndex
                    var srcIdxPrev = filteredModel.get(idx - 1).sourceIndex
                    // Swap in langModel
                    langModel.move(srcIdx, srcIdxPrev, 1)
                    cfg_languages = JSON.stringify(getLanguagesArray())
                    applyFilter()
                    langTable.currentSelectedIndex = idx - 1
                }
            }

            QQC2.Button {
                id: moveDown
                text: i18n("Move down")
                icon.name: "go-down"
                Layout.fillWidth: false
                enabled: false
                onClicked: {
                    var idx = langTable.currentSelectedIndex
                    if (idx < 0 || idx >= filteredModel.count - 1) {
                        return
                    }
                    // Get source indices
                    var srcIdx = filteredModel.get(idx).sourceIndex
                    var srcIdxNext = filteredModel.get(idx + 1).sourceIndex
                    // Swap in langModel
                    langModel.move(srcIdx, srcIdxNext, 1)
                    cfg_languages = JSON.stringify(getLanguagesArray())
                    applyFilter()
                    langTable.currentSelectedIndex = idx + 1
                }
            }
        }
    }

    LangModel {
        id: langModel
    }

    Connections {
        target: searchField
        function onTextChanged() {
            applyFilter()
        }
    }

    function applyFilter() {
        filteredModel.clear()
        var filterText = searchField ? searchField.text.toLowerCase() : ""
        for (var i = 0; i < langModel.count; i++) {
            var item = langModel.get(i)
            var com = (item.lang + item.nativelang + item.code).toLowerCase()
            if (filterText.length === 0 || com.indexOf(filterText) !== -1) {
                filteredModel.append({
                    "lang": item.lang,
                    "code": item.code,
                    "nativelang": item.nativelang,
                    "active": item.active,
                    "google": item.google,
                    "yandex": item.yandex,
                    "bing": item.bing,
                    "apertium": item.apertium,
                    "enabled": item.enabled,
                    "tts": item.tts,
                    "sourceIndex": i
                })
            }
        }
    }

    function getLanguagesArray() {
        var langArray = []
        for (var i = 0; i < langModel.count; i++) {
            langArray.push(langModel.get(i))
        }
        return langArray
    }
    function getLangNumbers() {
        var j = 0
        for (var i = 0; i < langModel.count; i++) {
            if (langModel.get(i).active === true) {
                j = j + 1
            }
        }
        if (j > 1) {
            notif.color = Kirigami.Theme.textColor
        } else {
            notif.color = "red"
        }
    }
    function changeEngine() {
        langModel.clear()
        var eng = configGeneral.cfg_engine
        if (!cfg_languages || cfg_languages.length === 0) {
            return
        }
        var languages
        try {
            languages = JSON.parse(cfg_languages)
        } catch(e) {
            return
        }
        for (var i = 0; i < languages.length; i++) {
            langModel.append(languages[i])
            langModel.set(i, {
                              "enabled": true
                          })
            langModel.set(i, {
                              "com": languages[i].lang + languages[i].nativelang + languages[i].code
                          })
        }
        for (var j = 0; j < languages.length; j++) {
            if (langModel.get(j)[eng] === false) {
                langModel.set(j, {
                                  "enabled": false,
                                  "active": false
                              })
            }
        }
        applyFilter()
    }
    function applyUpdate() {
        updatetext.text = i18n("Updating...")
        busy.visible = true
        update.connectCmd("wget -O " + tmpfolder + "/" + plasmoid.pluginName
                    + ".tar.gz " + serverlink + " && tar -C " + updatepath
                    + "/ -xvzf " + tmpfolder + "/" + plasmoid.pluginName
                    + ".tar.gz && rm " + tmpfolder + "/" + plasmoid.pluginName + ".tar.gz")
    }
}
