import QtQuick

// Destination menu of the widget: "Auto" first, then the languages
ComboBox3 {
    id: menu
    property var languages: []
    property string autoLabel
    // Index in languages, -1 for Auto
    property int languageIndex
    // Only a choice of the user: the widget stores it, the menu follows
    signal chosen(int languageIndex)

    model: [autoLabel].concat(languages)
    currentIndex: languages.length > 0 ? languageIndex + 1 : -1
    onActivated: function(index) {
        chosen(index - 1)
    }
}
