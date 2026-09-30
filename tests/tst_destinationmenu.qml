import QtQuick
import QtTest
import "../contents/ui"

Item {
    id: widget
    width: 400
    height: 400

    // Plays the widget's part: keeps what the user picks, -1 for Auto
    property int languageIndex: 1
    property var languages: []
    property string autoLabel: ""

    DestinationMenu {
        id: menu
        width: 250
        languages: widget.languages
        autoLabel: widget.autoLabel
        languageIndex: widget.languageIndex
        onChosen: function(index) {
            widget.languageIndex = index
        }
    }

    TestCase {
        name: "DestinationMenu"
        when: windowShown

        function init() {
            widget.languageIndex = 1
            widget.languages = ["English", "French", "Russian"]
            widget.autoLabel = "Auto (Russian / English)"
        }

        // The Plasma style wraps the popup's list view
        function listView(item) {
            if (item.itemAtIndex !== undefined) {
                return item
            }
            for (var i = 0; i < item.children.length; i++) {
                var found = listView(item.children[i])
                if (found) {
                    return found
                }
            }
            return null
        }

        function pick(index) {
            menu.popup.open()
            tryCompare(menu.popup, "opened", true)
            var view = listView(menu.popup.contentItem)
            verify(view, "list of the menu")
            tryVerify(function() { return view.itemAtIndex(index) !== null }, 2000, "menu entry " + index)
            var item = view.itemAtIndex(index)
            mouseClick(item)
            tryCompare(menu.popup, "visible", false)
        }

        function test_showsTheChosenLanguage() {
            compare(menu.currentText, "French")
        }

        function test_autoIsTheFirstEntry() {
            widget.languageIndex = -1
            compare(menu.currentIndex, 0)
            compare(menu.currentText, "Auto (Russian / English)")
        }

        function test_pickAutoThenALanguage() {
            pick(0)
            compare(widget.languageIndex, -1)
            compare(menu.currentText, "Auto (Russian / English)")
            pick(3)
            compare(widget.languageIndex, 2)
            compare(menu.currentText, "Russian")
            // The swap changes the language: the menu still follows
            widget.languageIndex = 0
            compare(menu.currentText, "English")
        }

        // Engine change: another list, the widget finds its language again
        function test_newListKeepsTheLanguage() {
            widget.languages = ["English", "German", "French", "Russian"]
            widget.languageIndex = 2
            compare(menu.currentText, "French")
        }

        // Same position in the new list: nothing tells the menu but the list
        function test_newListSameIndex() {
            widget.languages = ["German", "French", "Russian"]
            compare(menu.currentText, "French")
        }

        // Native or second language changed in the settings
        function test_newAutoLabel() {
            widget.languageIndex = -1
            widget.autoLabel = "Auto (Russian / French)"
            compare(menu.currentIndex, 0)
            compare(menu.currentText, "Auto (Russian / French)")
        }
    }
}
