.pragma library

// "v6.1" gives [6, 1]. Missing parts count as 0, so "6.1" and "6.1.0" are
// equal: the store version field is hand-typed and rarely padded.
function parts(v) {
    return v.trim().replace(/^v/i, "").split(".").map(function(p) {
        return parseInt(p, 10) || 0
    })
}

// True when the store version is newer than the installed one. An older
// store version (the store API caches it for hours after a release) is not
// an update: installing it would downgrade the widget.
function isNewer(store, installed) {
    var a = parts(store)
    var b = parts(installed)
    for (var i = 0; i < Math.max(a.length, b.length); i++) {
        var x = a[i] || 0
        var y = b[i] || 0
        if (x !== y) {
            return x > y
        }
    }
    return false
}
