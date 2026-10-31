# Unified Latte/Macchiato Theme Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One keypress switches every themed app between Catppuccin Latte (light) and Macchiato (dark), persisted across reboot.

**Architecture:** Palette values live once per flavour in `_config/themes/<flavour>/`. Each app reads a fixed path under `~/.config` that is a symlink into `~/.config/themes/<flavour>/`. `_local/bin/theme-toggle` repoints every symlink, sets GTK via gsettings, reloads running apps, writes `~/.config/theme`, and notifies.

**Tech Stack:** Bash, i3 4.23 `include`, polybar 3.7.1 `include-file`, rofi `@import`, tmux `source-file`, alacritty `import`, zathura `include`, dunst 1.9.2 (no include → whole-file), Neovim catppuccin.nvim, GTK 3/4.

**Spec:** `docs/superpowers/specs/2026-10-31-theme-toggle-design.md`

## Global Constraints

- State file: `~/.config/theme`, single line `latte` or `macchiato`, default `macchiato` when absent.
- Palette hex values are the published Catppuccin values in the table below. Copy exactly; no approximations.
- Symlinks point at deployed copies in `~/.config/themes/<flavour>/`, never at the repo checkout.
- `theme-toggle` must skip a fragment that does not exist yet (warn on stderr, exit 0) so tasks can land incrementally.
- Scripts: `#!/bin/bash`, `set -euo pipefail`, quote expansions, `command -v` before use.
- Keybind: `$cmd+Shift+t` (Super+Shift+t). Do not touch navigation, Harpoon, or i3 `Alt` binds.
- Wallpaper and `i3lock --color=000000` do not change.
- `dunst` and `screenkey` are the only whole-file symlinks; every other target is a colour fragment.

### Catppuccin palette (authoritative)

| name | latte | macchiato |
| --- | --- | --- |
| rosewater | `#dc8a78` | `#f4dbd6` |
| flamingo | `#dd7878` | `#f0c6c6` |
| pink | `#ea76cb` | `#f5bde6` |
| mauve | `#8839ef` | `#c6a0f6` |
| red | `#d20f39` | `#ed8796` |
| maroon | `#e64553` | `#ee99a0` |
| peach | `#fe640b` | `#f5a97f` |
| yellow | `#df8e1d` | `#eed49f` |
| green | `#40a02b` | `#a6da95` |
| teal | `#179299` | `#8bd5ca` |
| sky | `#04a5e5` | `#91d7e3` |
| sapphire | `#209fb5` | `#7dc4e4` |
| blue | `#1e66f5` | `#8aadf4` |
| lavender | `#7287fd` | `#b7bdf8` |
| text | `#4c4f69` | `#cad3f5` |
| subtext1 | `#5c5f77` | `#b8c0e0` |
| subtext0 | `#6c6f85` | `#a5adcb` |
| overlay2 | `#7c7f93` | `#939ab7` |
| overlay1 | `#8c8fa1` | `#8087a2` |
| overlay0 | `#9ca0b0` | `#6e738d` |
| surface2 | `#acb0be` | `#5b6078` |
| surface1 | `#bcc0cc` | `#494d64` |
| surface0 | `#ccd0da` | `#363a4f` |
| base | `#eff1f5` | `#24273a` |
| mantle | `#e6e9ef` | `#1e2030` |
| crust | `#dce0e8` | `#181926` |

## Review Focus

- Fragment missing on a fresh install: toggle must warn and continue, never leave a dangling symlink or a half-written state file.
- `app_setup.sh` re-run with `cp -a ./_config/.` must not write through the dunst/screenkey/GTK symlinks and destroy the active fragment.
- Leftover Macchiato hex in polybar modules makes light mode unreadable; no `#rrggbb` may remain in `_config/polybar/modules/`.
- A Neovim instance started before the toggle must follow it (FocusGained re-apply), not keep the old flavour.
- Catppuccin GTK theme missing must fall back to `Yaru`/`Yaru-dark`, not set a non-existent theme name.

---

### Task 1: Theme state, toggle script, i3 fragment

