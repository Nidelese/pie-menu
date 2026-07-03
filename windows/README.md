# Pie Menu — Windows edition ✦

A pink princess pie launcher. Hold **Win**, tap **Tab** → a pie appears at
your cursor. Move onto a slice, release **Win** (or left-click) to launch.
**Esc** cancels. Works on any monitor — the pie opens where your mouse is.

# Pie_Moonfly.png

<p align="center">
  <img src="assets/Pie_Moonfly.png" width="420"
       alt="Pie menu open over a desktop: 7 slices over a blue color scheme on windows 10. ">
</p>

## Setup

1. Install [AutoHotkey v2](https://www.autohotkey.com) (free, tiny).
2. Open `pie-menu.ini` (keep it next to `PieMenu.ahk`) in Notepad and make
   the `[apps]` section match the programs you actually use: one
   `Name = path-or-command` line per slice, clockwise from the top. Any
   number of slices works — the angles adapt. The `[colors]` and `[menu]`
   sections restyle the whole thing (`#RRGGBB` / `#RRGGBBAA` values); every
   key is optional and the file documents them all.
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
  that app in `pie-menu.ini` is wrong.
- The labels use JetBrains Mono if installed, otherwise Segoe UI (or set
  `font` in `pie-menu.ini`).
