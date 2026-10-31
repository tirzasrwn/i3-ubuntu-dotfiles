# i3 Ubuntu Dotfiles

A personal Catppuccin Macchiato-themed i3 desktop environment for Ubuntu, packaged
as a single repo of config files, helper scripts, and one-shot installers.

This is a personal configuration, not a turnkey distribution. Plan to edit a few
paths and identifiers so the desktop matches your machine before logging into i3.

## Contents

- i3 window manager with polybar, picom, rofi, dunst, alacritty, screenkey,
  gromit-mpx, zathura
- tmux with vi copy-mode and tmux-sessionizer / tmux-windowizer helpers
- zsh with antigen, powerlevel10k, and zsh-vi-mode
- A set of helper scripts in `~/.local/bin` (display toggles, screen recorder,
  battery notifier, dotfile pickers, cht.sh wrapper, cleaners)
- Bash installers for the OS packages, languages (Go, Node, Rust), dev tools
  (Neovim, Alacritty), fonts, and a backlight udev rule

## Prerequisites

- Ubuntu (or another Debian-based distro; every installer uses `apt`)
- Standard user-level tools the main installer assumes: `bash`, `git`, `wget`,
  `curl`, `unzip`, `sudo`
- An X11 session. Most configs target X11, not Wayland
- The FiraCode Nerd Font is used everywhere. Run `font_setup.sh` or install it
  yourself

## Quick Start

Run the installers from the repo root in this order. Each one is independent
and can be skipped if you do not need the tool.

```bash
git clone https://github.com/tirzasrwn/i3-ubuntu-dotfiles.git ~/i3-ubuntu-dotfiles
cd ~/i3-ubuntu-dotfiles

# 1. Base system, configs, and helper scripts (do NOT run as root)
./app_setup.sh

# 2. Backlight udev rule (requires root)
sudo ./brightness_controller_setup.sh

# 3. Fonts
./font_setup.sh

# 4. Language toolchains (run any subset)
./rust_setup.sh
./go_setup.sh
./node_setup.sh
./neovim_setup.sh

# 5. Optional apps
./multimedia_setup.sh
./brave_setup.sh
./boomer_setup.sh
./bun_setup.sh
./opencode_setup.sh
```

After the installers finish, log out, select i3 at the login manager, and log
back in.

## What the Installers Do

