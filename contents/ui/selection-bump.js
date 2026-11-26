.pragma library

// Evaluated by plasmashell when the selection shortcut is pressed. __ID__ is
// replaced with this applet's id. A tray applet lives in the tray containment.
var source = `(function () {
var id = __ID__
function bump(w) {
    if (!w || Number(w.id) !== id || !w.writeConfig) return false
    w.currentConfigGroup = ['General']
    var n = Number(w.readConfig('selectionRequest', 0)) || 0
    w.writeConfig('selectionRequest', n < 1000000000 ? n + 1 : 1)
    return true
}
function scan(c) {
    if (!c || !c.widgets) return false
    var mine = c.widgets('org.kde.plasma.translator') || []
    for (var i = 0; i < mine.length; i++) if (bump(mine[i])) return true
    var trays = c.widgets('org.kde.plasma.systemtray') || []
    for (var j = 0; j < trays.length; j++) {
        var trayId = Number(trays[j].readConfig('SystrayContainmentId'))
        if (trayId && scan(desktopById(trayId))) return true
    }
    return false
}
function walk(items) {
    for (var i = 0; items && i < items.length; i++) if (scan(items[i])) return true
}
walk(panels()) || walk(desktops())
})()
`
