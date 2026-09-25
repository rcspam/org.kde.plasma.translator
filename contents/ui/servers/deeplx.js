.pragma library
.import "common.js" as Common

// DeepLX, a self-hosted proxy to DeepL: https://github.com/OwO-Network/DeepLX

var defaults = { url: "http://localhost:1188" }
var allLanguages = false

var aliases = {
    "zh-CN": ["ZH"],
    "zh-TW": ["ZH-HANT"],
    "no": ["NB"]
}

// DeepLX has no language endpoint: DeepL's list.
var staticLanguages = ["AR", "BG", "CS", "DA", "DE", "EL", "EN", "ES", "ET", "FI", "FR", "HU",
                       "ID", "IT", "JA", "KO", "LT", "LV", "NB", "NL", "PL", "PT", "RO", "RU",
                       "SK", "SL", "SV", "TR", "UK", "ZH", "ZH-HANT"]

function endpoint(server) {
    var url = Common.trimUrl(server.url)
    return /\/translate$/.test(url) ? url : url + "/translate"
}

function buildRequest(server, req) {
    var payload = {
        text: req.text,
        target_lang: Common.toServerCode(req.target, aliases, staticLanguages, true)
    }
    if (req.source !== "auto") {
        payload.source_lang = Common.toServerCode(req.source, aliases, staticLanguages, true)
    }
    var headers = { "Content-Type": "application/json" }
    if (server.apiKey) {
        headers["Authorization"] = "Bearer " + server.apiKey
    }
    return { method: "POST", url: endpoint(server), headers: headers, body: JSON.stringify(payload) }
}

function parseResponse(status, body) {
    if (status !== 200) {
        return Common.httpError(status, body)
    }
    var json = Common.parseJson(body)
    if (json && json.code !== undefined && json.code !== 200) {
        return { error: "server", detail: json.message || ("code " + json.code) }
    }
    if (!json || typeof json.data !== "string") {
        return Common.badFormat(body)
    }
    var res = { text: json.data }
    if (json.source_lang) {
        res.detected = Common.toWidgetCode(json.source_lang, aliases)
    }
    return res
}

function languagesRequest(server) {
    return null
}
