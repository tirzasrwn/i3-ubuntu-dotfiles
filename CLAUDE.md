# Project Instructions

Personal i3/Ubuntu dotfiles for one machine. No application code: the repo is
config + install scripts deployed into `$HOME`.

## Deploy Model

`app_setup.sh` is the only deploy path:

- `_config/*` → `~/.config/`
- `_local/*` → `~/.local/`
- `.profile`, `.zshrc`, `.p10k.zsh`, `.bookmark`, `.directory_list` → `$HOME/`
- existing targets are copied to `~/.dotfiles-backup-<timestamp>/` first

Never run as root. Do not add a second copy mechanism.

## Key Paths

- `_config/i3/config` — window manager, keybinds, autostart
- `_config/polybar/` — bar; `config.ini` includes `modules/*.ini`
- `_local/bin/` — shell helpers on `PATH` via `.profile`
- `app_setup.sh` — apt package list + deploy
- `*_setup.sh` — independent tool installers (rust, go, node, neovim, fonts,
  multimedia, brave, boomer, opencode)

## Code Style

- Bash: `#!/bin/bash` + `set -euo pipefail`; root-running scripts check
  `EUID` and refuse otherwise.
- Quote all expansions. No `eval`. Prefer `read -r`, `command -v`, `mktemp`.
- `_local/bin/tmux-cht-list` is a data file, not a script; keep it out of
  shellcheck.
- Colors follow Catppuccin Macchiato across i3/polybar/rofi/dunst/tmux.
- Downloads must be pinned and SHA256-verified; if upstream publishes no
  checksum, say so in a comment.

## Verify Before Claiming Done

```bash
for f in *.sh _local/bin/* _config/polybar/launch.sh; do bash -n "$f"; done
bash -n .profile && zsh -n .zshrc
i3 -C -c _config/i3/config
jq . _config/screenkey.json >/dev/null
ls *.sh _local/bin/* _config/polybar/launch.sh | grep -v tmux-cht-list \
  | xargs -d '\n' shellcheck -S info -x
```

No automated tests exist; behavior changes need manual smoke tests
(`i3-msg reload`, new tmux server, keybind checks).

## Commit Style

Conventional prefixes, imperative, one logical change per commit:
`fix:`, `feat:`, `docs:`, `ci:`, `chore:`. Do not commit local
`.directory_list` edits unless intended.

## Gotchas

- Hardware values live in `_config/polybar/system.ini` and
  `_local/bin/toggle-display-mode`; README lists what to edit.
- `_local/bin/fix-touchpad` auto-detects the touchpad; no hardcoded device.
- Brightness keys use `brightnessctl` percentages; the udev rule from
  `brightness_controller_setup.sh` grants access via the `video` group.
- Re-run `app_setup.sh` after editing `_config/` or `_local/`; edits in the
  repo do not affect the live session until deployed.
