import QtQuick
import QtTest
import "../contents/ui/lang.js" as Lang

TestCase {
    name: "Lang"

    // Selection popup, text already in the popup's language. System language is "fr".
    function test_otherTarget_data() {
        return [
            { tag: "popup on the system language", popup: "fr", favorite: "en", expected: "en" },
            { tag: "popup on another language", popup: "de", favorite: "en", expected: "fr" },
            { tag: "favorite is the system language", popup: "fr", favorite: "fr", expected: "fr" },
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
}
