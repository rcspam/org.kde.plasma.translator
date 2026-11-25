.pragma library
.import "shell.js" as Shell

// KWin's KGlobalAccel component. kglobalshortcutsrc groups its shortcuts under
// this name, on X11 and on Wayland.
var kwinComponent = "kwin"

// One action per applet, so two widgets on the panel can have two shortcuts.
function actionName(appletId) {
    return "org.kde.plasma.translator.open." + numericId(appletId)
}

function numericId(appletId) {
    var id = Number(appletId)
    if (!isFinite(id)) {
        return -1
    }
    return Math.trunc(id)
}

// QKeySequence::toString() (portable text) as the integer KGlobalAccel stores.
// Empty, or a string Qt would not parse, is 0: nothing is registered.
function keyCode(text) {
    var raw = String(text || "").trim()
    if (!raw) {
        return 0
    }
    // A comma-space separates a chord ("Ctrl+K, Ctrl+T"). Only the first key
    // is a global shortcut. "Ctrl+," is a comma, and has no space after it.
    return chordCode(raw.split(", ")[0].trim())
}

function chordCode(chord) {
    if (!chord) {
        return 0
    }
    var mods = 0
    var rest = chord
    var prefixes = [
        ["ctrl+", 0x04000000],
        ["shift+", 0x02000000],
        ["alt+", 0x08000000],
        ["meta+", 0x10000000],
        ["num+", 0x20000000]
    ]
    var moved = true
    while (moved) {
        moved = false
        var lower = rest.toLowerCase()
        for (var i = 0; i < prefixes.length; i++) {
            if (lower.indexOf(prefixes[i][0]) === 0) {
                mods |= prefixes[i][1]
                rest = rest.slice(prefixes[i][0].length)
                moved = true
                break
            }
        }
    }
    rest = rest.trim()
    if (!rest) {
        return mods
    }
    var key = keyFromName(rest)
    if (!key) {
        return 0
    }
    return mods | key
}

function keyFromName(name) {
    var lower = name.toLowerCase()
    // Modifier-only shortcuts ("Meta", "Ctrl+Alt") are the modifier bits.
    var mods = { "ctrl": 0x04000000, "shift": 0x02000000, "alt": 0x08000000, "meta": 0x10000000, "num": 0x20000000 }
    if (mods[lower]) {
        return mods[lower]
    }
    var named = {
        "space": 0x20,
        "esc": 0x01000000,
        "tab": 0x01000001,
        "backtab": 0x01000002,
        "backspace": 0x01000003,
        "return": 0x01000004,
        "enter": 0x01000005,
        "ins": 0x01000006,
        "del": 0x01000007,
        "pause": 0x01000008,
        "print": 0x01000009,
        "sysreq": 0x0100000a,
        "home": 0x01000010,
        "end": 0x01000011,
        "left": 0x01000012,
        "up": 0x01000013,
        "right": 0x01000014,
        "down": 0x01000015,
        "pgup": 0x01000016,
        "pgdown": 0x01000017,
        "capslock": 0x01000024,
        "numlock": 0x01000025,
        "scrolllock": 0x01000026,
        "menu": 0x01000055,
        "help": 0x01000058
    }
    if (named[lower]) {
        return named[lower]
    }
    var fn = /^f([1-9]|[12][0-9]|3[0-5])$/.exec(lower)
    if (fn) {
        return 0x01000030 + Number(fn[1]) - 1
    }
    // Letters, digits and punctuation ("T", "+", ",") are their Latin-1 code,
    // which is also the Qt key code.
    if (name.length === 1) {
        var code = name.toUpperCase().charCodeAt(0)
        if (code > 0x20 && code < 0x7f) {
            return code
        }
    }
    return 0
}

// What KeySequenceItem gives back. QKeySequence::toString() is portable text.
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

