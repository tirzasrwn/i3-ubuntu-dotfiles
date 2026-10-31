#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root." 1>&2
	exit 1
fi

URL="https://go.dev/dl/go1.25.0.linux-amd64.tar.gz"
SHA256="2852af0cb20a13139b3448992e69b868e50ed0f8a1e5940ee1de9e19a123b613"

tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

curl -fL "$URL" -o "$tmp_file"
echo "$SHA256  $tmp_file" | sha256sum -c --quiet -
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "$tmp_file"

export PATH="$PATH:/usr/local/go/bin"
go version

go install github.com/jesseduffield/lazydocker@latest
