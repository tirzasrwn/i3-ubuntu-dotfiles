#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root." 1>&2
	exit 1
fi

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

sudo apt update
sudo apt install -y \
	alacritty \
	cmake \
	g++ \
	libfontconfig1-dev \
	libfreetype6-dev \
	libxcb-icccm4-dev \
	libxcb-keysyms1-dev \
	libxcb-render0-dev \
	libxcb-shape0-dev \
	libxcb-util0-dev \
	libxcb-xfixes0-dev \
	libxkbcommon-dev \
	pkg-config \
	python3

"$HOME/.cargo/bin/cargo" install tree-sitter-cli
"$HOME/.cargo/bin/cargo" install bluetui