**Files:**
- Create: `_local/bin/theme-toggle`
- Create: `_config/themes/latte/i3.conf`
- Create: `_config/themes/macchiato/i3.conf`
- Modify: `_config/i3/config:13-38` (palette block → `include`)
- Modify: `_config/i3/config` (add keybind near line 294)
- Modify: `app_setup.sh:81-83` (final apply)
- Modify: `keymaps.md` (keybind table)

**Interfaces:**
- Produces: `theme-toggle` CLI — `theme-toggle` (flip), `theme-toggle --set latte|macchiato`, `theme-toggle --status` (prints flavour, exit 0; exit 1 on unknown value). Later tasks only add rows to its link table.
- Produces: `~/.config/themes/<flavour>/` deployed by `app_setup.sh`.

- [ ] **Step 1: Write the failing check**

```bash
# /tmp/opencode/check-task1.sh
set -euo pipefail
TOGGLE="$HOME/.local/bin/theme-toggle"
[[ -x "$TOGGLE" ]] || { echo "FAIL: not executable"; exit 1; }
"$TOGGLE" --set latte
[[ "$(cat "$HOME/.config/theme")" == latte ]] || { echo "FAIL: state"; exit 1; }
[[ "$(readlink -f "$HOME/.config/i3/colors.conf")" == "$HOME/.config/themes/latte/i3.conf" ]] || { echo "FAIL: symlink"; exit 1; }
i3 -C -c "$HOME/.config/i3/config" >/dev/null || { echo "FAIL: i3 config"; exit 1; }
"$TOGGLE" --set macchiato
[[ "$(readlink -f "$HOME/.config/i3/colors.conf")" == "$HOME/.config/themes/macchiato/i3.conf" ]] || { echo "FAIL: symlink back"; exit 1; }
[[ "$("$TOGGLE" --status)" == macchiato ]] || { echo "FAIL: status"; exit 1; }
echo PASS
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/opencode/check-task1.sh`
Expected: `FAIL: not executable` (script absent).

- [ ] **Step 3: Create the two i3 fragments**

`_config/themes/latte/i3.conf` — 26 lines, exactly `set $<name> <latte hex>` in the palette table order (rosewater first, crust last). `_config/themes/macchiato/i3.conf` — same shape with macchiato values, reproducing today's values byte-for-byte.

- [ ] **Step 4: Replace the inline palette in `_config/i3/config`**

Delete lines 13-38 (the `set $rosewater` … `set $crust` block) and put in their place:

```i3config
include ~/.config/i3/colors.conf
```

- [ ] **Step 5: Write `_local/bin/theme-toggle`**

Structure: parse `--set|--status` (anything else = flip); resolve `CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}`; `THEME_FILE=$CONFIG/theme`, `THEMES_DIR=$CONFIG/themes`. Link table as a `while read -r fragment target` heredoc:

```
i3.conf:$CONFIG/i3/colors.conf
```

For each row: skip with `echo "skip: no fragment $fragment" >&2` when `$THEMES_DIR/$flavour/$fragment` is missing; otherwise `mkdir -p "$(dirname "$target")"` and `ln -sfn "$THEMES_DIR/$flavour/$fragment" "$target"`. After links, reload i3 only when `command -v i3-msg` and `i3-msg -t get_version` succeeds (`i3-msg reload >/dev/null`), then `notify-send -a Theme "Theme" "$flavour"` guarded by `command -v`. Write the flavour to `$THEME_FILE` last.

- [ ] **Step 6: Add the i3 keybind**

After the `$cmd+shift+q` line in `_config/i3/config`:

```i3config
bindsym $cmd+Shift+t exec $HOME/.local/bin/theme-toggle
```

- [ ] **Step 7: Apply the theme at the end of `app_setup.sh`**

After `cp -a ./_config/. "$HOME/.config/"` (line 81) and the other copies, before the script's final message:

```bash
install -m 755 ./_local/bin/theme-toggle "$HOME/.local/bin/theme-toggle"
"$HOME/.local/bin/theme-toggle" --set "$(cat "$HOME/.config/theme" 2>/dev/null || echo macchiato)"
```

