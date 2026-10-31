#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root." 1>&2
	exit 1
fi

URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/FiraCode.zip"
SHA256="239395baf60c89b2eaf4862b6b09db0ef95605cd3e8eef51c00345822a81a665"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

curl -fL "$URL" -o "$tmp_dir/FiraCode.zip"
echo "$SHA256  $tmp_dir/FiraCode.zip" | sha256sum -c --quiet -
unzip -q "$tmp_dir/FiraCode.zip" -d "$tmp_dir/fonts"
mkdir -p "$HOME/.fonts"
cp -f "$tmp_dir/fonts/"*.ttf "$HOME/.fonts/"
fc-cache -f
