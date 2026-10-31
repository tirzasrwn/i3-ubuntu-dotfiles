#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root." 1>&2
	exit 1
fi

VERSION="2.2.5"

if ! command -v bun >/dev/null 2>&1; then
	echo "bun not found; run ./bun_setup.sh first." 1>&2
	exit 1
fi

bun add -g "@opencode/cli@$VERSION"
"$HOME/.bun/bin/opencode" --version