// Runs inside plasmashell. Bumps this applet's openRequest, which the widget
// watches. Panels and desktops first; then every containment id, so a widget
// kept in the system tray (its own containment, not a desktop) is found too.
function plasmashellScript(appletId) {
    var id = numericId(appletId)
    return "(function() {\n"
        + "    var id = " + id + "\n"
        + "    function bump(w) {\n"
        + "        if (!w || !w.writeConfig || Number(w.id) !== id) return false\n"
        + "        var n = Number(w.readConfig(\"openRequest\", 0)) || 0\n"
        + "        if (n >= 1000000000) n = 0\n"
        + "        w.writeConfig(\"openRequest\", n + 1)\n"
        + "        return true\n"
        + "    }\n"
        + "    function consider(c) {\n"
        + "        if (!c || !c.widgetById) return false\n"
        + "        return bump(c.widgetById(id))\n"
        + "    }\n"
        + "    function walk(list) {\n"
        + "        if (!list) return false\n"
        + "        for (var i = 0; i < list.length; i++) {\n"
        + "            if (consider(list[i])) return true\n"
        + "        }\n"
        + "        return false\n"
        + "    }\n"
        + "    if (typeof panels === \"function\" && walk(panels())) return\n"
        + "    if (typeof desktops === \"function\" && walk(desktops())) return\n"
        + "    var ids = []\n"
        + "    function append(list) {\n"
        + "        if (!list) return\n"
        + "        for (var i = 0; i < list.length; i++) ids.push(list[i])\n"
        + "    }\n"
        + "    if (typeof panelIds !== \"undefined\") append(panelIds)\n"
        + "    if (typeof activityIds !== \"undefined\") append(activityIds)\n"
        + "    for (var i = 0; i < ids.length; i++) {\n"
        + "        var c = null\n"
        + "        if (typeof panelById === \"function\") c = panelById(ids[i])\n"
        + "        if (!c || !c.widgetById) {\n"
        + "            c = typeof desktopById === \"function\" ? desktopById(ids[i]) : null\n"
        + "        }\n"
        + "        if (consider(c)) return\n"
        + "    }\n"
        + "})()\n"
}

function kwinScript(appletId, shortcutText, label) {
    var name = actionName(appletId)
    var text = label || "Open Translator"
    return "registerShortcut(" + JSON.stringify(name) + ", " + JSON.stringify(text) + ", "
        + JSON.stringify(String(shortcutText || "")) + ", function() {\n"
        + "    callDBus(\"org.kde.plasmashell\", \"/PlasmaShell\", \"org.kde.PlasmaShell\", \"evaluateScript\", "
        + JSON.stringify(plasmashellScript(appletId)) + ")\n"
        + "})\n"
}

// Unloads the shortcut, and when one is set, loads a KWin script that
// registers it and then forces that key. registerShortcut keeps a key the
// user already had (KGlobalAccel autoloads it), so a change in the widget
// settings would not apply without setForeignShortcut.
function syncCommand(appletId, shortcutText, label, scriptFile) {
    var name = actionName(appletId)
    var kwin = "dbus-send --session --print-reply --dest=org.kde.KWin /Scripting org.kde.kwin.Scripting."
    var cmd = kwin + "unloadScript string:" + name + " >/dev/null 2>&1"
    var code = keyCode(shortcutText)
    if (!code) {
        return cmd
    }
    var script = kwinScript(appletId, shortcutText, label)
    cmd += "; printf '%s' " + Shell.quote(script) + " > " + Shell.quote(scriptFile)
        + " && " + kwin + "loadScript string:" + Shell.quote(scriptFile) + " string:" + name + " >/dev/null"
        + " && " + kwin + "start >/dev/null"
        + " && dbus-send --session --print-reply --dest=org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.setForeignShortcut"
        + " array:string:\"" + kwinComponent + "\",\"" + name + "\",\"KWin\",\"Open Translator\""
        + " array:int32:" + (code | 0)
    return cmd
}
