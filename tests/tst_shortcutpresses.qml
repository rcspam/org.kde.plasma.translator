import QtQuick
import QtTest
import "../contents/ui"

Item {
    ShortcutPresses {
        id: presses
        interval: 100
    }
    SignalSpy {
        id: singles
        target: presses
        signalName: "singlePress"
    }

    SignalSpy {
        id: doubles
        target: presses
        signalName: "doublePress"
    }

    TestCase {
        name: "ShortcutPresses"

        function init() {
            presses.reset()
            singles.clear()
            doubles.clear()
        }

        function test_single_press_waits_for_the_delay() {
            presses.press()
            compare(singles.count, 0, "reported before the delay")
            singles.wait(500)
            compare(doubles.count, 0)
        }

        function test_two_quick_presses_are_one_double_press() {
            presses.press()
            presses.press()
            compare(doubles.count, 1)
            wait(300)
            compare(singles.count, 0, "a double press is not also a single one")
        }

        function test_slow_presses_are_two_single_presses() {
            presses.press()
            singles.wait(500)
            presses.press()
            singles.wait(500)
            compare(singles.count, 2)
            compare(doubles.count, 0)
        }

        function test_third_quick_press_starts_a_new_count() {
            presses.press()
            presses.press()
            presses.press()
            compare(doubles.count, 1)
            singles.wait(500)
            compare(singles.count, 1)
        }
    }
}
