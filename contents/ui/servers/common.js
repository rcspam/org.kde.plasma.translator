.pragma library

// Helpers shared by the translation server adapters.

function trimUrl(url) {
    return (url || "").trim().replace(/\/+$/, "")
}

// Reads "a.b.0.c" from a parsed JSON object; undefined when a step is missing.
function getPath(obj, path) {
    var parts = path.split(".")
    var cur = obj
    for (var i = 0; i < parts.length; i++) {
        if (cur === null || cur === undefined) {
            return undefined
        }
        cur = cur[parts[i]]
    }
    return cur
}

// Escapes a string for insertion between the quotes of a JSON string.
function jsonEscape(s) {
    var quoted = JSON.stringify(String(s))
    return quoted.substring(1, quoted.length - 1)
}

// Replaces {key} placeholders; unknown placeholders are left untouched.
function fill(template, values, encode) {
    return template.replace(/\{(\w+)\}/g, function(match, key) {
        if (!values.hasOwnProperty(key)) {
            return match
        }
        return encode ? encode(values[key]) : values[key]
    })
}

// Reasoning models may prepend their chain of thought.
function stripThink(s) {
    return s.replace(/<think>[\s\S]*?<\/think>/g, "").trim()
}

function parseJson(body) {
    try {
        return JSON.parse(body)
    } catch (e) {
        return null
    }
}

// Maps a widget language code to the code a server expects. When the
// server's own list is known, the first alias it accepts wins.
function toServerCode(code, aliases, serverCodes, upperCase) {
    var candidates = (aliases[code] || []).concat([upperCase ? code.toUpperCase() : code])
    if (serverCodes) {
        for (var i = 0; i < candidates.length; i++) {
            for (var j = 0; j < serverCodes.length; j++) {
                if (serverCodes[j].toLowerCase() === candidates[i].toLowerCase()) {
                    return serverCodes[j]
                }
            }
        }
    }
    return candidates[0]
}

function toWidgetCode(serverCode, aliases) {
    var lower = serverCode.toLowerCase()
    for (var code in aliases) {
        var list = aliases[code]
        for (var i = 0; i < list.length; i++) {
            if (list[i].toLowerCase() === lower) {
                return code
            }
        }
    }
    return lower
}

function badFormat(body) {
    return { error: "format", detail: String(body).trim().substring(0, 200) }
}

// Turns a failed HTTP exchange into { error, detail }.
function httpError(status, body) {
    if (status === 0) {
        return { error: "unreachable", detail: "" }
    }
    var json = parseJson(body)
    var message = json ? (json.error || json.message || json.detail || "") : ""
    if (typeof message === "object") {
        message = message.message || JSON.stringify(message)
    }
    if (!message) {
        message = "HTTP " + status + ": " + String(body).trim().substring(0, 200)
    }
    return { error: (status === 401 || status === 403) ? "auth" : "server", detail: message }
}
