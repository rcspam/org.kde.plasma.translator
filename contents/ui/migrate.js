.pragma library
.import "shortcut.js" as Shortcut

// One-time swap from older builds of this widget. The Shortcuts page used to
// translate the selection and now opens the widget. globalShortcut is null
// when that page must be left as it is.
function migratedShortcuts(state) {
    var saved = Shortcut.sequenceText(state.selectionShortcut).trim()
    if (state.migrated) {
        return { selectionShortcut: saved, globalShortcut: null }
    }
    var globalText = Shortcut.sequenceText(state.globalShortcut).trim()
    var legacy = Shortcut.sequenceText(state.legacyOpenShortcut).trim()
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

// Writes the one-time swap into the applet. plasmoid.globalShortcut is the
// Shortcuts page key.
function apply(plasmoid) {
    var config = plasmoid.configuration
    if (config.selectionShortcutMigrated) {
        return
    }
    var plan = migratedShortcuts({
        migrated: false,
        selectionShortcut: config.selectionShortcut,
        legacyOpenShortcut: config.openShortcut,
        globalShortcut: plasmoid.globalShortcut
    })
    if ((config.selectionShortcut || "") !== plan.selectionShortcut) {
        config.selectionShortcut = plan.selectionShortcut
    }
    if (plan.globalShortcut !== null) {
        plasmoid.globalShortcut = plan.globalShortcut
    }
    config.selectionShortcutMigrated = true
    if (config.openShortcut) {
        config.openShortcut = ""
    }
}
