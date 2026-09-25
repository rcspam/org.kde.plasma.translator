.pragma library

// Quotes text as a single shell word. Inside single quotes the shell expands
// nothing, so only the quote itself needs escaping: ' becomes '\''
function quote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'"
}
