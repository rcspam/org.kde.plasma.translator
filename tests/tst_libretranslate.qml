import QtQuick
import QtTest
import "../contents/ui/servers/libretranslate.js" as LT

TestCase {
    name: "LibreTranslate"

    property var server: ({ type: "libretranslate", url: "http://localhost:5000/", apiKey: "",
                            languages: ["en", "fr", "zh-Hans", "nb"] })

    function req(source, target) {
        return { text: "Bonjour \"le\" monde", source: source, target: target,
                 sourceName: "French", targetName: "English" }
    }

    function test_buildRequest_postsJson() {
        var r = LT.buildRequest(server, req("fr", "en"))
        compare(r.method, "POST")
        compare(r.url, "http://localhost:5000/translate")
        compare(r.headers["Content-Type"], "application/json")
        var body = JSON.parse(r.body)
        compare(body.q, "Bonjour \"le\" monde")
        compare(body.source, "fr")
        compare(body.target, "en")
        compare(body.format, "text")
        verify(!body.hasOwnProperty("api_key"))
    }

    function test_buildRequest_mapsCodesToServer() {
        var body = JSON.parse(LT.buildRequest(server, req("no", "zh-CN")).body)
        compare(body.source, "nb")
        compare(body.target, "zh-Hans")
    }

    function test_buildRequest_autoAndApiKey() {
        var s = JSON.parse(JSON.stringify(server))
        s.apiKey = "secret"
        var body = JSON.parse(LT.buildRequest(s, req("auto", "en")).body)
        compare(body.source, "auto")
        compare(body.api_key, "secret")
    }

    function test_parseResponse_ok() {
        var res = LT.parseResponse(200, '{"detectedLanguage":{"confidence":90,"language":"zh-Hans"},"translatedText":"Hello"}')
        compare(res.text, "Hello")
        compare(res.detected, "zh-CN")
    }

    function test_parseResponse_withoutDetection() {
        var res = LT.parseResponse(200, '{"translatedText":"Hello"}')
        compare(res.text, "Hello")
        compare(res.detected, undefined)
    }

    function test_parseResponse_serverError() {
        var res = LT.parseResponse(400, '{"error":"fr is not supported"}')
        compare(res.error, "server")
        compare(res.detail, "fr is not supported")
    }

    function test_parseResponse_garbage() {
        compare(LT.parseResponse(200, "<html>").error, "format")
    }

    function test_languages() {
        var r = LT.languagesRequest(server)
        compare(r.method, "GET")
        compare(r.url, "http://localhost:5000/languages")
        var res = LT.parseLanguages(200, '[{"code":"en","name":"English"},{"code":"zh-Hans","name":"Chinese"}]')
        compare(res.codes, ["en", "zh-Hans"])
    }
}
