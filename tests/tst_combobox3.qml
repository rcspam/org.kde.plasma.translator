import QtQuick
import QtTest
import "../contents/ui"

Item {
    width: 400
    height: 100

    ComboBox3 {
        id: combo
        editable: true
        width: 120
    }

    TestCase {
        name: "ComboBox3"
        when: windowShown

        // A name wider than the box shows its start, not its end
        function test_longNameShowsItsStart() {
            combo.model = ["Auto (Russian / English)", "English"]
            combo.currentIndex = 0
            compare(combo.contentItem.cursorPosition, 0)
        }
    }
}
