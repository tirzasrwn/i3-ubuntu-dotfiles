#!/bin/bash

set -euo pipefail

NVM_VERSION="v0.40.8"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"
NVM_INSTALL_SHA256="48a0eee9a60e07422dce0eb5774754c83889570ca1ee2566c516acbe8af03a9e"

tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

# Download and verify nvm installer:
curl -fsSL "$NVM_INSTALL_URL" -o "$tmp_file"
echo "$NVM_INSTALL_SHA256  $tmp_file" | sha256sum -c --quiet -
bash "$tmp_file"

# in lieu of restarting the shell
# shellcheck source=/dev/null
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 26.13.0

# Verify the Node.js version:
node -v     # Should print "v26.13.0".
nvm current # Should print "v26.13.0".

# Verify npm version:
npm -v # Should print "11.20.0".
