import QtQuick
import QtTest
import "../contents/ui/shell.js" as Shell

TestCase {
    name: "Shell"

    function test_quote_data() {
        return [
            { tag: "plain", text: "Hello world", expected: "'Hello world'" },
            { tag: "empty", text: "", expected: "''" },
            { tag: "single quote", text: "it's", expected: "'it'\\''s'" },
            { tag: "command substitution", text: "$(rm -rf ~)", expected: "'$(rm -rf ~)'" },
            { tag: "backticks", text: "a `id` b `id`", expected: "'a `id` b `id`'" },
            { tag: "double quotes and backslash", text: 'say "hi" \\n', expected: "'say \"hi\" \\n'" },
            { tag: "newline", text: "line 1\nline 2", expected: "'line 1\nline 2'" },
        ]
    }
    function test_quote(row) {
        compare(Shell.quote(row.text), row.expected)
    }

    function test_transCommand_brief() {
        compare(Shell.transCommand("hello", "", "ru", "google", false),
                "trans :ru -brief -no-bidi -e google -- 'hello'")
    }

    function test_transCommand_lookup() {
        compare(Shell.transCommand("привет", "ru", "en", "bing", true),
                "trans ru:en -no-ansi -no-bidi -no-warn -w " + Shell.lookupWidth
                + " -e bing -- 'привет'")
    }

    function test_transCommand_quotesText() {
        compare(Shell.transCommand("it's", "en", "fr", "yandex", false),
                "trans en:fr -brief -no-bidi -e yandex -- 'it'\\''s'")
    }

    function test_transCommand_dashIsNotAnOption() {
        compare(Shell.transCommand("-n", "", "en", "google", true),
                "trans :en -no-ansi -no-bidi -no-warn -w " + Shell.lookupWidth
                + " -e google -- '-n'")
    }
}
