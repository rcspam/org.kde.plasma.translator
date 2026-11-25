import QtQuick
import QtTest
import "../contents/ui/selection.js" as Selection

TestCase {
    name: "Selection"

    function test_windowToReuse_data() {
        return [
            { tag: "bring forward uses the visible window", openNew: false,
              windows: [{ visible: false, name: "hidden" }, { visible: true, name: "visible" }],
              expected: "visible" },
            { tag: "new window leaves the visible one", openNew: true,
              windows: [{ visible: true, name: "visible" }],
              expected: "" },
            { tag: "new window recycles a hidden window", openNew: true,
              windows: [{ visible: true, name: "visible" }, { visible: false, name: "hidden" }],
              expected: "hidden" },
            { tag: "bring forward recycles a hidden window", openNew: false,
              windows: [{ visible: false, name: "hidden" }],
              expected: "hidden" },
            { tag: "nothing pooled", openNew: false, windows: [], expected: "" },
            { tag: "holes in the pool are skipped", openNew: false,
              windows: [null, { visible: true, name: "visible" }],
              expected: "visible" },
        ]
    }
    function test_windowToReuse(row) {
        var found = Selection.windowToReuse(row.windows, row.openNew)
        compare(found ? found.name : "", row.expected)
    }

    function test_acceptsResult_data() {
        return [
            { tag: "current request", windowRequestId: 2, request: 2, expected: true },
            { tag: "stale request", windowRequestId: 2, request: 1, expected: false },
            { tag: "window closed", windowRequestId: 0, request: 2, expected: false },
            { tag: "both idle", windowRequestId: 0, request: 0, expected: false },
        ]
    }
    function test_acceptsResult(row) {
        compare(Selection.acceptsResult(row.windowRequestId, row.request), row.expected)
    }
}
