.pragma library
.import "common.js" as Common

// LibreTranslate API: https://libretranslate.com/docs

var defaults = { url: "http://localhost:5000" }
var allLanguages = false

// Widget code -> LibreTranslate codes (current naming first, older after).
var aliases = {
    "zh-CN": ["zh-Hans", "zh"],
    "zh-TW": ["zh-Hant", "zt"],
    "no": ["nb"]
}

function buildRequest(server, req) {
    var payload = {
        q: req.text,
        source: req.source === "auto" ? "auto"
                                      : Common.toServerCode(req.source, aliases, server.languages),
        target: Common.toServerCode(req.target, aliases, server.languages),
        format: "text"
    }
    if (server.apiKey) {
        payload.api_key = server.apiKey
    }
    return {
        method: "POST",
        url: Common.trimUrl(server.url) + "/translate",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
    }
}

function parseResponse(status, body) {
    if (status !== 200) {
        return Common.httpError(status, body)
    }
    var json = Common.parseJson(body)
    if (!json || typeof json.translatedText !== "string") {
        return Common.badFormat(body)
    }
    var res = { text: json.translatedText }
    if (json.detectedLanguage && json.detectedLanguage.language) {
        res.detected = Common.toWidgetCode(json.detectedLanguage.language, aliases)
    }
    return res
}

function languagesRequest(server) {
    return { method: "GET", url: Common.trimUrl(server.url) + "/languages", headers: {}, body: null }
}

function parseLanguages(status, body) {
    if (status !== 200) {
        return Common.httpError(status, body)
    }
    var json = Common.parseJson(body)
    if (!Array.isArray(json)) {
        return Common.badFormat(body)
    }
    return { codes: json.map(function(l) { return l.code }) }
}
