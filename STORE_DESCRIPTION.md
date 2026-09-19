# Translator - Plasma 6 Widget

**Warning for 6.0.0 users: do NOT click the "Update" button in the widget settings.** In 6.0.0 it points to the old Plasma 5 package (0.8) and would break the widget. Update through Discover or "Get New Widgets" instead. If you already clicked it, reinstall the widget from this page. Fixed in 6.0.1.

A Plasma 6 panel widget that provides a graphical interface for translating text, powered by [translate-shell](https://github.com/soimort/translate-shell).

This is a **port to KDE Plasma 6** of the original [Translator widget by Driglu4it](https://www.pling.com/p/1395666/) (Plasma 5).

Ported by **rcspam** — Source code: https://github.com/rcspam/org.kde.plasma.translator

## Features

- **160+ languages** supported
- **4 translation engines**: Google, Yandex, Bing, Apertium
- **Auto-detect** source language
- **Text-to-speech** (TTS) pronunciation
- **Clipboard integration**: copy result / paste source text
- **Swap** source and destination languages with one click
- **Pin** the popup window to keep it open
- **Searchable and reorderable** language list in settings
- **Keyboard shortcuts**: Ctrl+Enter (translate), Ctrl+S (swap), Ctrl+V (paste), Ctrl+C (copy), Ctrl+P (pin), Esc (clear)

## Requirements

- KDE Plasma 6
- **translate-shell** package (`trans` command)

Install translate-shell:
- Arch / Manjaro: `sudo pacman -S translate-shell`
- Debian / Ubuntu: `sudo apt install translate-shell`
- Fedora: `sudo dnf install translate-shell`
- openSUSE: `sudo zypper install translate-shell`

## Installation

Download the .plasmoid file and run:
```
kpackagetool6 -t Plasma/Applet -i org.kde.plasma.translator.plasmoid
```

Or install directly from the Plasma widget browser.

## Changes from Plasma 5 version

Complete rewrite of the QML codebase for Qt6/Plasma 6 compatibility:
- PlasmoidItem root element, Plasma5Support.DataSource
- Kirigami theme and units, Qt6 controls
- MediaPlayer Qt6 API, new Connections syntax
- Config page rewritten with ListView (replaces TableView 1.x)
- Clipboard handling reworked for Qt6 focus model

## Credits

- **Original author**: [Driglu4it](https://www.pling.com/p/1395666/) (Plasma 5)
- **Plasma 6 port**: [rcspam](https://github.com/rcspam)
- **License**: MIT
