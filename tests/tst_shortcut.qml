import QtQuick
import QtTest
import "../contents/ui/shortcut.js" as Shortcut
import "../contents/ui/migrate.js" as Migrate

TestCase {
    name: "Shortcut"

    function test_sequenceText_data() {
        return [
            { tag: "string", sequence: "Meta+T", expected: "Meta+T" },
            { tag: "empty string", sequence: "", expected: "" },
            { tag: "null", sequence: null, expected: "" },
            { tag: "key sequence", sequence: { toString: function() { return "Ctrl+Alt+T" } }, expected: "Ctrl+Alt+T" },
            { tag: "object without a sequence", sequence: {}, expected: "" },
        ]
    }
    function test_sequenceText(row) {
        compare(Shortcut.sequenceText(row.sequence), row.expected)
    }

    function test_actionName_changesWithTheKey() {
        compare(Shortcut.scriptName(42), "org.kde.plasma.translator.selection.42")
        compare(Shortcut.legacyScriptName(42), "org.kde.plasma.translator.open.42")
        compare(Shortcut.actionName(42, "Meta+T"), "org.kde.plasma.translator.selection.42.Meta_T")
        compare(Shortcut.actionName(42, "Ctrl+Alt+T"), "org.kde.plasma.translator.selection.42.Ctrl_Alt_T")
        verify(Shortcut.actionName(42, "Meta+T") !== Shortcut.actionName(42, "Meta+Y"))
        // Not a number: still one safe token, never script text
        compare(Shortcut.scriptName("1); evil("), "org.kde.plasma.translator.selection.-1")
    }

    function test_plasmashellScript_bumpsThisApplet() {
        var script = Shortcut.plasmashellScript(42)
        verify(script.indexOf("var id = 42") !== -1)
        verify(script.indexOf("writeConfig('selectionRequest'") !== -1)
        verify(script.indexOf("currentConfigGroup = ['General']") !== -1)
        verify(script.indexOf("panels()") !== -1)
        verify(script.indexOf("widgets('org.kde.plasma.translator')") !== -1)
        verify(script.indexOf("widgets('org.kde.plasma.systemtray')") !== -1)
    }

    function test_plasmashellScript_rejectsInjection() {
        var script = Shortcut.plasmashellScript("42); callDBus(")
        verify(script.indexOf("var id = -1") !== -1)
        verify(script.indexOf("callDBus(") === -1)
    }

    function test_kwinScript_registersAndEscapes() {
        var script = Shortcut.kwinScript(7, "Meta+T", "Say \"hi\"")
        verify(script.indexOf("registerShortcut(") === 0)
        verify(script.indexOf("\"org.kde.plasma.translator.selection.7.Meta_T\"") !== -1)
        verify(script.indexOf("\"Meta+T\"") !== -1)
        verify(script.indexOf("Say \\\"hi\\\"") !== -1)
        verify(script.indexOf("evaluateScript") !== -1)
        verify(script.indexOf("var id = 7") !== -1)
        compare(script.indexOf("setForeignShortcut"), -1)
    }

    function test_syncCommand_emptyUnloadsOnly() {
        var cmd = Shortcut.syncCommand(3, "", "Translate the selection", "/tmp/open.js",
                                       "org.kde.plasma.translator.selection.3.Meta_Y")
        verify(cmd.indexOf("unregister string:kwin string:org.kde.plasma.translator.selection.3") !== -1)
        verify(cmd.indexOf("unloadScript string:org.kde.plasma.translator.selection.3.Meta_Y") !== -1)
        verify(cmd.indexOf("sleep 0.3") !== -1)
        compare(cmd.indexOf("setForeignShortcut"), -1)
        compare(cmd.indexOf("Scripting.loadScript"), -1)
    }

    function test_syncCommand_letsKWinParseTheKey() {
        var cmd = Shortcut.syncCommand(3, "Meta+T", "Translate the selection", "/tmp/my open.js",
                                       "org.kde.plasma.translator.selection.3")
        verify(cmd.indexOf("unloadScript string:org.kde.plasma.translator.selection.3") !== -1)
        verify(cmd.indexOf("sleep 0.3") !== -1)
        var loadAt = cmd.indexOf("Scripting.loadScript string:")
        verify(loadAt > cmd.indexOf("sleep 0.3"))
        verify(cmd.indexOf("string:org.kde.plasma.translator.selection.3.Meta_T") !== -1)
        verify(cmd.indexOf("registerShortcut(") !== -1)
        verify(cmd.indexOf("\"Meta+T\"") !== -1)
        compare(cmd.indexOf("setForeignShortcut"), -1)
        verify(cmd.indexOf("'/tmp/my open.js'") !== -1)
    }

    function test_migratedShortcuts_data() {
        return [
            { tag: "upgrade keeps the shortcuts page key",
              state: { migrated: false, selectionShortcut: "", legacyOpenShortcut: "", globalShortcut: "Meta+T" },
              selection: "Meta+T", global: "" },
            { tag: "previous open shortcut moves to the shortcuts page",
              state: { migrated: false, selectionShortcut: "", legacyOpenShortcut: "Meta+O", globalShortcut: "Meta+T" },
              selection: "Meta+T", global: "Meta+O" },
            { tag: "only an open shortcut was set",
              state: { migrated: false, selectionShortcut: "", legacyOpenShortcut: "Meta+O", globalShortcut: "" },
              selection: "", global: "Meta+O" },
            { tag: "fresh install leaves the shortcuts page alone",
              state: { migrated: false, selectionShortcut: "", legacyOpenShortcut: "", globalShortcut: "" },
              selection: "", global: null },
            { tag: "the same key keeps translating",
              state: { migrated: false, selectionShortcut: "", legacyOpenShortcut: "Meta+T", globalShortcut: "Meta+T" },
              selection: "Meta+T", global: "" },
            { tag: "already migrated",
              state: { migrated: true, selectionShortcut: "Ctrl+Alt+T", legacyOpenShortcut: "Meta+O", globalShortcut: "Meta+Space" },
              selection: "Ctrl+Alt+T", global: null },
            { tag: "key sequence object",
              state: { migrated: false, selectionShortcut: "", legacyOpenShortcut: "", globalShortcut: { toString: function() { return "Ctrl+Alt+T" } } },
              selection: "Ctrl+Alt+T", global: "" }
        ]
    }
    function test_migratedShortcuts(row) {
        var plan = Migrate.migratedShortcuts(row.state)
        compare(plan.selectionShortcut, row.selection)
        compare(plan.globalShortcut, row.global)
    }
}