- [ ] **Step 8: Deploy and run the check**

```bash
cd ~/personal/i3-ubuntu-dotfiles
cp -a _config/. "$HOME/.config/"
install -m 755 _local/bin/theme-toggle "$HOME/.local/bin/theme-toggle"
bash /tmp/opencode/check-task1.sh
```
Expected: `PASS`.

- [ ] **Step 9: Verify a missing fragment does not break the toggle**

Run: `mv "$HOME/.config/themes/latte" /tmp/opencode/latte-bak && ~/.local/bin/theme-toggle --set latte; echo "exit=$?"; mv /tmp/opencode/latte-bak "$HOME/.config/themes/latte"`
Expected: stderr contains `skip: no fragment`, `exit=0`, `~/.config/theme` still written, `~/.config/i3/colors.conf` still resolves to an existing file.

- [ ] **Step 10: Commit**

```bash
git add _local/bin/theme-toggle _config/themes _config/i3/config app_setup.sh keymaps.md
git commit -m "feat: add theme state and toggle with i3 palette fragment"
```

---

### Task 2: Polybar fragment and module colours

**Files:**
- Create: `_config/themes/latte/polybar.ini`, `_config/themes/macchiato/polybar.ini`
- Modify: `_config/polybar/config.ini:24-58` (`[colors]` body → `include-file`)
- Modify: `_config/polybar/modules/{battery,date,filesystem,network,xbacklight}.ini`
- Modify: `_local/bin/theme-toggle` (add link row + polybar reload)

**Interfaces:**
- Consumes: `theme-toggle` CLI and link-table pattern from Task 1.
- Produces: `[colors]` keys `base mantle crust text subtext0 subtext1 surface0 surface1 surface2 overlay0 overlay1 overlay2 blue lavender sapphire sky teal green yellow peach maroon red mauve pink flamingo rosewater transparent`.

- [ ] **Step 1: Write the failing check**

```bash
# /tmp/opencode/check-task2.sh
set -euo pipefail
! grep -rqE '#[0-9a-fA-F]{6}' "$HOME/.config/polybar/modules/" || { echo "FAIL: inline hex left"; exit 1; }
~/.local/bin/theme-toggle --set latte
grep -q '^ base = #eff1f5' "$HOME/.config/polybar/colors.ini" || { echo "FAIL: latte base"; exit 1; }
polybar-msg cmd restart >/dev/null 2>&1 || true
pgrep -x polybar >/dev/null || { echo "FAIL: polybar died"; exit 1; }
echo PASS
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/opencode/check-task2.sh`
Expected: `FAIL: inline hex left`.

- [ ] **Step 3: Create both polybar fragments**

Copy the existing `[colors]` block from `_config/polybar/config.ini` into each fragment, swapping values per the palette table; keep `transparent = #00000000` and the same key order. File starts with `[colors]` and contains no `[bar/*]` section.

- [ ] **Step 4: Point `config.ini` at the fragment**

Replace the `[colors]` body (lines 24-58) with:

```ini
[colors]
include-file = ~/.config/polybar/colors.ini
```

- [ ] **Step 5: Convert module hex to `${colors.*}`**

- `battery.ini:79` `%{F#a6da95}` → `%{F${colors.green}}`; `battery.ini:87` `%{F#ed8796}` → `%{F${colors.red}}`
- `date.ini:21` `%{F#91d7e3}` → `%{F${colors.sky}}`, `%{F#cad3f5}` → `%{F${colors.text}}`
- `filesystem.ini:54` `%{F#c6a0f6}` → `%{F${colors.mauve}}`
- `network.ini:78` `%{F#c6a0f6}` → `%{F${colors.mauve}}`, `%{F#ed8796}` → `%{F${colors.red}}`; `network.ini:108` and `:113` `%{F#c6a0f6}` → `%{F${colors.mauve}}`
- `xbacklight.ini:46` `%{F#c6a0f6}` → `%{F${colors.mauve}}`, `%{F#cad3f5}` → `%{F${colors.text}}`

