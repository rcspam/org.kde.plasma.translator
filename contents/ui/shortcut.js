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

// Runs inside plasmashell. Bumps this applet's selectionRequest. Panels and
// desktops first, then a system tray containment, which is not a desktop.
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
        + "function consider(c) {\n"
        + "  if (!c || !c.widgetById) return false\n"
        + "  if (bump(c.widgetById(id))) return true\n"
        + "  var ids = c.widgetIds || []\n"
        + "  for (var i = 0; i < ids.length; i++) {\n"
        + "    var child = c.widgetById(ids[i])\n"
        + "    if (!child || child.type !== 'org.kde.plasma.systemtray') continue\n"
        + "    var trayId = Number(child.readConfig('SystrayContainmentId'))\n"
        + "    if (trayId && typeof desktopById === 'function' && consider(desktopById(trayId))) return true\n"
        + "  }\n"
        + "  return false\n"
        + "}\n"
        + "var list = []\n"
        + "if (typeof panels === 'function' && panels()) list = list.concat(panels())\n"
        + "if (typeof desktops === 'function' && desktops()) list = list.concat(desktops())\n"
        + "for (var i = 0; i < list.length; i++) if (consider(list[i])) return\n"
        + "function walk(ids, byId) {\n"
        + "  if (!ids || typeof byId !== 'function') return false\n"
        + "  for (var i = 0; i < ids.length; i++) if (consider(byId(ids[i]))) return true\n"
        + "  return false\n"
        + "}\n"
        + "if (typeof panelIds !== 'undefined' && walk(panelIds, panelById)) return\n"
        + "if (typeof activityIds !== 'undefined' && walk(activityIds, desktopById)) return\n"
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

// Drops shortcuts registered by earlier revisions, then lets KWin register the
// current one. KWin parses the key text itself.
function syncCommand(appletId, shortcutText, label, scriptFile) {
    var script = scriptName(appletId)
    var legacy = legacyScriptName(appletId)
    var kwin = "dbus-send --session --print-reply --dest=org.kde.KWin /Scripting org.kde.kwin.Scripting."
    var cmd = unregisterCommand("kwin", script)
        + "; " + unregisterCommand("kwin", legacy)
        + "; " + unregisterCommand("kwin_wayland", script)
        + "; " + unregisterCommand("kwin_wayland", legacy)
        + "; " + kwin + "unloadScript string:" + legacy + " >/dev/null 2>&1"
        + "; " + kwin + "unloadScript string:" + script + " >/dev/null 2>&1"
    var text = String(shortcutText || "").trim()
    if (!text) {
        return cmd
    }
    cmd += "; printf '%s' " + Shell.quote(kwinScript(appletId, text, label)) + " > " + Shell.quote(scriptFile)
        + " && " + kwin + "loadScript string:" + Shell.quote(scriptFile) + " string:" + script + " >/dev/null"
        + " && " + kwin + "start >/dev/null"
    return cmd
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
