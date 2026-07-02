# Pie Menu — Windows edition ✦

A pink princess pie launcher. Hold **Win**, tap **Tab** → a pie appears at
your cursor. Move onto a slice, release **Win** (or left-click) to launch.
**Esc** cancels. Works on any monitor — the pie opens where your mouse is.

## Setup

1. Install [AutoHotkey v2](https://www.autohotkey.com) (free, tiny).
2. Open `PieMenu.ahk` in a text editor and fix the app paths in the `Apps`
   list at the top so they match where your programs are installed.
   Each entry is `{name: "Label", run: "path or command"}` — you can swap in
   any apps you like (keep it to 8 for 45° slices, or add/remove entries;
   the geometry adapts automatically).
3. Double-click `PieMenu.ahk`. A green "H" appears in the system tray —
   the menu is now live on Win+Tab.

## Start automatically with Windows

Press `Win+R`, run `shell:startup`, and drop a shortcut to `PieMenu.ahk`
into that folder.

## Make a standalone .exe (optional)

With AutoHotkey installed, right-click `PieMenu.ahk` → **Compile Script**
(or use Ahk2Exe). The resulting `PieMenu.exe` runs on machines without
AutoHotkey installed.

## Notes

- While the script runs, **Win+Tab no longer opens Task View**. Quit it
  from the tray icon (right-click → Exit) to get Task View back, or change
  the `#Tab::` hotkey line to something else (e.g. `#a::` for Win+A... see
  the [hotkey docs](https://www.autohotkey.com/docs/v2/Hotkeys.htm)).
- If a slice does nothing and you get a tray notification, the path for
  that app in the `Apps` list is wrong.
- The labels use JetBrains Mono if installed, otherwise Segoe UI. If the
  center glyph (✦) shows as a box, replace it in the script with any
  character you like.