Leave commented-out lines untouched.

- [ ] **Step 6: Add the polybar row and reload to `theme-toggle`**

Add `polybar.ini:$CONFIG/polybar/colors.ini` to the link table. In the reload block, after i3: if `command -v polybar-msg` and `pgrep -x polybar`, run `polybar-msg cmd restart >/dev/null || true`.

- [ ] **Step 7: Deploy and run the check**

```bash
cd ~/personal/i3-ubuntu-dotfiles && cp -a _config/. "$HOME/.config/" && bash /tmp/opencode/check-task2.sh
```
Expected: `PASS`. Then flip to macchiato and confirm `~/.config/polybar/colors.ini` contains `base = #24273a`.

- [ ] **Step 8: Commit**

```bash
git add _config/themes _config/polybar _local/bin/theme-toggle
git commit -m "feat: theme polybar from palette fragments"
```

---

### Task 3: rofi, tmux, alacritty, zathura

**Files:**
- Create: `_config/themes/{latte,macchiato}/{rofi.rasi,tmux.conf,alacritty.toml,zathura}`
- Modify: `_config/rofi/config.rasi:14-20`
- Modify: `_config/tmux/tmux.conf:33`
- Modify: `_config/alacritty/alacritty.toml:37`
- Delete: `_config/alacritty/catppuccin-macchiato.toml`
- Modify: `_config/zathura/zathurarc`
- Modify: `_local/bin/theme-toggle` (4 link rows + reloads)

**Interfaces:**
- Consumes: link table from Task 1.
- Produces: fragments at `~/.config/{rofi/colors.rasi,tmux/colors.conf,alacritty/colors.toml,zathura/colors}`.

- [ ] **Step 1: Write the failing check**

```bash
# /tmp/opencode/check-task3.sh
set -euo pipefail
~/.local/bin/theme-toggle --set latte
grep -q 'background-color: #eff1f5' "$HOME/.config/rofi/colors.rasi" || { echo "FAIL: rofi"; exit 1; }
grep -q "bg=#40a02b" "$HOME/.config/tmux/colors.conf" || { echo "FAIL: tmux"; exit 1; }
grep -q 'base = "#EFF1F5"' "$HOME/.config/alacritty/colors.toml" || { echo "FAIL: alacritty"; exit 1; }
grep -q '#EFF1F5' "$HOME/.config/zathura/colors" || { echo "FAIL: zathura"; exit 1; }
tmux source-file "$HOME/.config/tmux/tmux.conf" || { echo "FAIL: tmux parse"; exit 1; }
! grep -rq 'catppuccin-macchiato.toml' "$HOME/.config/alacritty/" || { echo "FAIL: old import"; exit 1; }
echo PASS
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/opencode/check-task3.sh`
Expected: `FAIL: rofi`.

- [ ] **Step 3: Create rofi fragments**

`rofi.rasi` holds one `* { ... }` block with exactly the five keys currently in `_config/rofi/config.rasi` lines 16-20 (`foreground`, `background-color`, `active-background`, `urgent-background`, `urgent-foreground`) mapped through the palette table.

- [ ] **Step 4: Import it and drop the inline colours**

In `_config/rofi/config.rasi`, add `@import "colors.rasi"` as the first line and delete the five colour properties from the `*` block (keep `font`).

- [ ] **Step 5: Create tmux fragments and source them**

Fragment content is one line per flavour: latte `set -g status-style 'bg=#40a02b fg=#eff1f5'`, macchiato `set -g status-style 'bg=#a6da95 fg=#181926'` (current value). In `_config/tmux/tmux.conf` replace line 33 with:

```tmux
source-file ~/.config/tmux/colors.conf
```

- [ ] **Step 6: Create alacritty fragments and switch the import**

