# pie-menu ✦

A pink princess radial app launcher. Hold <kbd>Super</kbd>, tap <kbd>Tab</kbd> →
a pie of eight app slices blooms at your cursor. Glide onto a slice, release
<kbd>Super</kbd> (or click) to launch. <kbd>Esc</kbd> cancels. Multi-monitor
aware — the pie opens on whichever screen your mouse is on.

Two implementations, same look and feel:

| | Linux (`linux/`) | Windows (`windows/`) |
|---|---|---|
| Stack | Python + GTK3 + gtk-layer-shell + Cairo | AutoHotkey v2 + GDI+ |
| Trigger | Super+Tab (compositor keybind) | Win+Tab (replaces Task View while running) |
| Tested on | Arch Linux + Hyprland | — |

## Linux setup

Dependencies (Arch): `python-gobject`, `gtk3`, `gtk-layer-shell`. The script
reads the cursor position from `hyprctl`, so it currently assumes Hyprland
(other wlroots compositors work if you swap out `get_cursor_and_monitor`).

```sh
install -m 755 linux/pie-menu ~/.local/bin/pie-menu
```

Then bind it in your compositor config — Hyprland example:

```
bind = SUPER, Tab, exec, ~/.local/bin/pie-menu
```

## Windows setup

See [`windows/README.md`](windows/README.md) — short version: install
[AutoHotkey v2](https://www.autohotkey.com), fix the app paths at the top of
`PieMenu.ahk`, double-click it.

## Customizing

Both scripts keep the knobs at the top of the file:

- **Apps** — the `APPS` / `Apps` list, clockwise from North. Any count works;
  slice angles adapt.
- **Palette** — pink princess by default (`#f4a7c3` pink, `#fde8f0` blush,
  `#1e1020` plum). Recolor freely.
- **Geometry** — inner/outer radius, label ring, gap between slices.

## License

MIT — see [LICENSE](LICENSE).
