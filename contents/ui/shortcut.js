.pragma library
.import "shell.js" as Shell

// KWin's registerShortcut is the API that can own a second global shortcut.
// Plasmashell itself only has Plasmoid.globalShortcut. There is no QML type
// for another one, so the widget asks KWin to register it and to tell
// plasmashell when the key is pressed.

function numericId(appletId) {
    var id = Number(appletId)
    if (!isFinite(id)) {
        return -1
    }
    return Math.trunc(id)
}

// Stable script name. Unloading it drops the previous KWin action.
function scriptName(appletId) {
    return "org.kde.plasma.translator.selection." + numericId(appletId)
}

function legacyScriptName(appletId) {
    return "org.kde.plasma.translator.open." + numericId(appletId)
}

// A new action id whenever the key changes. registerShortcut autoloads a key
// it already saved for an action, so reusing the id would ignore the new one.
function actionName(appletId, shortcutText) {
    var raw = String(shortcutText || "")
    var token = ""
    for (var i = 0; i < raw.length; i++) {
        var c = raw.charAt(i)
        var ok = (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9")
        token += ok ? c : "_"
    }
    return scriptName(appletId) + "." + (token || "none")
}

// What KeySequenceItem gives back. QKeySequence::toString() is portable text,
// which KWin's registerShortcut also accepts.
function sequenceText(sequence) {
    if (sequence === undefined || sequence === null) {
        return ""
    }
    if (typeof sequence === "string") {
        return sequence
    }
    try {
        if (typeof sequence.toString === "function") {
            var text = sequence.toString()
            if (typeof text === "string" && text !== "[object Object]") {
                return text
            }
        }
    } catch (e) {
    }
    return ""
}

// Runs inside plasmashell. Bumps this applet's selectionRequest. widgets() is
// the scripting API for the widgets in a panel or desktop. A system tray
// applet lives in the tray's own containment.
function plasmashellScript(appletId) {
    var id = numericId(appletId)
    return "(function() {\n"
        + "var id = " + id + "\n"
        + "function bump(w) {\n"
        + "  if (!w || !w.writeConfig || Number(w.id) !== id) return false\n"
        + "  w.currentConfigGroup = ['General']\n"
        + "  var n = Number(w.readConfig('selectionRequest', 0)) || 0\n"
        + "  if (n >= 1000000000) n = 0\n"
        + "  w.writeConfig('selectionRequest', n + 1)\n"
        + "  return true\n"
        + "}\n"
        + "function scan(c) {\n"
        + "  if (!c || !c.widgets) return false\n"
        + "  var mine = c.widgets('org.kde.plasma.translator') || []\n"
        + "  for (var i = 0; i < mine.length; i++) if (bump(mine[i])) return true\n"
        + "  var trays = c.widgets('org.kde.plasma.systemtray') || []\n"
        + "  for (var j = 0; j < trays.length; j++) {\n"
        + "    var trayId = Number(trays[j].readConfig('SystrayContainmentId'))\n"
        + "    if (trayId && typeof desktopById === 'function' && scan(desktopById(trayId))) return true\n"
        + "  }\n"
        + "  return false\n"
        + "}\n"
        + "var list = []\n"
        + "if (typeof panels === 'function' && panels()) list = list.concat(panels())\n"
        + "if (typeof desktops === 'function' && desktops()) list = list.concat(desktops())\n"
        + "for (var i = 0; i < list.length; i++) if (scan(list[i])) return\n"
        + "})()\n"
}

function kwinScript(appletId, shortcutText, label) {
    var text = label || "Translate the selection"
    return "registerShortcut(" + JSON.stringify(actionName(appletId, shortcutText)) + ", "
        + JSON.stringify(text) + ", " + JSON.stringify(String(shortcutText || "")) + ", function() {\n"
        + "    callDBus(\"org.kde.plasmashell\", \"/PlasmaShell\", \"org.kde.PlasmaShell\", \"evaluateScript\", "
        + JSON.stringify(plasmashellScript(appletId)) + ")\n"
        + "})\n"
}

function unregisterCommand(component, action) {
    return "dbus-send --session --print-reply --dest=org.kde.kglobalaccel /kglobalaccel "
        + "org.kde.KGlobalAccel.unregister string:" + component + " string:" + action + " >/dev/null 2>&1"
}

// unloadScript only schedules deletion. Loading the same name in the next
// command is ignored, and start() will not run a script that is already
// running, so a changed shortcut never replaced the previous one.
function syncCommand(appletId, shortcutText, label, scriptFile, previousName) {
    var text = String(shortcutText || "").trim()
    var next = text ? actionName(appletId, text) : ""
    var names = [legacyScriptName(appletId), scriptName(appletId)]
    if (previousName && names.indexOf(previousName) < 0) {
        names.push(previousName)
    }
    if (next && names.indexOf(next) < 0) {
        names.push(next)
    }
    var kwin = "dbus-send --session --print-reply --dest=org.kde.KWin /Scripting org.kde.kwin.Scripting."
    var parts = []
    for (var i = 0; i < names.length; i++) {
        parts.push(unregisterCommand("kwin", names[i]))
        parts.push(unregisterCommand("kwin_wayland", names[i]))
        parts.push(kwin + "unloadScript string:" + names[i] + " >/dev/null 2>&1")
    }
    // KWin deletes the old script on its next event-loop turn.
    parts.push("sleep 0.3")
    if (next) {
        parts.push("printf '%s' " + Shell.quote(kwinScript(appletId, text, label)) + " > " + Shell.quote(scriptFile)
            + " && " + kwin + "loadScript string:" + Shell.quote(scriptFile) + " string:" + next + " >/dev/null"
            + " && " + kwin + "start >/dev/null")
    }
    return parts.join("; ")
}

// One-time swap. The Shortcuts page used to translate the selection; it now
// opens the widget, and the selection shortcut lives in the widget's own
// config. globalShortcut is null when the Shortcuts page must be left as it is.
function migratedShortcuts(state) {
    var saved = sequenceText(state.selectionShortcut).trim()
    if (state.migrated) {
        return { selectionShortcut: saved, globalShortcut: null }
    }
    var globalText = sequenceText(state.globalShortcut).trim()
    var legacy = sequenceText(state.legacyOpenShortcut).trim()
    var selection = saved || globalText
    var nextGlobal = legacy
    // One key cannot both open the widget and translate. The key that used to
    // sit on the Shortcuts page keeps translating.
    if (nextGlobal && nextGlobal === selection && !saved) {
        nextGlobal = ""
    }
    return {
        selectionShortcut: selection,
        globalShortcut: nextGlobal === globalText ? null : nextGlobal
    }
}