Copy `_config/alacritty/catppuccin-macchiato.toml` to `_config/themes/macchiato/alacritty.toml` unchanged. Create the latte equivalent with the same structure, latte values, uppercase hex (match existing file style). Change `_config/alacritty/alacritty.toml:37` to `import = ["~/.config/alacritty/colors.toml"]` and delete `_config/alacritty/catppuccin-macchiato.toml`.

- [ ] **Step 7: Create zathura fragments**

Move every `set <element> "#hex"` line from `_config/zathura/zathurarc` into `_config/themes/macchiato/zathura`, keeping order and uppercase hex; create the latte version with the same element list. Replace them in `zathurarc` with `include colors` on one line where the block used to be.

- [ ] **Step 8: Add rows and reloads to `theme-toggle`**

Rows: `rofi.rasi:$CONFIG/rofi/colors.rasi`, `tmux.conf:$CONFIG/tmux/colors.conf`, `alacritty.toml:$CONFIG/alacritty/colors.toml`, `zathura:$CONFIG/zathura/colors`. Reload block: `tmux source-file "$CONFIG/tmux/tmux.conf"` when `tmux ls` succeeds; `touch "$CONFIG/alacritty/alacritty.toml"` when the file exists.

- [ ] **Step 9: Deploy and run the check**

```bash
cd ~/personal/i3-ubuntu-dotfiles && cp -a _config/. "$HOME/.config/" && bash /tmp/opencode/check-task3.sh
```
Expected: `PASS`. Then `theme-toggle --set macchiato`, open rofi and zathura manually, confirm dark colours.

- [ ] **Step 10: Commit**

```bash
git add _config/themes _config/rofi _config/tmux _config/alacritty _config/zathura _local/bin/theme-toggle
git commit -m "feat: theme rofi, tmux, alacritty, zathura from fragments"
```

---

### Task 4: dunst, screenkey, zsh fzf

**Files:**
- Create: `_config/themes/{latte,macchiato}/dunstrc`
- Create: `_config/themes/{latte,macchiato}/screenkey.json`
- Create: `_config/themes/{latte,macchiato}/zsh-colors.zsh`
- Delete: `_config/dunst/dunstrc`, `_config/screenkey.json`
- Modify: `.zshrc:99-103`
- Modify: `_local/bin/theme-toggle` (3 link rows + reloads)

**Interfaces:**
- Consumes: link table from Task 1.
- Produces: `~/.config/dunst/dunstrc`, `~/.config/screenkey.json`, `~/.config/zsh/colors.zsh` as symlinks into the active flavour.

- [ ] **Step 1: Write the failing check**

```bash
# /tmp/opencode/check-task4.sh
set -euo pipefail
~/.local/bin/theme-toggle --set latte
grep -q 'background = "#EFF1F5"' "$HOME/.config/dunst/dunstrc" || { echo "FAIL: dunst"; exit 1; }
grep -q '"bg_color": "#eff1f5"' "$HOME/.config/screenkey.json" || { echo "FAIL: screenkey"; exit 1; }
grep -q 'bg:#eff1f5' "$HOME/.config/zsh/colors.zsh" || { echo "FAIL: fzf"; exit 1; }
dunstctl reload >/dev/null 2>&1 || { echo "FAIL: dunst reload"; exit 1; }
zsh -n "$HOME/.zshrc" || { echo "FAIL: zshrc"; exit 1; }
zsh -ic 'print -r -- "$FZF_DEFAULT_OPTS"' | grep -q 'bg:#eff1f5' || { echo "FAIL: fzf not sourced"; exit 1; }
echo PASS
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/opencode/check-task4.sh`
Expected: `FAIL: dunst`.

- [ ] **Step 3: Create dunst fragments**

Copy `_config/dunst/dunstrc` twice, replacing all 8 hex values (lines 62, 274-290) with the matching palette entries: `frame_color` blue, `background` base, `foreground` text, notification-low `frame_color` peach. Delete `_config/dunst/dunstrc` from the repo afterwards.

- [ ] **Step 4: Create screenkey fragments**

Copy `_config/screenkey.json` twice; `font_color` = text, `bg_color` = base (lowercase hex to match the file). Delete `_config/screenkey.json` from the repo.

