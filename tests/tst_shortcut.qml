import QtQuick
import QtTest
import "../contents/ui/shortcut.js" as Shortcut

TestCase {
    name: "Shortcut"

    function test_keyCode_data() {
        return [
            { tag: "empty", text: "", expected: 0 },
            { tag: "blank", text: "   ", expected: 0 },
            { tag: "letter", text: "T", expected: 0x54 },
            { tag: "letter lowercase", text: "t", expected: 0x54 },
            { tag: "meta t", text: "Meta+T", expected: 0x10000054 },
            { tag: "ctrl alt t", text: "Ctrl+Alt+T", expected: 0x0c000054 },
            { tag: "ctrl alt shift f1", text: "Ctrl+Alt+Shift+F1", expected: 0x0f000030 },
            { tag: "f12", text: "F12", expected: 0x0100003b },
            { tag: "escape", text: "Esc", expected: 0x01000000 },
            { tag: "meta space", text: "Meta+Space", expected: 0x10000020 },
            { tag: "ctrl plus", text: "Ctrl++", expected: 0x0400002b },
            { tag: "ctrl comma", text: "Ctrl+,", expected: 0x0400002c },
            { tag: "modifier only", text: "Meta", expected: 0x10000000 },
            { tag: "two modifiers", text: "Ctrl+Alt", expected: 0x0c000000 },
            { tag: "first chord", text: "Ctrl+Alt+T, Ctrl+B", expected: 0x0c000054 },
            { tag: "unknown", text: "NotAKey", expected: 0 },
            { tag: "unknown with modifier", text: "Ctrl+NotAKey", expected: 0 },
        ]
    }
    function test_keyCode(row) {
        compare(Shortcut.keyCode(row.text), row.expected)
    }

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

    function test_actionName_isPerApplet() {
        compare(Shortcut.actionName(42), "org.kde.plasma.translator.open.42")
        compare(Shortcut.actionName("7"), "org.kde.plasma.translator.open.7")
        // Not a number: still one safe token, never script text
        compare(Shortcut.actionName("1); evil("), "org.kde.plasma.translator.open.-1")
    }

    function test_plasmashellScript_bumpsThisApplet() {
        var script = Shortcut.plasmashellScript(42)
        verify(script.indexOf("var id = 42") !== -1)
        verify(script.indexOf("writeConfig(\"openRequest\"") !== -1)
        verify(script.indexOf("panels()") !== -1)
        verify(script.indexOf("desktops()") !== -1)
        // The system tray is its own containment, not a desktop
        verify(script.indexOf("activityIds") !== -1)
        verify(script.indexOf("widgetById(id)") !== -1)
    }

    function test_plasmashellScript_rejectsInjection() {
        var script = Shortcut.plasmashellScript("42); callDBus(")
        verify(script.indexOf("var id = -1") !== -1)
        verify(script.indexOf("callDBus(") === -1)
    }

    function test_kwinScript_registersAndEscapes() {
        var script = Shortcut.kwinScript(7, "Meta+T", "Say \"hi\"")
        verify(script.indexOf("registerShortcut(") === 0)
        verify(script.indexOf("\"org.kde.plasma.translator.open.7\"") !== -1)
        verify(script.indexOf("\"Meta+T\"") !== -1)
        verify(script.indexOf("Say \\\"hi\\\"") !== -1)
        verify(script.indexOf("evaluateScript") !== -1)
        verify(script.indexOf("var id = 7") !== -1)
    }

    function test_syncCommand_emptyUnloadsOnly() {
        var cmd = Shortcut.syncCommand(3, "", "Open Translator", "/tmp/open.js")
        verify(cmd.indexOf("unloadScript string:org.kde.plasma.translator.open.3") !== -1)
        compare(cmd.indexOf("setForeignShortcut"), -1)
        // "unloadScript" starts with "un" and then "loadScript"
        compare(cmd.indexOf("Scripting.loadScript"), -1)
    }

    function test_syncCommand_forcesTheKey() {
        var cmd = Shortcut.syncCommand(3, "Meta+T", "Open Translator", "/tmp/my open.js")
        verify(cmd.indexOf("unloadScript string:org.kde.plasma.translator.open.3") !== -1)
        verify(cmd.indexOf("Scripting.loadScript string:") !== -1)
        verify(cmd.indexOf("org.kde.KGlobalAccel.setForeignShortcut") !== -1)
        verify(cmd.indexOf("array:string:\"kwin\",\"org.kde.plasma.translator.open.3\",\"KWin\",\"Open Translator\"") !== -1)
        verify(cmd.indexOf("array:int32:" + 0x10000054) !== -1)
        // The path is one shell word, so the space cannot start a new command
        verify(cmd.indexOf("'/tmp/my open.js'") !== -1)
        verify(cmd.indexOf("registerShortcut(") !== -1)
    }

    function test_syncCommand_unknownShortcutUnloadsOnly() {
        var cmd = Shortcut.syncCommand(3, "Ctrl+NotAKey", "Open Translator", "/tmp/open.js")
        compare(cmd.indexOf("setForeignShortcut"), -1)
        compare(cmd.indexOf("Scripting.loadScript"), -1)
    }
}
