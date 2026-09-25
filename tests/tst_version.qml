import QtQuick
import QtTest
import "../contents/ui/version.js" as Version

TestCase {
    name: "Version"

    function test_isNewer_data() {
        return [
            { tag: "older store version", store: "6.0.1", installed: "6.1.0", expected: false },
            { tag: "newer store version", store: "6.1.0", installed: "6.0.1", expected: true },
            { tag: "same version", store: "6.1.0", installed: "6.1.0", expected: false },
            { tag: "store version not padded", store: "6.1", installed: "6.1.0", expected: false },
            { tag: "installed version not padded", store: "6.1.0", installed: "6.1", expected: false },
            { tag: "v prefix and spaces", store: " v6.2 ", installed: "6.1.0", expected: true },
            { tag: "numeric order", store: "6.10.0", installed: "6.9.0", expected: true },
            { tag: "installed version unknown", store: "6.1.0", installed: "", expected: true },
        ]
    }
    function test_isNewer(row) {
        compare(Version.isNewer(row.store, row.installed), row.expected)
    }
}