- [ ] **Step 5: Create zsh fragments**

Each file is one `export FZF_DEFAULT_OPTS="..."` matching the current block, with `bg+`=surface0, `bg`=base, `spinner`/`pointer`/`marker`=rosewater, `hl`/`hl+`/`header`=red, `fg`/`fg+`=text, `info`/`prompt`=mauve.

- [ ] **Step 6: Source it from `.zshrc`**

Replace the inline `export FZF_DEFAULT_OPTS=...` block with:

```zsh
[[ -r ~/.config/zsh/colors.zsh ]] && source ~/.config/zsh/colors.zsh
```

- [ ] **Step 7: Add rows and reloads to `theme-toggle`**

Rows: `dunstrc:$CONFIG/dunst/dunstrc`, `screenkey.json:$CONFIG/screenkey.json`, `zsh-colors.zsh:$CONFIG/zsh/colors.zsh`. Reload: `dunstctl reload` when `command -v dunstctl`; when `pgrep -x screenkey`, `pkill -x screenkey` and `screenkey --no-systray` detached via `setsid` only if it was running.

- [ ] **Step 8: Deploy and run the check**

```bash
cd ~/personal/i3-ubuntu-dotfiles && cp -a _config/. "$HOME/.config/" && bash /tmp/opencode/check-task4.sh
```
Expected: `PASS`.

- [ ] **Step 9: Verify the deploy no longer writes through symlinks**

```bash
before=$(readlink -f ~/.config/dunst/dunstrc)
cd ~/personal/i3-ubuntu-dotfiles && cp -a _config/. "$HOME/.config/"
after=$(readlink -f ~/.config/dunst/dunstrc)
[[ "$before" == "$after" ]] && grep -q 'EFF1F5\|24273A' ~/.config/dunst/dunstrc && echo "PASS: fragment intact"
```
Expected: `PASS: fragment intact`.

- [ ] **Step 10: Commit**

```bash
git add _config/themes _config/dunst _config/screenkey.json .zshrc _local/bin/theme-toggle
git commit -m "feat: theme dunst, screenkey, fzf from fragments"
```

---

### Task 5: GTK 3/4

**Files:**
- Create: `gtk_theme_setup.sh`
- Create: `_config/themes/{latte,macchiato}/gtk.ini`
- Modify: `_local/bin/theme-toggle` (gsettings + 2 link rows)
- Modify: `app_setup.sh` (run `gtk_theme_setup.sh`)
- Modify: `README.md` (installer list)

**Interfaces:**
- Consumes: `theme-toggle` CLI, link table.
- Produces: `~/.themes/Catppuccin-{Latte,Macchiato}-Mauve-standard+default/` and `~/.config/gtk-{3.0,4.0}/settings.ini` symlinks.

- [ ] **Step 1: Write the failing check**

```bash
# /tmp/opencode/check-task5.sh
set -euo pipefail
~/.local/bin/theme-toggle --set latte
theme=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
scheme=$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")
[[ "$theme" == Catppuccin-Latte-* || "$theme" == Yaru ]] || { echo "FAIL: theme=$theme"; exit 1; }
[[ "$scheme" == prefer-light ]] || { echo "FAIL: scheme=$scheme"; exit 1; }
grep -q "^gtk-theme-name=$theme" "$HOME/.config/gtk-3.0/settings.ini" || { echo "FAIL: gtk3 ini"; exit 1; }
grep -q "^gtk-theme-name=$theme" "$HOME/.config/gtk-4.0/settings.ini" || { echo "FAIL: gtk4 ini"; exit 1; }
~/.local/bin/theme-toggle --set macchiato
[[ "$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")" == prefer-dark ]] || { echo "FAIL: dark scheme"; exit 1; }
echo PASS
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/opencode/check-task5.sh`
Expected: `FAIL: theme=Yaru-dark`.

- [ ] **Step 3: Write `gtk_theme_setup.sh`**

