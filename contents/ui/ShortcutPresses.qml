import QtQuick

// Tells a single press of the global shortcut from a double one. A single
// press is reported only once the delay has run out without a second press.
QtObject {
    id: presses
    property int interval: Qt.styleHints.mouseDoubleClickInterval
    signal singlePress()
    signal doublePress()

    function press() {
        if (presses.timer.running) {
            presses.timer.stop()
            presses.doublePress()
        } else {
            presses.timer.start()
        }
    }

    function reset() {
        presses.timer.stop()
    }

    property Timer timer: Timer {
        interval: presses.interval
        repeat: false
        onTriggered: presses.singlePress()
    }
}
