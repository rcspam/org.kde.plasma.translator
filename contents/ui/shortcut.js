.pragma library
.import "shell.js" as Shell

// Plasma gives a widget one global shortcut, Plasmoid.globalShortcut. This
// file registers a second one with KWin. When it is pressed, KWin asks
// plasmashell to bump selectionRequest. plasmoidviewer is a different
// process, so that key does nothing there.

function numericId(appletId) {
    var id = Number(appletId)
    return isFinite(id) ? Math.trunc(id) : -1
}

function scriptName(appletId) {
    return "org.kde.plasma.translator.selection." + numericId(appletId)
}

function legacyScriptName(appletId) {
    return "org.kde.plasma.translator.open." + numericId(appletId)
}

// registerShortcut keeps a key it already saved for an action id, so a new
// key needs a new id or the old one stays.
function actionName(appletId, shortcutText) {
    var token = String(shortcutText || "").replace(/[^a-zA-Z0-9]/g, "_")
    return scriptName(appletId) + "." + (token || "none")
}

// KeySequenceItem's value. QKeySequence::toString() is portable text, which
// KWin's registerShortcut accepts.
function sequenceText(sequence) {
    if (typeof sequence === "string") {
        return sequence
    }
    if (!sequence || !sequence.toString) {
        return ""
    }
    try {
        var text = sequence.toString()
        return typeof text === "string" && text !== "[object Object]" ? text : ""
    } catch (e) {
        return ""
    }
}

// Runs inside plasmashell. A tray applet lives in the tray's containment.
function plasmashellScript(appletId) {
    var id = numericId(appletId)
    return `(function () {
var id = ${id}
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
}

function kwinScript(appletId, shortcutText, label) {
    return "registerShortcut(" + JSON.stringify(actionName(appletId, shortcutText)) + ", "
        + JSON.stringify(label || "Translate the selection") + ", "
        + JSON.stringify(String(shortcutText || "")) + ", function () {\n"
        + "    callDBus('org.kde.plasmashell', '/PlasmaShell', 'org.kde.PlasmaShell', 'evaluateScript', "
        + JSON.stringify(plasmashellScript(appletId)) + ")\n"
        + "})\n"
}

function dropCommand(name) {
    var off = "dbus-send --session --print-reply --dest=org.kde.kglobalaccel /kglobalaccel "
        + "org.kde.KGlobalAccel.unregister string:"
    var unload = "dbus-send --session --print-reply --dest=org.kde.KWin /Scripting "
        + "org.kde.kwin.Scripting.unloadScript string:" + name + " >/dev/null 2>&1"
    return off + "kwin string:" + name + " >/dev/null 2>&1; "
        + off + "kwin_wayland string:" + name + " >/dev/null 2>&1; " + unload
}

// unloadScript only schedules deletion. Loading that name again in the same
// command is ignored, and start() will not run a script that is still running.
function syncCommand(appletId, shortcutText, label, scriptFile, previousName) {
    var text = String(shortcutText || "").trim()
    var next = text ? actionName(appletId, text) : ""
    var names = [legacyScriptName(appletId), scriptName(appletId), previousName || "", next]
    var seen = {}
    var parts = []
    for (var i = 0; i < names.length; i++) {
        if (!names[i] || seen[names[i]]) {
            continue
        }
        seen[names[i]] = true
        parts.push(dropCommand(names[i]))
    }
    // KWin deletes the old script on its next event-loop turn.
    parts.push("sleep 0.3")
    if (next) {
        var kwin = "dbus-send --session --print-reply --dest=org.kde.KWin /Scripting org.kde.kwin.Scripting."
        parts.push("printf '%s' " + Shell.quote(kwinScript(appletId, text, label)) + " > " + Shell.quote(scriptFile)
            + " && " + kwin + "loadScript string:" + Shell.quote(scriptFile) + " string:" + next + " >/dev/null"
            + " && " + kwin + "start >/dev/null")
    }
    return parts.join("; ")
}
