import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."
import "../servers/servers.js" as Servers
import "../servers/openai.js" as OpenAI

Item {
    id: page

    property string cfg_servers: plasmoid.configuration.servers
    // Reset to a built-in engine when its server is removed
    property string cfg_engine: plasmoid.configuration.engine
    property string cfg_languages: plasmoid.configuration.languages

    // Properties injected by Plasma config system
    property string cfg_serversDefault
    property string cfg_engineDefault
    property string cfg_languagesDefault
    property bool cfg_checkall
    property bool cfg_checkallDefault
    property bool cfg_autodetect
    property bool cfg_autodetectDefault
    property int cfg_sourceIndex
    property int cfg_sourceIndexDefault
    property int cfg_destinationIndex
    property int cfg_destinationIndexDefault
    property int cfg_mode
    property int cfg_modeDefault
    property string title: i18n("Servers")

    // Edited in place; cfg_servers holds its JSON for saving. Form fields are
    // filled imperatively so that typing never gets overwritten by a binding.
    property var servers: []
    property int currentIndex: -1
    property string currentType: ""
    property string currentMethod: "POST"
    property bool loading: false
    property bool testing: false
    property string status: ""
    property bool statusOk: true
    property string languageInfo: ""
    property var models: []

    ServerClient {
        id: client
    }

    component FieldLabel: QQC2.Label {
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }

    ListModel {
        id: serverModel
    }

    Component.onCompleted: {
        servers = Servers.parseList(cfg_servers)
        servers.forEach(function(s) {
            serverModel.append({ name: s.name, type: s.type, url: s.url })
        })
        select(servers.length > 0 ? 0 : -1)
    }

    function typeLabel(type) {
        switch (type) {
        case "libretranslate":
            return "LibreTranslate"
        case "deepl":
            return "DeepL"
        case "deeplx":
            return "DeepLX"
        case "openai":
            return i18n("LLM (OpenAI-compatible: Ollama, LM Studio…)")
        case "custom":
            return i18n("Custom")
        }
        return type
    }

    function langName(code) {
        var languages = JSON.parse(cfg_languages)
        for (var i = 0; i < languages.length; i++) {
            if (languages[i].code === code) {
                return languages[i].lang
            }
        }
        return code
    }

    function current() {
        return currentIndex >= 0 && currentIndex < servers.length ? servers[currentIndex] : null
    }

    function currentCopy() {
        return JSON.parse(JSON.stringify(current()))
    }

    function indexOfId(id) {
        for (var i = 0; i < servers.length; i++) {
            if (servers[i].id === id) {
                return i
            }
        }
        return -1
    }

    function commit() {
        cfg_servers = JSON.stringify(servers)
    }

    function select(index) {
        currentIndex = index
        status = ""
        models = []
        loadForm()
        refreshFromServer()
    }

    function loadForm() {
        var s = current()
        loading = true
        currentType = s ? s.type : ""
        currentMethod = s && s.method === "GET" ? "GET" : "POST"
        if (s) {
            nameField.text = s.name || ""
            typeBox.currentIndex = Servers.types.indexOf(s.type)
            urlField.text = s.url || ""
            keyField.text = s.apiKey || ""
            modelField.text = s.model || ""
            promptArea.text = s.prompt || OpenAI.defaultPrompt
            methodBox.currentIndex = currentMethod === "GET" ? 1 : 0
            headersArea.text = s.headers || ""
            bodyArea.text = s.body || ""
            resultField.text = s.resultPath || ""
        }
        loading = false
        updateLanguageInfo()
    }

    function setField(key, value) {
        var s = current()
        // Text areas report their text late, once the form is filled: a
        // missing field and an empty one must compare equal.
        var old = s && s[key] !== undefined ? s[key] : ""
        if (loading || !s || old === value) {
            return
        }
        s[key] = value
        if (key === "name" || key === "url") {
            serverModel.setProperty(currentIndex, key, value)
        }
        commit()
    }

    function changeType(type) {
        var s = current()
        if (loading || !s || s.type === type) {
            return
        }
        var changed = Servers.changeType(s, type)
        servers[currentIndex] = changed
        serverModel.set(currentIndex, { name: changed.name, type: changed.type, url: changed.url })
        commit()
        select(currentIndex)
    }

    function addServer() {
        var id = Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36)
        var s = Servers.newServer("libretranslate", id)
        servers.push(s)
        serverModel.append({ name: s.name, type: s.type, url: s.url })
        commit()
        select(servers.length - 1)
    }

    function removeServer() {
        if (currentIndex < 0) {
            return
        }
        var removed = servers.splice(currentIndex, 1)[0]
        serverModel.remove(currentIndex)
        if (cfg_engine === Servers.engineOf(removed)) {
            cfg_engine = "google"
        }
        commit()
        select(Math.min(currentIndex, servers.length - 1))
    }

    function storeLanguages(id, codes) {
        var i = indexOfId(id)
        if (i < 0) {
            return
        }
        servers[i].languages = codes
        commit()
        if (i === currentIndex) {
            updateLanguageInfo()
        }
    }

    // Silently reloads what the server can tell: its languages and models.
    function refreshFromServer() {
        var s = current()
        if (!s) {
            return
        }
        var server = currentCopy()
        client.fetchLanguages(server, function(result) {
            if (result.codes) {
                storeLanguages(server.id, result.codes)
            }
        })
        client.fetchModels(server, function(result) {
            var s = current()
            if (s && s.id === server.id) {
                page.models = result.models || []
            }
        })
    }

    function updateLanguageInfo() {
        var s = current()
        if (!s) {
            languageInfo = ""
            return
        }
        var codes = Servers.enabledCodes(s)
        if (codes === null) {
            languageInfo = Servers.adapter(s.type).allLanguages
                    ? i18n("All languages")
                    : i18n("Unknown until the server answers. Press Test.")
            return
        }
        var known = JSON.parse(cfg_languages).map(function(l) { return l.code })
        var count = codes.filter(function(c) { return known.indexOf(c) !== -1 }).length
        languageInfo = i18np("%1 language", "%1 languages", count)
    }

    function runTest() {
        var s = current()
        if (!s) {
            return
        }
        var server = currentCopy()
        testing = true
        status = ""
        var target = Qt.locale().name.split("_")[0]
        if (target === "en") {
            target = "fr"
        }
        client.fetchLanguages(server, function(langs) {
            if (langs.codes) {
                storeLanguages(server.id, langs.codes)
                server.languages = langs.codes
            }
            client.translate(server, {
                text: "Hello world",
                source: "en",
                target: target,
                sourceName: "English",
                targetName: langName(target)
            }, function(res) {
                testing = false
                var s = current()
                if (!s || s.id !== server.id) {
                    return
                }
                statusOk = !res.error
                status = res.error ? client.errorText(res, server) : i18n("It works: %1", res.text)
            })
        })
    }

    QQC2.ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: i18n("Translation servers added here appear as engines in the General tab.")
            }

            QQC2.Frame {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 7
                padding: 1

                ListView {
                    id: serverList
                    anchors.fill: parent
                    clip: true
                    model: serverModel

                    delegate: QQC2.ItemDelegate {
                        width: ListView.view.width
                        highlighted: index === page.currentIndex
                        onClicked: page.select(index)

                        contentItem: ColumnLayout {
                            spacing: 0
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: model.name || page.typeLabel(model.type)
                                elide: Text.ElideRight
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: page.typeLabel(model.type) + "   " + model.url
                                font: Kirigami.Theme.smallFont
                                opacity: 0.7
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - Kirigami.Units.gridUnit * 2
                        visible: serverList.count === 0
                        text: i18n("No server yet")
                    }
                }
            }

            RowLayout {
                QQC2.Button {
                    text: i18n("Add")
                    icon.name: "list-add"
                    onClicked: page.addServer()
                }
                QQC2.Button {
                    text: i18n("Remove")
                    icon.name: "list-remove"
                    enabled: page.currentIndex >= 0
                    onClicked: page.removeServer()
                }
                Item {
                    Layout.fillWidth: true
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                visible: page.currentIndex >= 0
            }

            // A plain grid rather than Kirigami.FormLayout: FormLayout caps
            // its width and centers it, so the fields would not follow the
            // window, and a wide text area made it overflow on the right.
            GridLayout {
                Layout.fillWidth: true
                visible: page.currentIndex >= 0
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                FieldLabel {
                    text: i18n("Name:")
                }
                QQC2.TextField {
                    id: nameField
                    Layout.fillWidth: true
                    onTextChanged: page.setField("name", text)
                }

                FieldLabel {
                    text: i18n("Type:")
                }
                QQC2.ComboBox {
                    id: typeBox
                    Layout.fillWidth: true
                    model: Servers.types.map(function(t) { return { label: page.typeLabel(t), value: t } })
                    textRole: "label"
                    valueRole: "value"
                    // Scrolling the page must not change a server's type
                    wheelEnabled: false
                    onActivated: page.changeType(currentValue)
                }

                FieldLabel {
                    text: page.currentType === "custom" ? i18n("URL:") : i18n("Address:")
                }
                QQC2.TextField {
                    id: urlField
                    Layout.fillWidth: true
                    placeholderText: page.currentType === "custom"
                                     ? "https://example.org/translate?q={text}&to={target}"
                                     : Servers.adapter(page.currentType).defaults.url
                    onTextChanged: page.setField("url", text.trim())
                    onEditingFinished: page.refreshFromServer()
                }

                FieldLabel {
                    text: page.currentType === "deeplx" ? i18n("Token:") : i18n("API key:")
                }
                Kirigami.PasswordField {
                    id: keyField
                    Layout.fillWidth: true
                    placeholderText: page.currentType === "deepl" ? i18n("Required") : i18n("Optional")
                    onTextChanged: page.setField("apiKey", text.trim())
                    onEditingFinished: page.refreshFromServer()
                }

                FieldLabel {
                    text: i18n("Model:")
                    visible: page.currentType === "openai"
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: page.currentType === "openai"

                    // Both halves share the row, so model names are not cut short
                    QQC2.TextField {
                        id: modelField
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        placeholderText: "gemma3:4b"
                        onTextChanged: page.setField("model", text.trim())
                    }
                    QQC2.ComboBox {
                        visible: page.models.length > 0
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        wheelEnabled: false
                        model: page.models
                        displayText: i18n("Installed models")
                        onActivated: modelField.text = currentText
                    }
                }

                FieldLabel {
                    text: i18n("Instructions:")
                    visible: page.currentType === "openai"
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    Layout.topMargin: promptArea.topPadding
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: page.currentType === "openai"

                    QQC2.TextArea {
                        id: promptArea
                        Layout.fillWidth: true
                        // Grows with its text, which would otherwise spill over the next rows
                        Layout.preferredHeight: Math.max(implicitHeight, Kirigami.Units.gridUnit * 5)
                        wrapMode: TextEdit.Wrap
                        // Stored empty while it is the default, so it follows future defaults
                        onTextChanged: page.setField("prompt", text === OpenAI.defaultPrompt ? "" : text)
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font: Kirigami.Theme.smallFont
                        text: i18n("Placeholders: {text} {source_name} {source_code} {target_name} {target_code}. Without {text}, the text is added at the end.")
                    }
                }

                FieldLabel {
                    text: i18n("Method:")
                    visible: page.currentType === "custom"
                }
                QQC2.ComboBox {
                    id: methodBox
                    visible: page.currentType === "custom"
                    wheelEnabled: false
                    model: ["POST", "GET"]
                    onActivated: {
                        page.currentMethod = currentText
                        page.setField("method", currentText)
                    }
                }

                FieldLabel {
                    text: i18n("Headers:")
                    visible: page.currentType === "custom"
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    Layout.topMargin: headersArea.topPadding
                }
                QQC2.TextArea {
                    id: headersArea
                    Layout.fillWidth: true
                    visible: page.currentType === "custom"
                    placeholderText: "Authorization: Bearer {api_key}"
                    onTextChanged: page.setField("headers", text)
                }

                FieldLabel {
                    text: i18n("Body:")
                    visible: bodyArea.visible
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    Layout.topMargin: bodyArea.topPadding
                }
                QQC2.TextArea {
                    id: bodyArea
                    Layout.fillWidth: true
                    // Grows with its text, which would otherwise spill over the next rows
                    Layout.preferredHeight: Math.max(implicitHeight, Kirigami.Units.gridUnit * 4)
                    visible: page.currentType === "custom" && page.currentMethod !== "GET"
                    wrapMode: TextEdit.Wrap
                    onTextChanged: page.setField("body", text)
                }

                FieldLabel {
                    text: i18n("Result path:")
                    visible: page.currentType === "custom"
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    Layout.topMargin: resultField.topPadding
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: page.currentType === "custom"

                    QQC2.TextField {
                        id: resultField
                        Layout.fillWidth: true
                        placeholderText: "translatedText, data.translations.0.text"
                        onTextChanged: page.setField("resultPath", text.trim())
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font: Kirigami.Theme.smallFont
                        text: i18n("Placeholders: {text} {source} {target} {source_name} {target_name} {api_key}. Leave the result path empty when the server answers with plain text.")
                    }
                }

                FieldLabel {
                    text: i18n("Languages:")
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: page.languageInfo
                }

                Item {
                    implicitWidth: 1
                }
                // The result sits next to the button: below it, it would be
                // out of view at the bottom of the scrolled form.
                RowLayout {
                    Layout.fillWidth: true

                    QQC2.Button {
                        text: i18n("Test")
                        icon.name: "network-connect"
                        enabled: !page.testing
                        onClicked: page.runTest()
                    }
                    QQC2.BusyIndicator {
                        running: page.testing
                        visible: running
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: page.testing || page.status !== ""
                        wrapMode: Text.WordWrap
                        text: page.testing ? i18n("Testing…") : page.status
                        color: page.testing ? Kirigami.Theme.textColor
                             : page.statusOk ? Kirigami.Theme.positiveTextColor
                             : Kirigami.Theme.negativeTextColor
                    }
                }
            }
        }
    }
}
