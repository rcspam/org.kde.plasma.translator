import QtQuick
import QtTest
import "../contents/ui/servers/common.js" as Common

TestCase {
    name: "Common"

    function test_trimUrl() {
        compare(Common.trimUrl(" http://localhost:5000/// "), "http://localhost:5000")
        compare(Common.trimUrl(""), "")
        compare(Common.trimUrl(undefined), "")
    }

    function test_getPath_data() {
        return [
            { tag: "top level", path: "translatedText", expected: "Hello" },
            { tag: "nested with index", path: "data.translations.0.text", expected: "Salut" },
            { tag: "missing key", path: "data.nope", expected: undefined },
            { tag: "index out of range", path: "data.translations.3.text", expected: undefined },
        ]
    }
    function test_getPath(row) {
        var obj = { translatedText: "Hello", data: { translations: [{ text: "Salut" }] } }
        compare(Common.getPath(obj, row.path), row.expected)
    }

    function test_jsonEscape() {
        compare(Common.jsonEscape('say "hi"\nnow\\'), 'say \\"hi\\"\\nnow\\\\')
    }

    function test_fill_replacesEveryOccurrence() {
        compare(Common.fill("{a}-{b}-{a}", { a: "x", b: "y" }), "x-y-x")
    }

    function test_fill_encodesValues() {
        compare(Common.fill("q={text}", { text: "a b&c" }, encodeURIComponent), "q=a%20b%26c")
    }

    function test_fill_leavesUnknownPlaceholders() {
        compare(Common.fill("{text} {other}", { text: "t" }), "t {other}")
    }

    function test_stripThink() {
        compare(Common.stripThink("<think>\nlet me see\n</think>\n\nBonjour"), "Bonjour")
        compare(Common.stripThink("Bonjour"), "Bonjour")
    }

    function test_toServerCode_prefersCodeKnownByServer() {
        var aliases = { "zh-CN": ["zh-Hans", "zh"] }
        compare(Common.toServerCode("zh-CN", aliases, ["en", "zh"]), "zh")
        compare(Common.toServerCode("zh-CN", aliases, ["en", "zh-Hans"]), "zh-Hans")
    }

    function test_toServerCode_fallsBackToFirstAlias() {
        compare(Common.toServerCode("zh-CN", { "zh-CN": ["zh-Hans", "zh"] }, null), "zh-Hans")
    }

    function test_toServerCode_withoutAlias() {
        compare(Common.toServerCode("fr", {}, null), "fr")
        compare(Common.toServerCode("fr", {}, null, true), "FR")
    }

    function test_toServerCode_matchesServerCaseInsensitively() {
        compare(Common.toServerCode("en", { en: ["EN-US", "EN-GB"] }, ["en-gb"]), "en-gb")
    }

    function test_toWidgetCode() {
        var aliases = { "zh-CN": ["zh-Hans", "zh"], "no": ["nb"] }
        compare(Common.toWidgetCode("zh-Hans", aliases), "zh-CN")
        compare(Common.toWidgetCode("NB", aliases), "no")
        compare(Common.toWidgetCode("FR", aliases), "fr")
    }

    function test_badFormat_keepsAShortExcerpt() {
        var e = Common.badFormat("  <html>" + new Array(300).join("x"))
        compare(e.error, "format")
        compare(e.detail.length, 200)
        verify(e.detail.indexOf("<html>") === 0)
    }

    function test_httpError_data() {
        return [
            { tag: "unreachable", status: 0, body: "", error: "unreachable", detail: "" },
            { tag: "bad key", status: 403, body: '{"error":"Invalid API key"}', error: "auth", detail: "Invalid API key" },
            { tag: "json message", status: 456, body: '{"message":"Quota exceeded"}', error: "server", detail: "Quota exceeded" },
            { tag: "plain body", status: 500, body: "Internal Server Error", error: "server", detail: "HTTP 500: Internal Server Error" },
        ]
    }
    function test_httpError(row) {
        var e = Common.httpError(row.status, row.body)
        compare(e.error, row.error)
        compare(e.detail, row.detail)
    }
}
