import QtQuick
import QtTest
import "../contents/ui/lang.js" as Lang

TestCase {
    name: "Lang"

    // Selection popup, text already in the popup's language. Native language is "fr".
    function test_otherTarget_data() {
        return [
            { tag: "popup on the native language", popup: "fr", favorite: "en", expected: "en" },
            { tag: "popup on another language", popup: "de", favorite: "en", expected: "fr" },
            { tag: "favorite is the native language", popup: "fr", favorite: "fr", expected: "fr" },
        ]
    }
    function test_otherTarget(row) {
        compare(Lang.otherTarget(row.popup, row.favorite, "fr"), row.expected)
    }

    // Outputs from TranslateGemma asked to translate into French
    function test_unchanged_data() {
        return [
            { tag: "french text reworded", text: "Il fait beau aujourd'hui, on pourrait aller se promener au bord du lac.",
              translation: "Il fait beau aujourd'hui, on pourrait faire une promenade au bord du lac.", expected: true },
            { tag: "french text untouched", text: "Merci !", translation: "Merci !", expected: true },
            { tag: "english text", text: "Thanks!", translation: "Merci !", expected: false },
            { tag: "german text", text: "Das Wetter ist heute schön, wir könnten am See spazieren gehen.",
              translation: "Il fait beau aujourd'hui, nous pourrions faire une promenade au bord du lac.", expected: false },
            { tag: "numbers and names kept", text: "Linux kernel 6.18 update",
              translation: "Mise à jour du noyau Linux 6.18", expected: false },
        ]
    }
    function test_unchanged(row) {
        compare(Lang.unchanged(row.text, row.translation), row.expected)
    }

    function test_systemCode_data() {
        return [
            { tag: "language only in the list", locale: "fr_FR", expected: "fr" },
            { tag: "language and country in the list", locale: "zh_TW", expected: "zh-TW" },
            { tag: "simplified chinese", locale: "zh_CN", expected: "zh-CN" },
            { tag: "norwegian bokmal", locale: "nb_NO", expected: "no" },
            { tag: "norwegian nynorsk", locale: "nn_NO", expected: "no" },
        ]
    }
    function test_systemCode(row) {
        var codes = ["en", "fr", "zh-CN", "zh-TW", "no", "sr-Cyrl"]
        compare(Lang.systemCode(row.locale, codes), row.expected)
    }

    // System in English, native language chosen in the settings or not
    function test_nativeCode_data() {
        return [
            { tag: "nothing chosen", chosen: "", expected: "en" },
            { tag: "chosen language", chosen: "ru", expected: "ru" },
        ]
    }
    function test_nativeCode(row) {
        compare(Lang.nativeCode(row.chosen, "en_US", ["en", "fr", "ru"]), row.expected)
    }

    // Output of trans -identify, which prints colors even when not in a terminal
    function test_identifiedCode_data() {
        return [
            { tag: "colors", expected: "ru", output:
                "\u001b[1mрусский\n\u001b[22mName                  \u001b[1mRussian\u001b[22m\n"
                + "Family                \u001b[1mIndo-European\u001b[22m\n"
                + "Code                  \u001b[1mru\u001b[22m\n"
                + "ISO 639-3             \u001b[1mrus\u001b[22m\n" },
            { tag: "no colors", expected: "zh-CN", output:
                "中文(简体)\nName                  Chinese (Simplified)\nCode                  zh-CN\n" },
            { tag: "nothing identified", expected: "", output: "" },
        ]
    }
    function test_identifiedCode(row) {
        compare(Lang.identifiedCode(row.output), row.expected)
    }

    // Auto destination, native language "ru", second language "en"
    function test_autoTarget_data() {
        return [
            { tag: "source unknown", source: "auto", expected: "ru" },
            { tag: "source is another language", source: "de", expected: "ru" },
            { tag: "source is the native language", source: "ru", expected: "en" },
        ]
    }
    function test_autoTarget(row) {
        compare(Lang.autoTarget(row.source, "ru", "en"), row.expected)
    }
}
