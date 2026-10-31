#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root." 1>&2
	exit 1
fi

sudo apt update
sudo apt install -y build-essential cmake gettext git ninja-build unzip curl

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

git clone --depth 1 --branch stable https://github.com/neovim/neovim "$tmp_dir/neovim"
cd "$tmp_dir/neovim"
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
