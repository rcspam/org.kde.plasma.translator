.pragma library

// Target for a selected text that is already in the popup's language: the
// favorite language when the popup is on the native language, else the
// native language.
function otherTarget(popupTarget, favorite, nativeTarget) {
    return popupTarget === nativeTarget ? favorite : nativeTarget
}

// Splits on spaces, digits and punctuation (QML's JavaScript has no \p{L}).
// Typographic quotes, dashes and CJK punctuation included.
var separators = /[\s0-9.,;:!?'"()\[\]{}<>\/\\|@#$%^&*+=_~`¡«»¿\u2013\u2014‘’“”…、。！（），：；？-]+/

function words(text) {
    return text.toLowerCase().split(separators).filter(function(w) { return w.length > 0 })
}

// True when a translation kept most words of the text: the text was already
// in the target language. Works with every engine, none has to report the
// language it detected. Measured with TranslateGemma into French: 79 to 100%
// of the words kept for French texts, none for English or German ones.
function unchanged(text, translation) {
    var source = words(text)
    if (source.length === 0) {
        return text.trim() === translation.trim()
    }
    var kept = {}
    words(translation).forEach(function(w) { kept[w] = true })
    var common = source.filter(function(w) { return kept[w] }).length
    return common / source.length >= 0.5
}

// Widget language code for a Qt locale name ("fr_FR", "zh_TW"…).
function systemCode(localeName, codes) {
    var full = localeName.replace("_", "-")
    if (codes.indexOf(full) !== -1) {
        return full
    }
    var lang = localeName.split("_")[0]
    // Norwegian is "no" in the widget, Bokmål and Nynorsk locales are nb and nn
    if (lang === "nb" || lang === "nn") {
        return "no"
    }
    return lang
}

// Native language: the one chosen in the settings, else the system language.
// The system language is not always the native one (English UI, language
// being learnt).
function nativeCode(chosen, localeName, codes) {
    return chosen || systemCode(localeName, codes)
}
