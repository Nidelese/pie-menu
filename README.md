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
mkdir -p ~/.config/pie-menu
cp linux/config.example.ini ~/.config/pie-menu/config.ini   # optional, see Customizing
```

Then bind it in your compositor config — Hyprland example:

```
bind = SUPER, Tab, exec, ~/.local/bin/pie-menu
```

## Windows setup

See [`windows/README.md`](windows/README.md) — short version: install
[AutoHotkey v2](https://www.autohotkey.com), fix the app paths in
`pie-menu.ini`, double-click `PieMenu.ahk`.

## Customizing

No code editing needed — both versions read the same INI config format:

| | Config location |
|---|---|
| Linux | `~/.config/pie-menu/config.ini` ([example](linux/config.example.ini)) |
| Windows | `pie-menu.ini` next to the script |

Three sections, all optional (missing file or keys = built-in defaults):

- **`[apps]`** — `Display Name = command`, one per slice, clockwise from the
  top. Put *your* programs here — any number of slices works, the angles
  adapt automatically.
- **`[colors]`** — `#RRGGBB` or `#RRGGBBAA` for every element (slices, hover,
  borders, text, center, overlay). Pink princess by default (`#f4a7c3` pink,
  `#fde8f0` blush, `#1e1020` plum), but it's your pie: gothify, nordify,
  gruvboxify at will.
- **`[menu]`** — radii, gap between slices, font.

The example configs are fully commented and list every key with its default.

## License

MIT — see [LICENSE](LICENSE).
