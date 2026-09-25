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
}