Pinned `v1.0.3` of `catppuccin/gtk`, assets `catppuccin-latte-mauve-standard+default.zip` and `catppuccin-macchiato-mauve-standard+default.zip` from `https://github.com/catppuccin/gtk/releases/download/v1.0.3/`. Download to `$(mktemp -d)`, verify SHA256 constants declared at the top of the script (fill them from the actual downloads during implementation), extract into `~/.themes`, and print the resulting directory name. Idempotent: skip download when the target directory already exists.

- [ ] **Step 4: Create GTK fragments**

`gtk.ini` per flavour:

```ini
gtk-theme-name=Catppuccin-Latte-Mauve-standard+default
gtk-application-prefer-dark-theme=0
gtk-font-name=FiraCode Nerd Font 10
gtk-icon-theme-name=Yaru
gtk-cursor-theme-name=Yaru
```

Macchiato version uses its own theme name and `gtk-application-prefer-dark-theme=1`. Font/icon/cursor values are copied from the values in effect at implementation time (`gsettings get org.gnome.desktop.interface font-name`, `icon-theme`, `cursor-theme`).

- [ ] **Step 5: Wire gsettings and links into `theme-toggle`**

Rows: `gtk.ini:$CONFIG/gtk-3.0/settings.ini`, `gtk.ini:$CONFIG/gtk-4.0/settings.ini`. Then, when `command -v gsettings`:

```bash
theme_name=$(sed -n 's/^gtk-theme-name=//p' "$THEMES_DIR/$flavour/gtk.ini")
[[ -d "$HOME/.themes/$theme_name" ]] || theme_name=$([[ $flavour == latte ]] && echo Yaru || echo Yaru-dark)
gsettings set org.gnome.desktop.interface gtk-theme "$theme_name"
gsettings set org.gnome.desktop.interface color-scheme "$([[ $flavour == latte ]] && echo prefer-light || echo prefer-dark)"
```

- [ ] **Step 6: Run the installer, then the check**

```bash
cd ~/personal/i3-ubuntu-dotfiles && bash gtk_theme_setup.sh && cp -a _config/. "$HOME/.config/" && bash /tmp/opencode/check-task5.sh
```
Expected: `PASS`, and `ls ~/.themes` shows both Catppuccin directories.

- [ ] **Step 7: Verify the fallback**

```bash
mv ~/.themes/Catppuccin-Latte-* /tmp/opencode/gtk-bak
~/.local/bin/theme-toggle --set latte
gsettings get org.gnome.desktop.interface gtk-theme
mv /tmp/opencode/gtk-bak ~/.themes/ 2>/dev/null || true
```
Expected: `'Yaru'`, exit 0, no error output.

- [ ] **Step 8: Hook into `app_setup.sh` and README**

Run `bash ./gtk_theme_setup.sh` next to the other `*_setup.sh` invocations (or in the install section if they are not invoked there), and add `gtk_theme_setup.sh` to the installer list in `README.md`.

- [ ] **Step 9: Commit**

```bash
git add gtk_theme_setup.sh _config/themes _local/bin/theme-toggle app_setup.sh README.md
git commit -m "feat: theme GTK 3 and 4 with Catppuccin GTK"
```

---

### Task 6: Neovim follows the state file

**Files:**
- Modify: `~/.config/nvim/lua/plugins/catppuccin.lua` (outside this repo)

**Interfaces:**
- Consumes: `~/.config/theme` written by `theme-toggle`.

- [ ] **Step 1: Write the failing check**

```bash
# /tmp/opencode/check-task6.sh
set -euo pipefail
~/.local/bin/theme-toggle --set latte
out=$(nvim --headless -c 'lua print(vim.o.background)' -c 'qa' 2>&1 | tail -1)
[[ "$out" == light ]] || { echo "FAIL: latte background=$out"; exit 1; }
~/.local/bin/theme-toggle --set macchiato
out=$(nvim --headless -c 'lua print(vim.o.background)' -c 'qa' 2>&1 | tail -1)
[[ "$out" == dark ]] || { echo "FAIL: macchiato background=$out"; exit 1; }
echo PASS
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/opencode/check-task6.sh`
Expected: `FAIL: latte background=dark`.

