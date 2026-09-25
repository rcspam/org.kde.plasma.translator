.pragma library
.import "common.js" as Common

// Official DeepL API: https://developers.deepl.com/docs

var defaults = { url: "https://api-free.deepl.com" }
var allLanguages = false

// Target codes carry a region for some languages; source codes never do.
var aliases = {
    "en": ["EN-US", "EN-GB", "EN"],
    "pt": ["PT-PT", "PT-BR", "PT"],
    "zh-CN": ["ZH-HANS", "ZH"],
    "zh-TW": ["ZH-HANT"],
    "no": ["NB"]
}
var sourceAliases = {
    "en": ["EN"],
    "pt": ["PT"],
    "zh-CN": ["ZH"],
    "zh-TW": ["ZH"],
    "no": ["NB"]
}

function apiBase(server) {
    return Common.trimUrl(server.url).replace(/\/v2$/, "") + "/v2"
}

function authHeaders(server) {
    return { "Authorization": "DeepL-Auth-Key " + server.apiKey }
}

function buildRequest(server, req) {
    if (!server.apiKey) {
        return { error: "config", detail: "apikey" }
    }
    var payload = {
        text: [req.text],
        target_lang: Common.toServerCode(req.target, aliases, server.languages, true)
    }
    if (req.source !== "auto") {
        payload.source_lang = Common.toServerCode(req.source, sourceAliases, null, true)
    }
    var headers = authHeaders(server)
    headers["Content-Type"] = "application/json"
    return { method: "POST", url: apiBase(server) + "/translate", headers: headers,
             body: JSON.stringify(payload) }
}

function parseResponse(status, body) {
    if (status !== 200) {
        return Common.httpError(status, body)
    }
    var json = Common.parseJson(body)
    var first = json && json.translations && json.translations[0]
    if (!first || typeof first.text !== "string") {
        return Common.badFormat(body)
    }
    var res = { text: first.text }
    if (first.detected_source_language) {
        res.detected = Common.toWidgetCode(first.detected_source_language, sourceAliases)
    }
    return res
}

function languagesRequest(server) {
    return { method: "GET", url: apiBase(server) + "/languages?type=target",
             headers: authHeaders(server), body: null }
}

function parseLanguages(status, body) {
    if (status !== 200) {
        return Common.httpError(status, body)
    }
    var json = Common.parseJson(body)
    if (!Array.isArray(json)) {
        return Common.badFormat(body)
    }
    return { codes: json.map(function(l) { return l.language }) }
}
