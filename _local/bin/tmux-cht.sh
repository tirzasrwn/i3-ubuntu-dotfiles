#!/bin/bash

set -euo pipefail

SCRIPT_PATH="${XDG_CACHE_HOME:-$HOME/.cache}/cht.sh"
mkdir -p "$(dirname "$SCRIPT_PATH")"

# cht.sh publishes no versioned checksum, so integrity relies on HTTPS only.
if [[ ! -s "$SCRIPT_PATH" ]]; then
	curl -fsSL https://cht.sh/:cht.sh -o "$SCRIPT_PATH"
fi

LIST="$HOME/.local/bin/tmux-cht-list"
selected=$(fzf --print-query --prompt="cht.sh/" <"$LIST" | tail -1)
[[ -n "$selected" ]] || exit 0

tmux neww bash -c "bash \"$SCRIPT_PATH\" \"$selected\" | sed 's/\x1b\[[0-9;]*m//g' | less -S"
