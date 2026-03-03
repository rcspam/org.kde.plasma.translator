# Translator - KDE Plasma 6 Widget

A Plasma 6 desktop widget that provides a graphical interface for translating text, powered by [translate-shell](https://github.com/soimort/translate-shell).

This is a **port to Plasma 6 / KDE 6** of the original [Translator widget](https://www.pling.com/p/1395666/) created by **Driglu4it** for Plasma 5.

Ported by **rcspam**.

![Translator Widget](contents/images/icon.svg)

## Features

- Translate text between 160+ languages
- Multiple translation engines: **Google**, **Yandex**, **Bing**, **Apertium**
- Auto-detect source language
- Text-to-speech (TTS) pronunciation
- Clipboard integration (copy/paste)
- Swap source and destination languages
- Pin popup window to keep it open
- Searchable and reorderable language list in settings
- Keyboard shortcuts for all actions

## Requirements

- **KDE Plasma 6**
- **translate-shell** (`trans`) package

### Install translate-shell

```bash
# Arch Linux / Manjaro
sudo pacman -S translate-shell

# Debian / Ubuntu
sudo apt install translate-shell

# Fedora
sudo dnf install translate-shell

# openSUSE
sudo zypper install translate-shell
```

## Installation

### From .plasmoid file

```bash
kpackagetool6 -t Plasma/Applet -i org.kde.plasma.translator.plasmoid
```

### From source

```bash
git clone https://github.com/rcspam/org.kde.plasma.translator.git
cd org.kde.plasma.translator
kpackagetool6 -t Plasma/Applet -i .
```

### Update

```bash
kpackagetool6 -t Plasma/Applet -u .
```

### Uninstall

```bash
kpackagetool6 -t Plasma/Applet -r org.kde.plasma.translator
```

## Keyboard Shortcuts

| Shortcut     | Action            |
| ------------ | ----------------- |
| `Ctrl+Enter` | Translate         |
| `Ctrl+S`     | Swap languages    |
| `Ctrl+V`     | Paste into source |
| `Ctrl+C`     | Copy translation  |
| `Ctrl+P`     | Pin/unpin popup   |
| `Esc`        | Clear all text    |

## Changes from Plasma 5 to Plasma 6

This port includes the following changes to make the widget compatible with KDE Plasma 6:

- **metadata.desktop** replaced by **metadata.json** with Plasma 6 fields
- Root element migrated from `Item` to `PlasmoidItem`
- All QML imports updated to Qt6 (no version numbers)
- `PlasmaCore.DataSource` replaced by `Plasma5Support.DataSource`
- Theme colors migrated from `PlasmaCore.Theme` to `Kirigami.Theme`
- Units migrated from `PlasmaCore.Units` to `Kirigami.Units`
- Controls migrated from QtQuick.Controls 1.x to QtQuick.Controls 2 (`QQC2`)
- SVG rendering migrated from `PlasmaCore.SvgItem` to `Image` + `ColorOverlay`
- MediaPlayer updated for Qt6 API (`audioOutput`, new signal names)
- Connections blocks updated to Qt6 function syntax
- Config page language table rewritten (TableView 1.x replaced by ListView)
- `XmlListModel` replaced by `XMLHttpRequest` for update checking
- Clipboard handling reworked for Qt6 focus model

## Credits

- **Original author:** [Driglu4it](https://www.pling.com/p/1395666/) (Plasma 5 version)
- **Plasma 6 port:** rcspam
- **License:** MIT
