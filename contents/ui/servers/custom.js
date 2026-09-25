.pragma library
.import "common.js" as Common

// Any HTTP API described by the user. Placeholders: {text} {source} {target}
// {source_name} {target_name} {api_key}.

var defaults = {
    url: "",
    method: "POST",
    headers: "Content-Type: application/json",
    body: "{\"q\": \"{text}\", \"source\": \"{source}\", \"target\": \"{target}\"}",
    resultPath: ""
}
var allLanguages = true

function parseHeaders(text, values) {
    var headers = {}
    text.split("\n").forEach(function(line) {
        var idx = line.indexOf(":")
        if (idx <= 0) {
            return
        }
        var name = line.substring(0, idx).trim()
        if (name) {
            headers[name] = Common.fill(line.substring(idx + 1).trim(), values)
        }
    })
    return headers
}

function findHeader(headers, name) {
    for (var key in headers) {
        if (key.toLowerCase() === name) {
            return headers[key]
        }
    }
    return undefined
}

function buildRequest(server, req) {
    var values = {
        text: req.text,
        source: req.source,
        target: req.target,
        source_name: req.sourceName || req.source,
        target_name: req.targetName || req.target,
        api_key: server.apiKey || ""
    }
    var method = (server.method || "POST").toUpperCase()
    var headers = parseHeaders(server.headers || "", values)
    var body = null
    if (method !== "GET") {
        var contentType = findHeader(headers, "content-type")
        if (contentType === undefined) {
            contentType = headers["Content-Type"] = "application/json"
        }
        var encode = /x-www-form-urlencoded/i.test(contentType) ? encodeURIComponent
                   : /json/i.test(contentType) ? Common.jsonEscape : null
        body = Common.fill(server.body || "", values, encode)
    }
    return { method: method, url: Common.fill((server.url || "").trim(), values, encodeURIComponent),
             headers: headers, body: body }
}

function parseResponse(status, body, server) {
    if (status < 200 || status >= 300) {
        return Common.httpError(status, body)
    }
    var path = (server.resultPath || "").trim()
    if (!path) {
        var plain = String(body).trim()
        return plain ? { text: plain } : Common.badFormat(body)
    }
    var value = Common.getPath(Common.parseJson(body), path)
    if (typeof value !== "string" && typeof value !== "number") {
        return Common.badFormat(body)
    }
    return { text: String(value).trim() }
}

function languagesRequest(server) {
    return null
}
