import QtQuick
import "servers/servers.js" as Servers

// QML front of servers.js: adds a timeout (QML's XMLHttpRequest has none)
// and turns error results into localized messages.
QtObject {
    id: client

    property int timeout: 60000

    property Component timerComponent: Component {
        Timer {
            repeat: false
        }
    }

    // start(cb) launches a request and returns its handle; done gets one result.
    function guarded(start, done) {
        var timer = timerComponent.createObject(client, { interval: client.timeout })
        var handle = null
        var finished = false
        timer.triggered.connect(function() {
            if (handle) {
                handle.abort("timeout")
            }
        })
        timer.start()
        handle = start(function(result) {
            if (finished) {
                return
            }
            finished = true
            timer.stop()
            timer.destroy()
            done(result)
        })
        return handle
    }

    function translate(server, req, done) {
        return guarded(function(cb) { return Servers.translate(server, req, cb) }, done)
    }

    function fetchLanguages(server, done) {
        return guarded(function(cb) { return Servers.fetchLanguages(server, cb) }, done)
    }

    function fetchModels(server, done) {
        return guarded(function(cb) { return Servers.fetchModels(server, cb) }, done)
    }

    function errorText(result, server) {
        var url = server ? server.url : ""
        switch (result.error) {
        case "unreachable":
            return i18n("Cannot reach the server at %1.", url)
        case "timeout":
            return i18n("The server at %1 did not answer in time.", url)
        case "auth":
            return result.detail ? i18n("The server refused the API key: %1", result.detail)
                                 : i18n("The server refused the API key.")
        case "server":
            return i18n("Server error: %1", result.detail)
        case "format":
            return i18n("Unexpected answer from the server: %1", result.detail)
        case "noserver":
            return i18n("This server no longer exists. Choose another engine in the settings.")
        case "config":
            if (result.detail === "url") {
                return i18n("The server address is missing.")
            }
            if (result.detail === "apikey") {
                return i18n("The API key is missing.")
            }
            if (result.detail === "model") {
                return i18n("The model name is missing.")
            }
        }
        return i18n("Unknown error: %1", result.detail || result.error)
    }
}
