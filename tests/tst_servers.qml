import QtQuick
import QtTest
import "../contents/ui/servers/servers.js" as Servers

TestCase {
    name: "Servers"

    function req() {
        return { text: "Bonjour", source: "fr", target: "en", sourceName: "French", targetName: "English" }
    }

    // Records the request and answers with the given status and body.
    function fakeTransport(status, body, log) {
        return function(request, cb) {
            log.push(request)
            cb(status, body)
            return { abort: function() {} }
        }
    }

    function test_types() {
        compare(Servers.types, ["libretranslate", "deepl", "deeplx", "openai", "custom"])
    }

    function test_newServer_usesTypeDefaults() {
        var s = Servers.newServer("openai", "abc")
        compare(s.id, "abc")
        compare(s.type, "openai")
        compare(s.url, "http://localhost:11434/v1")
        compare(s.apiKey, "")
        compare(s.model, "")
        compare(s.languages, null)
        var c = Servers.newServer("custom", "x")
        compare(c.method, "POST")
        compare(c.headers, "Content-Type: application/json")
    }

    function test_changeType_swapsDefaults() {
        var s = Servers.newServer("libretranslate", "abc")
        s.apiKey = "key"
        s.languages = ["en"]
        var t = Servers.changeType(s, "openai")
        compare(t.id, "abc")
        compare(t.type, "openai")
        compare(t.name, "LLM")
        compare(t.url, "http://localhost:11434/v1")
        compare(t.apiKey, "key")
        compare(t.languages, null)
        compare(s.type, "libretranslate")
    }

    function test_changeType_keepsUserChoices() {
        var s = Servers.newServer("libretranslate", "abc")
        s.name = "My server"
        s.url = "http://nas:5000"
        var t = Servers.changeType(s, "deeplx")
        compare(t.name, "My server")
        compare(t.url, "http://nas:5000")
    }

    function test_engineIds() {
        compare(Servers.engineOf({ id: "abc" }), "server:abc")
        verify(Servers.isServerEngine("server:abc"))
        verify(!Servers.isServerEngine("google"))
        verify(!Servers.isServerEngine(undefined))
    }

    function test_parseList() {
        compare(Servers.parseList(""), [])
        compare(Servers.parseList("not json"), [])
        compare(Servers.parseList('{"a":1}'), [])
        compare(Servers.parseList('[{"id":"a"}]').length, 1)
    }

    function test_findServer() {
        var list = [{ id: "a" }, { id: "b" }]
        compare(Servers.findServer(list, "server:b").id, "b")
        compare(Servers.findServer(list, "server:zz"), null)
        compare(Servers.findServer(list, "google"), null)
    }

    function test_enabledCodes_fromServerList() {
        var s = { type: "libretranslate", languages: ["en", "zh-Hans", "nb", "pt-BR"] }
        compare(Servers.enabledCodes(s), ["en", "zh-CN", "no", "pt-br"])
    }

    function test_enabledCodes_deeplDeduplicates() {
        var s = { type: "deepl", languages: ["EN-GB", "EN-US", "ZH-HANS", "ZH-HANT"] }
        compare(Servers.enabledCodes(s), ["en", "zh-CN", "zh-TW"])
    }

    function test_enabledCodes_unknownListMeansAll() {
        compare(Servers.enabledCodes({ type: "libretranslate", languages: null }), null)
        compare(Servers.enabledCodes({ type: "openai", languages: null }), null)
        compare(Servers.enabledCodes({ type: "custom" }), null)
    }

    function test_enabledCodes_staticList() {
        var codes = Servers.enabledCodes({ type: "deeplx" })
        verify(codes.indexOf("fr") !== -1)
        verify(codes.indexOf("zh-TW") !== -1)
        verify(codes.indexOf("no") !== -1)
    }

    function test_translate_sendsAdapterRequest() {
        var log = []
        var result = null
        var s = Servers.newServer("libretranslate", "a")
        Servers.translate(s, req(), function(r) { result = r },
                          fakeTransport(200, '{"translatedText":"Hello"}', log))
        compare(log.length, 1)
        compare(log[0].url, "http://localhost:5000/translate")
        compare(result.text, "Hello")
    }

    function test_translate_passesServerToParser() {
        var result = null
        var s = Servers.newServer("custom", "a")
        s.url = "http://host/api"
        s.resultPath = "out"
        Servers.translate(s, req(), function(r) { result = r }, fakeTransport(200, '{"out":"Hi"}', []))
        compare(result.text, "Hi")
    }

    function test_translate_missingUrl() {
        var log = []
        var result = null
        var s = Servers.newServer("libretranslate", "a")
        s.url = "  "
        Servers.translate(s, req(), function(r) { result = r }, fakeTransport(200, "", log))
        compare(log.length, 0)
        compare(result.error, "config")
        compare(result.detail, "url")
    }

    function test_translate_adapterConfigError() {
        var log = []
        var result = null
        Servers.translate(Servers.newServer("deepl", "a"), req(), function(r) { result = r },
                          fakeTransport(200, "", log))
        compare(log.length, 0)
        compare(result.detail, "apikey")
    }

    function test_translate_abortAnswersOnce() {
        var calls = []
        var pending = null
        var aborted = false
        var transport = function(request, cb) {
            pending = cb
            return { abort: function() { aborted = true } }
        }
        var handle = Servers.translate(Servers.newServer("libretranslate", "a"), req(),
                                       function(r) { calls.push(r) }, transport)
        handle.abort("timeout")
        pending(0, "")
        verify(aborted)
        compare(calls.length, 1)
        compare(calls[0].error, "timeout")
    }

    function test_fetchLanguages_fromServer() {
        var result = null
        Servers.fetchLanguages(Servers.newServer("libretranslate", "a"), function(r) { result = r },
                               fakeTransport(200, '[{"code":"en"},{"code":"fr"}]', []))
        compare(result.codes, ["en", "fr"])
    }

    function test_fetchLanguages_notSupported() {
        var log = []
        var result = null
        Servers.fetchLanguages(Servers.newServer("openai", "a"), function(r) { result = r },
                               fakeTransport(200, "", log))
        compare(log.length, 0)
        compare(result.codes, null)
    }

    function test_fetchModels() {
        var result = null
        Servers.fetchModels(Servers.newServer("openai", "a"), function(r) { result = r },
                            fakeTransport(200, '{"data":[{"id":"m1"}]}', []))
        compare(result.models, ["m1"])
        Servers.fetchModels(Servers.newServer("deepl", "a"), function(r) { result = r },
                            fakeTransport(200, "", []))
        compare(result.models, [])
    }
}
