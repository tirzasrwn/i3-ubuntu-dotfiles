#!/bin/bash
set -euo pipefail

VERSION=v1.0.3
BASE_URL=https://github.com/catppuccin/gtk/releases/download/$VERSION
DEST=${XDG_DATA_HOME:-$HOME/.local/share}/themes

declare -A SHA256=(
	[catppuccin-latte-mauve-standard+default.zip]=b19da9e3048dc9357a3e55f2592a4e006aaf5654ff228f846d7b21adf7c3273e
	[catppuccin-macchiato-mauve-standard+default.zip]=b8186e47a9d09266f54b38c6e58dd2837fe53d9786532ce206c1fc3c7b658573
)

mkdir -p "$DEST"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for asset in "${!SHA256[@]}"; do
	name=${asset%.zip}
	if [[ -d $DEST/$name ]]; then
		echo "skip: $name already installed"
		continue
	fi
	curl -fsSLo "$tmp/$asset" "$BASE_URL/$asset"
	echo "${SHA256[$asset]}  $tmp/$asset" | sha256sum -c --quiet -
	unzip -q "$tmp/$asset" -d "$DEST"
	echo "installed: $DEST/$name"
done
