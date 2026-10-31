#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root." 1>&2
	exit 1
fi

URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip"
SHA256="7cc4ffd8f7a1fc914cdab7b149808298165ff7a7f40e40d82dea9ebe41e8ca0b"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

curl -fL "$URL" -o "$tmp_dir/FiraCode.zip"
echo "$SHA256  $tmp_dir/FiraCode.zip" | sha256sum -c --quiet -
unzip -q "$tmp_dir/FiraCode.zip" -d "$tmp_dir/fonts"
mkdir -p "$HOME/.fonts"
cp -f "$tmp_dir/fonts/"*.ttf "$HOME/.fonts/"
fc-cache -f
