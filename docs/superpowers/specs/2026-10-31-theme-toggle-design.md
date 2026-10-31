# Unified Light/Dark Theme Toggle

Date: 2026-10-31
Status: awaiting approval

## Intent

One keypress switches every themed app between Catppuccin **Latte** (light)
and **Macchiato** (dark). Today the palette is hardcoded per file in at least
eleven places, so light mode is unreachable without editing each one.

Why: the user works in both lighting conditions and wants a single control
instead of per-app theme menus.

## Goals

- One command / one keybind flips the whole desktop.
- Choice persists across reboot and new terminals.
- Palette values live in exactly one place per flavour; no duplicated hex
  blocks in app configs.
- Each app keeps its own real config file; the theme layer only owns colours.

## Non-goals

- Wallpaper and `i3lock` background stay as they are today
  (`dracula-soft-waves-bd93f9.png`, `i3lock --color=000000`). Decided by the
  user: the desktop may stay dark behind light windows.
- Browser web content (Brave renders pages per site; OS theme cannot change it).
- `lazygit`, `lazydocker`, `opencode`, `bluetui`, `lazysql` (separate configs;
  candidate follow-up).
- Per-app independent theming (e.g. light bar + dark terminal).
- Automatic switching by time of day.

## Constraints found in the current system

| App | Version | Include mechanism | Reload |
| --- | --- | --- | --- |
| i3 | 4.23 | `include` | `i3-msg reload` |
| polybar | 3.7.1 | `include-file`, `${colors.x}` refs already used | `polybar-msg cmd restart` |
| rofi | — | `@import` | next launch |
| tmux | 3.4 | `source-file` | `tmux source-file` |
| alacritty | — | `import` | config watch (verify) |
| zathura | — | `include` | next launch |
| dunst | 1.9.2 | **none** (verified: no `include` support) | `dunstctl reload` |
| screenkey | — | none (JSON) | restart via `toggle-app` |
| zsh / fzf | — | `source` | new shell |
| GTK | — | `settings.ini` + gsettings | live |
| Neovim | — | reads state file | `FocusGained` |

`picom` has no colours. `.p10k.zsh` uses ANSI indices (`local magenta='5'`),
so it follows the terminal palette for free — no change needed.

## Approaches considered

**A. Palette fragments included by each app (chosen).** Repo holds
`_config/themes/{latte,macchiato}/` with one small fragment per app. Each app
reads a fixed path (`~/.config/i3/colors.conf`, ...) that is a symlink into the
active flavour directory. Toggle repoints symlinks and reloads. Only dunst and
screenkey need whole-file replacement because they have no include mechanism.

**B. Two complete config sets, swapped by symlink.** No include support needed
anywhere, but ~15 files duplicated per flavour and drift whenever one side is
edited.

**C. Templates rendered at toggle time.** Single source of truth, works for
apps without include, but deployed configs become generated artifacts and every
manual edit is lost on the next toggle.

A wins because six of eight apps already support includes, so no render engine
is needed and configs stay hand-editable.

## Design

### State

- `~/.config/theme` contains one line: `latte` or `macchiato`. Default when
  absent: `macchiato`.
- Everything reads this file; nothing else stores the mode.

### Repo layout

```
_config/themes/
  latte/
    i3.conf          # 26 `set $name #hex` lines
    polybar.ini      # [colors] section
    rofi.rasi        # `* { ... }` colour block
    tmux.conf        # status bar colours
    alacritty.toml   # [colors.*] block
    zathura          # `set <element>-bg/fg "#hex"` lines
    dunstrc          # full file
    screenkey.json   # full file
    zsh-colors.zsh   # export FZF_DEFAULT_OPTS=...
    gtk.ini          # gtk-theme-name / prefer-dark
  macchiato/
    (same files, Macchiato values)
