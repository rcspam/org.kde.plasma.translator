.pragma library

// Window a selection shortcut should update. openNew keeps every visible
// window and recycles a closed one; otherwise the visible window is updated,
// or a closed one when nothing is on screen. Null means the caller creates
// a window. A preferred window (the one whose Destination menu changed) is
// chosen by the caller and never passed here.
function windowToReuse(windows, openNew) {
    var hidden = null
    for (var i = 0; i < windows.length; i++) {
        var win = windows[i]
        if (!win)
            continue
        if (win.visible) {
            if (!openNew)
                return win
        } else if (hidden === null) {
            hidden = win
        }
    }
    return hidden
}

// A result is shown only for the request that window is still waiting on.
// Closing the window sets its id back to 0, so a translation that finishes
// afterwards is dropped without touching any other window. The next request
// uses a new id, so the closed one cannot match a window that was shown again.
function acceptsResult(windowRequestId, request) {
    return request !== 0 && windowRequestId === request
}
