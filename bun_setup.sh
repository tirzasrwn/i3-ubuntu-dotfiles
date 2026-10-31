#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root." 1>&2
	exit 1
fi

URL="https://github.com/oven-sh/bun/releases/download/bun-v1.4.4/bun-linux-x64.zip"
SHA256="bf8ccbfb2b0b80159e0f9a6d15c55317add8077534dbc6130a3edb52fccb395c"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

curl -fsSL "$URL" -o "$tmp_dir/bun.zip"
echo "$SHA256  $tmp_dir/bun.zip" | sha256sum -c --quiet -
unzip -q "$tmp_dir/bun.zip" -d "$tmp_dir"

mkdir -p "$HOME/.local/bin"
install -m 755 "$tmp_dir/bun-linux-x64/bun" "$HOME/.local/bin/bun"
"$HOME/.local/bin/bun" --version
