import QtQuick
import QtTest
import "../contents/ui/servers/deeplx.js" as DeepLX

TestCase {
    name: "DeepLX"

    property var server: ({ type: "deeplx", url: "http://localhost:1188", apiKey: "" })

    function req(source, target) {
        return { text: "Bonjour", source: source, target: target, sourceName: "", targetName: "" }
    }

    function test_buildRequest() {
        var r = DeepLX.buildRequest(server, req("fr", "zh-CN"))
        compare(r.method, "POST")
        compare(r.url, "http://localhost:1188/translate")
        verify(!r.headers.hasOwnProperty("Authorization"))
        var body = JSON.parse(r.body)
        compare(body.text, "Bonjour")
        compare(body.source_lang, "FR")
        compare(body.target_lang, "ZH")
    }

    function test_buildRequest_keepsFullEndpoint() {
        var s = { type: "deeplx", url: "https://deeplx.example.org/v1/translate", apiKey: "tok" }
        var r = DeepLX.buildRequest(s, req("auto", "en"))
        compare(r.url, "https://deeplx.example.org/v1/translate")
        compare(r.headers["Authorization"], "Bearer tok")
        verify(!JSON.parse(r.body).hasOwnProperty("source_lang"))
    }

    function test_parseResponse_ok() {
        var res = DeepLX.parseResponse(200, '{"code":200,"data":"Hello","source_lang":"FR","target_lang":"EN"}')
        compare(res.text, "Hello")
        compare(res.detected, "fr")
    }

    function test_parseResponse_errorCode() {
        var res = DeepLX.parseResponse(200, '{"code":429,"message":"Too many requests"}')
        compare(res.error, "server")
        compare(res.detail, "Too many requests")
    }

    function test_hasStaticLanguages() {
        verify(DeepLX.languagesRequest(server) === null)
        verify(DeepLX.staticLanguages.indexOf("FR") !== -1)
        verify(DeepLX.staticLanguages.indexOf("ZH-HANT") !== -1)
    }
}
