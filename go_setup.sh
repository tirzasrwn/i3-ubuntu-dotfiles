#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root." 1>&2
	exit 1
fi

URL="https://go.dev/dl/go1.27.3.linux-amd64.tar.gz"
SHA256="65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40"

tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

curl -fL "$URL" -o "$tmp_file"
echo "$SHA256  $tmp_file" | sha256sum -c --quiet -
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "$tmp_file"

export PATH="$PATH:/usr/local/go/bin"
go version

go install github.com/jesseduffield/lazydocker@latest
