# Keymaps

## i3 (`_config/i3/config`)

Modifiers:
- `$mod` = `Alt`
- `$cmd` = `Super` (Windows key)

### Applications

| Key             | Action                              |
| --------------- | ----------------------------------- |
| `Alt+Return`    | Open terminal (alacritty)           |
| `Alt+Shift+q`   | Kill focused window                 |
| `Alt+d`         | App launcher (rofi drun)            |
| `Super+l`       | Lock screen (i3lock)                |
| `Super+Shift+s` | Screenshot (flameshot gui)          |
| `Super+Shift+q` | Boomer (zoom without leaving mouse) |
| `Super+u`       | Generate UUID, copy to clipboard    |

### Focus

| Key                       | Action            |
| ------------------------- | ----------------- |
| `Alt+j` / `Alt+Left`     | Focus left        |
| `Alt+k` / `Alt+Down`      | Focus down        |
| `Alt+l` / `Alt+Up`        | Focus up          |
| `Alt+;` / `Alt+Right`    | Focus right       |
| `Alt+a`                   | Focus parent      |
| `Alt+space`               | Toggle tiling/floating focus |

### Move window

| Key                                | Action       |
| ---------------------------------- | ------------ |
| `Alt+Shift+j` / `Alt+Shift+Left`  | Move left    |
| `Alt+Shift+k` / `Alt+Shift+Down`  | Move down    |
| `Alt+Shift+l` / `Alt+Shift+Up`    | Move up      |
| `Alt+Shift+;` / `Alt+Shift+Right` | Move right   |

### Layout

| Key                | Action                         |
| ------------------ | ------------------------------ |
| `Alt+h`            | Split horizontal               |
| `Alt+v`            | Split vertical                 |
| `Alt+f`            | Toggle fullscreen               |
| `Alt+s`            | Stacking layout                |
| `Alt+w`            | Tabbed layout                  |
| `Alt+e`            | Toggle split layout            |
| `Alt+Shift+space`  | Toggle floating                |

### Workspaces

| Key            | Action                       |
| -------------- | ---------------------------- |
| `Alt+1`-`Alt+0` | Switch to workspace 1-10    |
| `Alt+Shift+1`-`Alt+Shift+0` | Move window to workspace 1-10 |
| `Alt+x`        | Move workspace to next output |

### Resize (`Alt+r` enters resize mode)

| Key       | Action             |
| --------- | ------------------ |
| `j` / `Left`  | Shrink width   |
| `k` / `Down`  | Grow height    |
| `l` / `Up`    | Shrink height  |
| `;` / `Right` | Grow width     |
| `Return` / `Escape` / `Alt+r` | Exit resize mode |

### System

| Key                    | Action                              |
| ---------------------- | ----------------------------------- |
| `Alt+Shift+c`          | Reload i3 config                    |
| `Alt+Shift+r`          | Restart i3                          |
| `Alt+Shift+e`          | Exit i3 (with confirmation)         |
| `XF86AudioRaiseVolume` | Volume up (+10%)                    |
| `XF86AudioLowerVolume` | Volume down (-10%)                  |
| `XF86AudioMute`        | Toggle output mute                  |
| `XF86AudioMicMute`     | Toggle microphone mute              |
| `XF86AudioPlay`        | Media play (playerctl)              |
| `XF86AudioPause`       | Media pause (playerctl)             |
| `XF86AudioNext`        | Media next (playerctl)              |
| `XF86AudioPrev`        | Media previous (playerctl)          |
| `XF86MonBrightnessUp`  | Brightness up (brightnessctl)       |
| `XF86MonBrightnessDown`| Brightness down (brightnessctl)     |

### Super-key helpers

| Key                  | Action                                                   |
| -------------------- | -------------------------------------------------------- |
| `Super+b`            | Pick bookmark from `~/.bookmark`, paste at cursor        |
| `Super+h`            | Pick command from `~/.zsh_history`, paste at cursor      |
| `Super+d`            | Pick directory from `~/.directory_list`, open in nautilus |
| `Super+f`            | Pick file from `~/.directory_list`, open with xdg-open/zathura |
| `Super+p`            | Toggle display mode                                      |
| `Super+o`            | Toggle display gamma                                     |
| `Super+k`            | Toggle screenkey                                         |
| `Super+Shift+r`      | Toggle screen record                                     |

### Window rules

| Title                    | Rule       |
| ------------------------ | ---------- |
| `Picture-in-Picture`     | Sticky     |

---

## tmux (`_config/tmux/tmux.conf`)

Prefix: `Ctrl+b` (press twice to send literal `Ctrl+b`)

### General

| Key         | Action                              |
| ----------- | ----------------------------------- |
| `Ctrl+b r`  | Reload tmux config                  |
| `Ctrl+b x`  | Kill current window (with confirmation) |
| `Ctrl+b X`  | Kill current session (with confirmation) |
| `Ctrl+b ^`  | Jump to last window                 |

### Pane navigation (vim-like)

| Key          | Action          |
| ------------ | --------------- |
| `Ctrl+b h`   | Select pane left  |
| `Ctrl+b j`   | Select pane down  |
| `Ctrl+b k`   | Select pane up    |
| `Ctrl+b l`   | Select pane right |

### Copy mode (vi keys)

| Key | Action                                            |
| --- | ------------------------------------------------- |
| `v` | Begin selection                                   |
| `y` | Copy selection and cancel (copies to clipboard)   |

### Window/pane launchers

| Key         | Action                                                      |
| ----------- | ----------------------------------------------------------- |
| `Ctrl+b f`  | New window running `tmux-sessionizer`                        |
| `Ctrl+b N`  | New window running `open-note` (neovim)                     |
| `Ctrl+b o`  | New window running `tmux-cht.sh` (cheat sheet)              |
| `Ctrl+b D`  | Open `todo.md` in current path or `~/todo.md` in new pane  |
| `Ctrl+b H`  | Sessionizer on `~/personal`                                 |
| `Ctrl+b J`  | Sessionizer on `~/work`                                     |
| `Ctrl+b K`  | Sessionizer on `~/Downloads`                                |
| `Ctrl+b L`  | Sessionizer on `~/Pictures`                                 |

### Popups

| Key         | Action                                          |
| ----------- | ----------------------------------------------- |
| `Ctrl+b g`  | lazygit popup (current pane directory)          |
| `Ctrl+b a`  | opencode popup (current pane directory)         |
| `Ctrl+b e`  | lazydocker popup (current pane directory)       |

---

## zsh (`.zshrc`)

- `jj` exits insert mode (zsh-vi-mode)
- `Up` / `Down` — history substring search