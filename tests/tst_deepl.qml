import QtQuick
import QtTest
import "../contents/ui/servers/deepl.js" as DeepL

TestCase {
    name: "DeepL"

    property var server: ({ type: "deepl", url: "https://api-free.deepl.com/v2/", apiKey: "k:fx",
                            languages: ["EN-GB", "EN-US", "FR", "PT-BR", "PT-PT", "ZH", "ZH-HANS", "ZH-HANT", "NB"] })

    function req(source, target) {
        return { text: "Bonjour", source: source, target: target, sourceName: "", targetName: "" }
    }

    function test_buildRequest() {
        var r = DeepL.buildRequest(server, req("fr", "en"))
        compare(r.method, "POST")
        compare(r.url, "https://api-free.deepl.com/v2/translate")
        compare(r.headers["Authorization"], "DeepL-Auth-Key k:fx")
        var body = JSON.parse(r.body)
        compare(body.text, ["Bonjour"])
        compare(body.source_lang, "FR")
        compare(body.target_lang, "EN-US")
    }

    function test_buildRequest_regionalCodes() {
        var body = JSON.parse(DeepL.buildRequest(server, req("zh-CN", "pt")).body)
        compare(body.source_lang, "ZH")
        compare(body.target_lang, "PT-PT")
        body = JSON.parse(DeepL.buildRequest(server, req("en", "zh-TW")).body)
        compare(body.source_lang, "EN")
        compare(body.target_lang, "ZH-HANT")
    }

    function test_buildRequest_autoOmitsSource() {
        var body = JSON.parse(DeepL.buildRequest(server, req("auto", "no")).body)
        verify(!body.hasOwnProperty("source_lang"))
        compare(body.target_lang, "NB")
    }

    function test_buildRequest_requiresKey() {
        var s = JSON.parse(JSON.stringify(server))
        s.apiKey = ""
        var r = DeepL.buildRequest(s, req("fr", "en"))
        compare(r.error, "config")
        compare(r.detail, "apikey")
    }

    function test_parseResponse_ok() {
        var res = DeepL.parseResponse(200, '{"translations":[{"detected_source_language":"ZH","text":"Hello"}]}')
        compare(res.text, "Hello")
        compare(res.detected, "zh-CN")
    }

    function test_parseResponse_quota() {
        var res = DeepL.parseResponse(456, '{"message":"Quota Exceeded"}')
        compare(res.error, "server")
        compare(res.detail, "Quota Exceeded")
    }

    function test_parseResponse_badKey() {
        compare(DeepL.parseResponse(403, "").error, "auth")
    }

    function test_languages() {
        var r = DeepL.languagesRequest(server)
        compare(r.url, "https://api-free.deepl.com/v2/languages?type=target")
        compare(r.headers["Authorization"], "DeepL-Auth-Key k:fx")
        var res = DeepL.parseLanguages(200, '[{"language":"EN-GB","name":"English (British)"},{"language":"FR","name":"French"}]')
        compare(res.codes, ["EN-GB", "FR"])
    }
}
