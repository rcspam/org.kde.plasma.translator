.pragma library
.import "common.js" as Common

// OpenAI-compatible chat completions: Ollama, LM Studio, OpenAI, Mistral, Groq...

var defaults = { url: "http://localhost:11434/v1" }
var allLanguages = true

// TranslateGemma's prompt format (https://ollama.com/library/translategemma),
// which works as well with general-purpose models.
var defaultPrompt = "You are a professional {source_name} ({source_code}) to {target_name} ({target_code}) "
        + "translator. Your goal is to accurately convey the meaning and nuances of the original "
        + "{source_name} text while adhering to {target_name} grammar, vocabulary, and cultural "
        + "sensitivities.\nProduce only the {target_name} translation, without any additional "
        + "explanations or commentary. Please translate the following {source_name} text into "
        + "{target_name}:\n\n\n{text}"

function apiBase(server) {
    return Common.trimUrl(server.url).replace(/\/chat\/completions$/, "")
}

function headers(server) {
    var h = { "Content-Type": "application/json" }
    if (server.apiKey) {
        h["Authorization"] = "Bearer " + server.apiKey
    }
    return h
}

function buildRequest(server, req) {
    var model = (server.model || "").trim()
    if (!model) {
        return { error: "config", detail: "model" }
    }
    // Instructions and text go in a single user message: chat templates such
    // as TranslateGemma's turn a system message into a separate user turn,
    // and the model then echoes the text or obeys it instead of translating.
    var template = server.prompt || defaultPrompt
    if (template.indexOf("{text}") === -1) {
        template += "\n\n\n{text}"
    }
    var auto = req.source === "auto"
    var content = Common.fill(template, {
        source_name: auto || !req.sourceName ? "source language" : req.sourceName,
        source_code: req.source,
        target_name: req.targetName || req.target,
        target_code: req.target,
        text: req.text
    })
    var payload = {
        model: model,
        stream: false,
        messages: [{ role: "user", content: content }]
    }
    return { method: "POST", url: apiBase(server) + "/chat/completions", headers: headers(server),
             body: JSON.stringify(payload) }
}

function parseResponse(status, body) {
    if (status !== 200) {
        return Common.httpError(status, body)
    }
    var content = Common.getPath(Common.parseJson(body), "choices.0.message.content")
    if (typeof content !== "string") {
        return Common.badFormat(body)
    }
    return { text: Common.stripThink(content) }
}

function languagesRequest(server) {
    return null
}

function modelsRequest(server) {
    return { method: "GET", url: apiBase(server) + "/models", headers: headers(server), body: null }
}

function parseModels(status, body) {
    if (status !== 200) {
        return Common.httpError(status, body)
    }
    var data = Common.getPath(Common.parseJson(body), "data")
    if (!Array.isArray(data)) {
        return Common.badFormat(body)
    }
    return { models: data.map(function(m) { return m.id }).sort() }
}
