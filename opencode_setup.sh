#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root." 1>&2
	exit 1
fi

URL="https://github.com/anomalyco/opencode/releases/download/v1.19.5/opencode-linux-x64.tar.gz"
SHA256="588310a336fa3b9df36b3f0225b26f679d453efaad0cf3d66c3651ef3ec1647a"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

curl -fsSL "$URL" -o "$tmp_dir/opencode.tar.gz"
echo "$SHA256  $tmp_dir/opencode.tar.gz" | sha256sum -c --quiet -
tar -xzf "$tmp_dir/opencode.tar.gz" -C "$tmp_dir"

mkdir -p "$HOME/.local/bin"
install -m 755 "$tmp_dir/opencode" "$HOME/.local/bin/opencode"
"$HOME/.local/bin/opencode" --version
