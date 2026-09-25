import QtQuick
import QtTest
import "../contents/ui/servers/custom.js" as Custom

TestCase {
    name: "Custom"

    function req(source, target) {
        return { text: "Bonjour \"toi\" & moi", source: source, target: target,
                 sourceName: "French", targetName: "English" }
    }

    function test_post_fillsJsonBody() {
        var s = { type: "custom", method: "POST", url: "http://host/api", apiKey: "k",
                  headers: "Authorization: Bearer {api_key}\nX-Empty:",
                  body: '{"q":"{text}","from":"{source}","to":"{target}","lang":"{target_name}"}',
                  resultPath: "data.text" }
        var r = Custom.buildRequest(s, req("fr", "en"))
        compare(r.method, "POST")
        compare(r.url, "http://host/api")
        compare(r.headers["Authorization"], "Bearer k")
        compare(r.headers["Content-Type"], "application/json")
        var body = JSON.parse(r.body)
        compare(body.q, "Bonjour \"toi\" & moi")
        compare(body.from, "fr")
        compare(body.to, "en")
        compare(body.lang, "English")
    }

    function test_post_formEncodedBody() {
        var s = { type: "custom", method: "POST", url: "http://host/api", apiKey: "",
                  headers: "Content-Type: application/x-www-form-urlencoded",
                  body: "q={text}&to={target}", resultPath: "" }
        var r = Custom.buildRequest(s, req("fr", "en"))
        compare(r.body, "q=Bonjour%20%22toi%22%20%26%20moi&to=en")
    }

    function test_get_encodesUrl() {
        var s = { type: "custom", method: "GET", url: "http://host/api/{source}/{target}/{text}",
                  apiKey: "", headers: "", body: "", resultPath: "translation" }
        var r = Custom.buildRequest(s, req("auto", "en"))
        compare(r.method, "GET")
        compare(r.url, "http://host/api/auto/en/Bonjour%20%22toi%22%20%26%20moi")
        compare(r.body, null)
    }

    function test_parseResponse_path() {
        var res = Custom.parseResponse(200, '{"data":{"text":"Hello"}}', { resultPath: "data.text" })
        compare(res.text, "Hello")
    }

    function test_parseResponse_plainText() {
        compare(Custom.parseResponse(200, " Hello\n", { resultPath: "" }).text, "Hello")
    }

    function test_parseResponse_missingPath() {
        var res = Custom.parseResponse(200, '{"other":1}', { resultPath: "data.text" })
        compare(res.error, "format")
    }

    function test_parseResponse_httpError() {
        compare(Custom.parseResponse(500, "boom", { resultPath: "x" }).error, "server")
    }

    function test_allLanguages() {
        verify(Custom.allLanguages)
    }
}