| Script                       | Purpose                                                                 |
|------------------------------|-------------------------------------------------------------------------|
| `app_setup.sh`               | apt packages; copies `_config/*` to `~/.config`, `_local/*` to `~/.local`, and `.profile`, `.zshrc`, `.p10k.zsh`, `.bookmark`, `.directory_list` to `$HOME`. Backs up replaced files to `~/.dotfiles-backup-<timestamp>`. Refuses to run as root. |
| `brightness_controller_setup.sh` | Writes `/etc/udev/rules.d/backlight.rules` and adds the user to the `video` group. Run with `sudo`. |
| `font_setup.sh`              | Downloads FiraCode Nerd Font v3.5.1 to `~/.fonts` and runs `fc-cache`.  |
| `rust_setup.sh`              | rustup; installs `alacritty` via apt and `tree-sitter-cli`, `bluetui` via cargo. |
| `go_setup.sh`                | Go 1.27.3 to `/usr/local/go`; installs `lazydocker` and `lazygit`.                     |
| `node_setup.sh`              | nvm v0.40.8 then Node 26.13.0.                                                |
| `neovim_setup.sh`            | Builds Neovim (stable) from source and installs with `sudo make install`.|
| `multimedia_setup.sh`        | gimp, inkscape, kdenlive, mpv, vlc.                                      |
| `brave_setup.sh`             | Pipes Brave's official installer.                                       |
| `boomer_setup.sh`            | Builds [tsoding/boomer](https://github.com/tsoding/boomer) into `~/.local/bin`. |
| `opencode_setup.sh`          | Installs [opencode](https://opencode.ai) `@opencode/cli` globally with Bun, pinned to a version. Requires `bun_setup.sh` first. |
| `bun_setup.sh`               | Installs the pinned [Bun](https://bun.sh) release into `~/.local/bin` after SHA256 verification. |

## Personalize for Your Machine

The following files contain hardcoded values that must be edited before logging
into i3. The dotfiles will not break silently, but several widgets and
keybindings will not work until these are fixed.

1. Hardcoded personal paths
   - `_config/alacritty/alacritty.toml` line 37: `import = [...]` points to
     `/home/tirzasrwn/.config/alacritty/catppuccin-macchiato.toml`. Replace
     with `$HOME/.config/alacritty/catppuccin-macchiato.toml` (or your theme
     path).
   - `_local/bin/open-note` line 4: `cd ~/vault/tirzasrwn/ && nvim .`. Point
     this at your own notes vault.

2. Hardware-specific identifiers
   - `_config/polybar/system.ini`: `sys_adapter`, `sys_battery`,
     `sys_graphics_card`, `sys_wlan_interface`, `sys_eth_interface`. The file
     header lists the commands to discover each value.
   - `_local/bin/toggle-display-mode` lines 5-6: `PRIMARY="eDP"` and
     `EXTERNAL="DisplayPort-1"`. Replace with output names from `xrandr --query`.
   - `_local/bin/fix-touchpad` auto-detects the first device whose name contains
     `touchpad`. Adjust the `grep` if that picks the wrong device.

3. Pickers and shell
   - Replace the sample `~/.bookmark` and `~/.directory_list` with your own
     entries. Lines starting with `#` are ignored.
   - `app_setup.sh` installs `zsh` but does not change the login shell. Run
     `chsh -s /usr/bin/zsh` if you want zsh as the default.

## Configuration Overview

- i3: Catppuccin color variables, `$mod = Alt`, `$cmd = Super`, 5px borders,
  5px inner gaps, `smart_gaps inverse_outer`, `smart_borders on`. Polybar is
  launched via `exec_always` from i3 config.
- Polybar: a single bar `main` at 24pt on each monitor. Modules right chain:
  `xbacklight filesystem pulseaudio xkeyboard memory cpu wlan battery tray date
  suspend poweroff`.
- Alacritty: zsh shell, FiraCode Nerd Font, Catppuccin Macchiato import,
  `live_config_reload = true`.
- tmux: prefix `C-b`, mouse on, vi copy-mode with `v`/`y` piping to xclip,
  vim-style pane navigation, custom helpers (`f`, `o`, `H`/`J`/`K`/`L`).
- rofi: drun + window + run modes, Catppuccin colors, FiraCode Nerd Font.
- picom, dunst, screenkey, gromit-mpx, zathura: full configs are in
  `_config/<app>/`.

Helper scripts under `_local/bin` (installed to `~/.local/bin`):

- `tmux-sessionizer`, `tmux-windowizer`, `tmux-cht.sh`, `tmux-cht-list`
- `open-directory`, `open-file`, `open-note`
- `toggle-app`, `toggle-display-mode`, `toggle-display-gamma`,
  `toggle-screen-record`
- `fix-touchpad`, `battery-notification`, `bell`
- `screendir`, `clean-docker-none-tag`, `clean-go-npm-cargo-cache`,
  `clean-snapd-disable-app`

For the full keybinding lists, see `keymaps.md`. The per-component readmes live
in `_config/i3/readme.md`, `_config/polybar/readme.md`, and
`_config/tmux/readme.md`.

## Reload and Validation

Common commands after editing a config:

```bash
i3-msg reload                 # apply i3 config changes
i3-msg restart                # restart i3 in place
i3 -C ~/.config/i3/config     # dry-run parse the i3 config
~/.config/polybar/launch.sh   # restart polybar
tmux source-file ~/.config/tmux/tmux.conf   # inside an existing session
rofi -show drun               # smoke-test rofi config
dunst -print                  # dump dunst rules
polybar --list-monitors       # check polybar sees all monitors
bash -n script.sh             # syntax-check a shell script
shellcheck script.sh          # lint a shell script (if installed)
```

Health-check the binaries the configs rely on:

```bash
for cmd in dex xdotool rofi flameshot feh polybar playerctl brightnessctl \
           xclip uuid nautilus dunst acpi xinput xrandr eza; do
  command -v "$cmd" || echo "MISSING: $cmd"
done
```

## Repository Layout

```
.
|-- app_setup.sh                  # main installer
|-- *_setup.sh                    # language and tool installers
|-- _config/                      # copied to ~/.config
|   |-- i3/
|   |-- alacritty/
|   |-- polybar/
|   |-- tmux/
|   |-- rofi/
|   |-- dunst/
|   |-- picom/
|   |-- zathura/
|   |-- gromit-mpx.cfg
|   `-- screenkey.json
|-- _local/bin/                   # copied to ~/.local/bin
|-- .profile                      # PATH additions, nvm loader
|-- .zshrc                        # antigen + p10k + zsh-vi-mode
|-- .p10k.zsh                     # powerlevel10k config
|-- .bookmark                     # sample bookmark list
|-- .directory_list               # sample directory list
`-- keymaps.md                    # i3, tmux, zsh keybinding tables
```

## Caveats

- The `bell` helper uses `~/bell.mp3` if present, otherwise the system bell
  sound.
- `i3/config` uses `xss-lock --transfer-sleep-lock -- i3lock ...`, which only
  works in a logind-aware session.
- `~/.local/bin` is added to `PATH` by `.profile`, so a fresh login is needed
  before invoking helpers like `boomer` or `tmux-sessionizer` from a fresh
  shell.
- `app_setup.sh` installs the runtime packages the configs reference. If a
  helper still reports a missing command, install it and update the package
  list.

## Credits

- Catppuccin color palette: https://github.com/catppuccin/catppuccin
- FiraCode Nerd Font: https://github.com/ryanoasis/nerd-fonts
- i3, polybar, picom, rofi, dunst, alacritty, tmux, powerlevel10k, zsh-vi-mode
  and the other upstream projects referenced in the configs.

## License

[MIT](LICENSE) © 2026 tirzasrwn
