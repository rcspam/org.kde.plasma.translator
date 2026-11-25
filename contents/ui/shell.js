.pragma library

// Quotes text as a single shell word. Inside single quotes the shell expands
// nothing, so only the quote itself needs escaping: ' becomes '\''
function quote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'"
}

// Screen width for a dictionary page. Plasma does not set COLUMNS, and
// translate-shell then uses width 0. Wide enough that definitions stay one
// line; the text field wraps them.
var lookupWidth = 72

// translate-shell command. A lookup omits -brief, so the page has pronunciation,
// definitions and alternatives. -dictionary is not used: it hides those.
function transCommand(text, from, target, engine, lookup) {
    var flags = lookup
            ? "-no-ansi -no-bidi -no-warn -w " + lookupWidth
            : "-brief -no-bidi"
    return "trans " + (from ? from : "") + ":" + target + " " + flags
            + " -e " + engine + " -- " + quote(text)
}
