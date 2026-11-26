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
