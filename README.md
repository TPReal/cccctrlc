# CCCCtrlC

A simple multiple-clipboard utility for Windows, written in [AutoHotkey](https://www.autohotkey.com/) v2.
It adds any number of extra clipboards, called cccclipboards, reachable through the normal clipboard
shortcuts: tap a shortcut for the regular clipboard, hold it to pick a cccclipboard.

Originally written in 2009 for AutoHotkey v1, ported to v2 in 2026.

## Usage

- Hold Ctrl+C to select a cccclipboard, and release to copy to it.
- Hold Ctrl+V to select a cccclipboard, and release to paste from it.

Pressing and releasing a shortcut without delay uses the regular clipboard, as always. Holding it
brings up a selection indicator in the bottom right corner of the screen, which scrolls over the
cccclipboards; releasing the keys runs the action on the one selected at that moment. Holding on past
the last one cancels the action.

In the indicator, `C` is a cccclipboard with data and `_` an empty one. The first cccclipboard is the
rightmost. `(C)` marks the current selection, `[C]` the cccclipboard an action has just used.

### Shortcuts

| Shortcut                           | Action                                                  |
|------------------------------------|---------------------------------------------------------|
| Ctrl+X, Ctrl+C, Ctrl+V             | Cut, copy, paste                                        |
| Shift+Del, Ctrl+Ins, Shift+Ins     | Cut, copy, paste                                        |
| Ctrl+C+V                           | Show help (while held)                                  |
| Ctrl+X+C                           | Show the list of cccclipboards (while held)             |
| Ctrl+Ins+X                         | Erase all cccclipboards (the regular one is left alone) |

For the three-key combinations, hold the first two keys and add the third.

Cccclipboards live in memory only: they are gone when the script exits or reloads.

## Running

Requires Windows and AutoHotkey v2.0 or newer.

Double-click `CCCCtrlC.ahk`. The script runs as administrator, so that its shortcuts also work in
elevated windows; expect a UAC prompt when starting it by hand.

Because it runs elevated, keep the script somewhere only you can write to: whatever can modify the
file gets to run code as administrator.

### Tray menu

Right-click the tray icon for the options:

- **Run at startup** — starts CCCCtrlC at logon. This registers a scheduled task named `CCCCtrlC`
  that runs with highest privileges, so there is no UAC prompt at logon; unticking the item deletes
  the task. The task records the script's location at the time, so untick and tick the item again
  after moving the script.
- **Selection interval** — how fast the indicator moves between cccclipboards: the lower the faster,
  10 by default. Changes apply immediately.

After editing the script, pick "Reload Script" from the same menu.

### Configuration

The selection interval is saved to `CCCCtrlC.ini`, next to the script:

```ini
[Settings]
Interval=10
```

The file is created on the first change, and is not meant to be committed.

## Compiling

The script can be compiled to a standalone exe with Ahk2Exe; `CCCCtrlC.ico` is embedded as its icon.
A compiled exe keeps its own `CCCCtrlC.ini` next to itself.