- [ ] **Step 3: Replace the forced colourscheme**

In `~/.config/nvim/lua/plugins/catppuccin.lua`: keep the existing `require('catppuccin').setup { flavour = 'auto', ... }` table, delete `vim.cmd.colorscheme 'catppuccin-macchiato'`, and add before it:

```lua
local function apply_background()
  local ok, lines = pcall(vim.fn.readfile, vim.fn.expand('~/.config/theme'))
  local flavour = (ok and lines[1] or 'macchiato'):gsub('%s+$', '')
  vim.o.background = flavour == 'latte' and 'light' or 'dark'
  vim.cmd.colorscheme 'catppuccin'
end

apply_background()
vim.api.nvim_create_autocmd('FocusGained', { callback = apply_background })
```

- [ ] **Step 4: Run the check**

Run: `bash /tmp/opencode/check-task6.sh`
Expected: `PASS`.

- [ ] **Step 5: Verify a running instance follows a toggle**

Open `nvim`, switch to another window, run `theme-toggle`, return to nvim, and confirm the background flipped without restarting.

- [ ] **Step 6: Commit**

Neovim config is outside this repo: report the change in the PR/commit message of the dotfiles repo only if the user wants it mirrored; otherwise leave uncommitted and note it in the final summary.

---

### Task 7: Documentation and end-to-end verification

**Files:**
- Modify: `keymaps.md` (theme keybind row)
- Modify: `README.md` (theme section: state file, fragments, toggle)
- Modify: `CLAUDE.md` (theme layout convention)

- [ ] **Step 1: Write the failing check**

```bash
# /tmp/opencode/check-task7.sh
set -euo pipefail
cd ~/personal/i3-ubuntu-dotfiles
grep -q 'Super+Shift+t' keymaps.md || { echo "FAIL: keymaps"; exit 1; }
grep -q 'themes/' README.md || { echo "FAIL: readme"; exit 1; }
grep -q '_config/themes' CLAUDE.md || { echo "FAIL: claude"; exit 1; }
for f in latte macchiato; do
  for frag in i3.conf polybar.ini rofi.rasi tmux.conf alacritty.toml zathura dunstrc screenkey.json zsh-colors.zsh gtk.ini; do
    [[ -f "_config/themes/$f/$frag" ]] || { echo "FAIL: missing $f/$frag"; exit 1; }
  done
done
echo PASS
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash /tmp/opencode/check-task7.sh`
Expected: `FAIL: keymaps` (or `FAIL: missing`).

- [ ] **Step 3: Write the docs**

`keymaps.md`: add `| Super+Shift+t | Toggle Latte (light) / Macchiato (dark) |` under Applications.
`README.md`: short section — state file `~/.config/theme`, fragments in `_config/themes/`, `theme-toggle [--set latte|macchiato|--status]`, note that dunst/screenkey are whole-file symlinks.
`CLAUDE.md`: under Key Paths add `_config/themes/` — one fragment per app per flavour; never hardcode hex in app configs.

- [ ] **Step 4: Run the check**

Run: `bash /tmp/opencode/check-task7.sh`
Expected: `PASS`.

- [ ] **Step 5: End-to-end verification**

```bash
~/.local/bin/theme-toggle --set latte
i3 -C -c ~/.config/i3/config && tmux source-file ~/.config/tmux/tmux.conf && dunstctl reload && zsh -n ~/.zshrc && echo "all parse"
grep -rE '#[0-9a-fA-F]{6}' ~/.config/polybar/modules/ || echo "no inline polybar hex"
import -window root /tmp/opencode/light.png
~/.local/bin/theme-toggle --set macchiato
import -window root /tmp/opencode/dark.png
```
Confirm visually: light bar has dark text and no invisible segments; dark bar unchanged from before; nvim, rofi, dunst, terminal all follow.

- [ ] **Step 6: Commit**

```bash
git add keymaps.md README.md CLAUDE.md
git commit -m "docs: document theme toggle and fragment layout"
```
