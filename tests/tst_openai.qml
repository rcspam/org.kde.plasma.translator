import QtQuick
import QtTest
import "../contents/ui/servers/openai.js" as OpenAI

TestCase {
    name: "OpenAI"

    property var server: ({ type: "openai", url: "http://localhost:11434/v1/", apiKey: "",
                            model: "gemma3:4b", prompt: "" })

    function req(source, target) {
        return { text: "Bonjour", source: source, target: target,
                 sourceName: source === "auto" ? "" : "French", targetName: "English" }
    }

    // Instructions and text travel in one user message, the format
    // TranslateGemma is trained on (a system message becomes a separate turn).
    function test_buildRequest_singleUserMessage() {
        var r = OpenAI.buildRequest(server, req("fr", "en"))
        compare(r.method, "POST")
        compare(r.url, "http://localhost:11434/v1/chat/completions")
        verify(!r.headers.hasOwnProperty("Authorization"))
        var body = JSON.parse(r.body)
        compare(body.model, "gemma3:4b")
        compare(body.stream, false)
        compare(body.messages.length, 1)
        compare(body.messages[0].role, "user")
        var content = body.messages[0].content
        verify(content.indexOf("You are a professional French (fr) to English (en) translator.") === 0, content)
        verify(content.indexOf("Please translate the following French text into English:\n\n\nBonjour") !== -1, content)
    }

    function test_buildRequest_autoSource() {
        var content = JSON.parse(OpenAI.buildRequest(server, req("auto", "en")).body).messages[0].content
        verify(content.indexOf("professional source language (auto) to English (en) translator") !== -1, content)
    }

    function test_buildRequest_promptWithoutTextGetsTextAppended() {
        var s = { type: "openai", url: "https://api.openai.com/v1/chat/completions", apiKey: "sk-1",
                  model: "gpt-4o-mini", prompt: "Into {target_name}, please." }
        var r = OpenAI.buildRequest(s, req("fr", "en"))
        compare(r.url, "https://api.openai.com/v1/chat/completions")
        compare(r.headers["Authorization"], "Bearer sk-1")
        compare(JSON.parse(r.body).messages[0].content, "Into English, please.\n\n\nBonjour")
    }

    function test_buildRequest_promptWithTextPlaceholder() {
        var s = { type: "openai", url: "http://x/v1", apiKey: "", model: "m",
                  prompt: "To {target_code}: {text} (from {source_code})" }
        compare(JSON.parse(OpenAI.buildRequest(s, req("fr", "en")).body).messages[0].content,
                "To en: Bonjour (from fr)")
    }

    function test_buildRequest_textIsNotExpanded() {
        var r = { text: "Say {target_name}", source: "fr", target: "en", sourceName: "French", targetName: "English" }
        var s = { type: "openai", url: "http://x/v1", apiKey: "", model: "m", prompt: "{text}" }
        compare(JSON.parse(OpenAI.buildRequest(s, r).body).messages[0].content, "Say {target_name}")
    }

    function test_buildRequest_requiresModel() {
        var s = { type: "openai", url: "http://localhost:11434/v1", apiKey: "", model: " ", prompt: "" }
        var r = OpenAI.buildRequest(s, req("fr", "en"))
        compare(r.error, "config")
        compare(r.detail, "model")
    }

    function test_parseResponse_stripsThinking() {
        var res = OpenAI.parseResponse(200, JSON.stringify({ choices: [{ message: {
            role: "assistant", content: "<think>ok</think>\n Hello \n" } }] }))
        compare(res.text, "Hello")
    }

    function test_parseResponse_error() {
        var res = OpenAI.parseResponse(404, '{"error":{"message":"model \\"x\\" not found"}}')
        compare(res.error, "server")
        compare(res.detail, 'model "x" not found')
    }

    function test_parseResponse_noChoices() {
        compare(OpenAI.parseResponse(200, '{"choices":[]}').error, "format")
    }

    function test_models() {
        var r = OpenAI.modelsRequest(server)
        compare(r.url, "http://localhost:11434/v1/models")
        var res = OpenAI.parseModels(200, '{"data":[{"id":"mistral"},{"id":"gemma3:4b"}]}')
        compare(res.models, ["gemma3:4b", "mistral"])
    }

    function test_allLanguages() {
        verify(OpenAI.allLanguages)
        verify(OpenAI.languagesRequest(server) === null)
    }
}
