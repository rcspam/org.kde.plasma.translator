.pragma library
.import "common.js" as Common
.import "http.js" as Http
.import "libretranslate.js" as LibreTranslate
.import "deepl.js" as DeepL
.import "deeplx.js" as DeepLX
.import "openai.js" as OpenAI
.import "custom.js" as Custom

// User-defined translation servers. A server is a plain object stored in the
// "servers" config key (JSON array); the engine key of a server is "server:<id>".

var types = ["libretranslate", "deepl", "deeplx", "openai", "custom"]

var adapters = {
    "libretranslate": LibreTranslate,
    "deepl": DeepL,
    "deeplx": DeepLX,
    "openai": OpenAI,
    "custom": Custom
}

var defaultNames = {
    "libretranslate": "LibreTranslate",
    "deepl": "DeepL",
    "deeplx": "DeepLX",
    "openai": "LLM",
    "custom": "Custom"
}

var enginePrefix = "server:"

function adapter(type) {
    return adapters[type] || LibreTranslate
}

function newServer(type, id) {
    var server = { id: id, name: defaultNames[type], type: type, url: "", apiKey: "",
                   model: "", prompt: "", languages: null }
    var defaults = adapter(type).defaults
    for (var key in defaults) {
        server[key] = defaults[key]
    }
    return server
}

// Returns a copy switched to another type. Values the user typed are kept,
// values that were only the old type's defaults are replaced.
function changeType(server, type) {
    var copy = JSON.parse(JSON.stringify(server))
    var oldDefaults = newServer(server.type, server.id)
    var fresh = newServer(type, server.id)
    for (var key in fresh) {
        if (copy[key] === undefined || copy[key] === oldDefaults[key]) {
            copy[key] = fresh[key]
        }
    }
    copy.type = type
    copy.languages = null
    return copy
}

function engineOf(server) {
    return enginePrefix + server.id
}

function isServerEngine(engine) {
    return typeof engine === "string" && engine.indexOf(enginePrefix) === 0
}

function parseList(json) {
    var list = Common.parseJson(json || "")
    return Array.isArray(list) ? list : []
}

function findServer(list, engine) {
    if (!isServerEngine(engine)) {
        return null
    }
    var id = engine.substring(enginePrefix.length)
    for (var i = 0; i < list.length; i++) {
        if (list[i].id === id) {
            return list[i]
        }
    }
    return null
}

// Widget language codes the server supports, or null when it takes them all
// (or when its list is not known yet).
function enabledCodes(server) {
    var a = adapter(server.type)
    if (a.allLanguages) {
        return null
    }
    var codes = server.languages || a.staticLanguages || null
    if (!codes) {
        return null
    }
    var result = []
    codes.forEach(function(code) {
        var widgetCode = Common.toWidgetCode(code, a.aliases)
        if (result.indexOf(widgetCode) === -1) {
            result.push(widgetCode)
        }
    })
    return result
}

// Runs request -> parse and calls done(result) exactly once. The returned
// handle's abort(reason) answers { error: reason } and drops the reply.
function exchange(request, parse, done, transport) {
    var finished = false
    function finish(result) {
        if (!finished) {
            finished = true
            done(result)
        }
    }
    var pending = (transport || Http.send)(request, function(status, body) {
        finish(parse(status, body))
    })
    return {
        abort: function(reason) {
            finish({ error: reason || "aborted", detail: "" })
            pending.abort()
        }
    }
}

var noop = { abort: function() {} }

function translate(server, req, done, transport) {
    if (!Common.trimUrl(server.url)) {
        done({ error: "config", detail: "url" })
        return noop
    }
    var a = adapter(server.type)
    var request = a.buildRequest(server, req)
    if (request.error) {
        done(request)
        return noop
    }
    return exchange(request, function(status, body) {
        return a.parseResponse(status, body, server)
    }, done, transport)
}

function fetchLanguages(server, done, transport) {
    var a = adapter(server.type)
    var request = Common.trimUrl(server.url) ? a.languagesRequest(server) : null
    if (!request) {
        done({ codes: null })
        return noop
    }
    return exchange(request, a.parseLanguages, done, transport)
}

function fetchModels(server, done, transport) {
    var a = adapter(server.type)
    if (!a.modelsRequest || !Common.trimUrl(server.url)) {
        done({ models: [] })
        return noop
    }
    return exchange(a.modelsRequest(server), a.parseModels, done, transport)
}