_local/bin/theme-toggle
gtk_theme_setup.sh
```

Palette values are the published Catppuccin hex values for both flavours.

### Stable paths (symlinks into the active flavour)

| App | Path | Fragment |
| --- | --- | --- |
| i3 | `~/.config/i3/colors.conf` | `i3.conf` |
| polybar | `~/.config/polybar/colors.ini` | `polybar.ini` |
| rofi | `~/.config/rofi/colors.rasi` | `rofi.rasi` |
| tmux | `~/.config/tmux/colors.conf` | `tmux.conf` |
| alacritty | `~/.config/alacritty/colors.toml` | `alacritty.toml` |
| zathura | `~/.config/zathura/colors` | `zathura` |
| dunst | `~/.config/dunst/dunstrc` | `dunstrc` |
| screenkey | `~/.config/screenkey.json` | `screenkey.json` |
| zsh | `~/.config/zsh/colors.zsh` | `zsh-colors.zsh` |
| GTK | `~/.config/gtk-3.0/settings.ini` | `gtk.ini` |

Symlinks point at the deployed copies in `~/.config/themes/<flavour>/`, not at
the repo, so the desktop never depends on the checkout location.

`app_setup.sh` ends with `theme-toggle --set "$(cat ~/.config/theme 2>/dev/null || echo macchiato)"`
so a fresh install never has an include pointing at a missing file. The old
`_config/dunst/dunstrc` and `_config/screenkey.json` are deleted from the repo:
`cp -a ./_config/.` would otherwise write through the deployed symlink and
overwrite the active fragment.

### Polybar module colours

`battery.ini`, `date.ini`, `filesystem.ini`, `network.ini`, `xbacklight.ini`
still hardcode `%{F#...}` inline. They are converted to `${colors.*}` so no
Macchiato hex survives in light mode.

### GTK4

`~/.config/gtk-4.0/settings.ini` gets the same symlink and fragment content, so
GTK4 apps (Nautilus, file chooser) follow. Fragment carries theme name plus the
font/icon/cursor keys currently in effect, so switching does not reset them.

dunst and screenkey are the only targets whose *whole* file is the fragment;
for them the symlink replaces the deployed file, so local edits must be made in
the theme directory.

### Edits to existing configs

- `_config/i3/config`: replace the 26 `set $name #hex` lines with
  `include ~/.config/i3/colors.conf`.
- `_config/polybar/config.ini`: replace the `[colors]` body with
  `include-file = ~/.config/polybar/colors.ini` (keeps `${colors.*}` refs working).
- `_config/rofi/config.rasi`: drop colour properties from the `*` block, add
  `@import "colors.rasi"`.
- `_config/tmux/tmux.conf`: move the single `status-style` colour line into
  `colors.conf`, add `source-file ~/.config/tmux/colors.conf`.
- `_config/alacritty/alacritty.toml`: import `~/.config/alacritty/colors.toml`
  instead of the hardcoded absolute `catppuccin-macchiato.toml` path; delete
  that file.
- `_config/zathura/zathurarc`: replace `set ... "#hex"` lines with
  `include colors`.
- `.zshrc`: replace the inline `FZF_DEFAULT_OPTS` export with
  `source ~/.config/zsh/colors.zsh`.
- `_config/i3/config`: add `bindsym $cmd+Shift+t exec ~/.local/bin/theme-toggle`
  (`Super+Shift+t` is unused; `Super+d`, `Super+Shift+s`, `Super+Shift+r` are taken).

### Toggle behaviour (`_local/bin/theme-toggle`)

1. Read current flavour from `~/.config/theme`; compute the other.
2. Repoint every symlink above with `ln -sfn`.
3. GTK: `gsettings set org.gnome.desktop.interface gtk-theme ...` and
   `color-scheme prefer-light|prefer-dark`.
4. Reload: `i3-msg reload`, `polybar-msg cmd restart`, `dunstctl reload`,
   `tmux source-file` for the current server, restart screenkey if running,
   `touch ~/.config/alacritty/alacritty.toml` to force a reload.
5. Write the new flavour to `~/.config/theme`.
6. `notify-send -a Theme "Theme" "Latte (light)"` / `"Macchiato (dark)"`.

Idempotent: running with `--set latte|macchiato` applies a flavour without
flipping, so setup scripts can call it.

### Neovim (outside this repo)

`~/.config/nvim/lua/plugins/catppuccin.lua`: remove
`vim.cmd.colorscheme 'catppuccin-macchiato'`; set `vim.o.background` from
`~/.config/theme` before `colorscheme catppuccin`, and re-apply on
`FocusGained` so a running instance follows the toggle.

### GTK themes

`gtk_theme_setup.sh` downloads pinned release zips from
`catppuccin/gtk` v1.0.3 (`catppuccin-latte-mauve-standard+default.zip`,
`catppuccin-macchiato-mauve-standard+default.zip`), verifies SHA256, and
extracts into `~/.themes`. Mauve accent matches the current Neovim/polybar
accent usage. Exact theme directory name is read from the archive at
implementation time.

`app_setup.sh` runs it. If the Catppuccin theme directory is missing,
`theme-toggle` falls back to `Yaru` / `Yaru-dark` (already installed) instead
of setting a theme name that does not exist.

## Verification

- `theme-toggle` twice: state file flips, all symlinks resolve, no target
  missing.
- Parse checks after each flip: `i3 -C -c ~/.config/i3/config`,
  `bash -n` on scripts, `polybar-msg cmd restart` exit 0,
  `dunstctl reload` exit 0, `tmux source-file` exit 0.
- Visual: screenshot of bar + terminal + Neovim in both modes; confirm light
  bar has dark text and dark bar has light text (no invisible segments).
- Reboot simulation: new shell sources Latte fzf colours; Neovim starts Latte.

## Risks

- Alacritty may not pick up an imported-file change; fallback is touching the
  main config (already in the script).
- `zathura` and `rofi` only change on next launch — accepted.
- GTK theme zip layout may differ from `~/.themes/<name>`; verified during
  implementation, fallback is `Yaru`/`Yaru-dark` (already installed).
- dunst and screenkey are fully replaced by symlink: any local tweak outside
  the theme directory is lost on the next toggle.
