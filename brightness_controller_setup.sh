#!/bin/bash

set -euo pipefail

file_path="/etc/udev/rules.d/backlight.rules"

# shellcheck disable=SC2016 # $sys/$devpath are udev placeholders, not shell vars
content='ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"'

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root."
	exit 1
fi

target_user="${SUDO_USER:-$USER}"
usermod -aG video "$target_user"

echo "$content" | tee "$file_path" >/dev/null

udevadm control --reload-rules
udevadm trigger --subsystem-match=backlight

echo "Content successfully written to $file_path"
echo "Added $target_user to the video group. Log out and back in for it to apply."
