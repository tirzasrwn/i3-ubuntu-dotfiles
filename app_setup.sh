#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root." 1>&2
	exit 1
fi

sudo apt update
sudo apt install -y \
	acpi \
	alsa-utils \
	blueman \
	brightnessctl \
	cowsay \
	curl \
	dex \
	dunst \
	eza \
	feh \
	ffmpeg \
	flameshot \
	fortune \
	fzf \
	git \
	gromit-mpx \
	i3-wm \
	i3lock \
	libdbus-1-dev \
	libnotify-bin \
	mate-polkit \
	mpv \
	nautilus \
	network-manager-gnome \
	pavucontrol \
	picom \
	pkg-config \
	playerctl \
	polybar \
	pulseaudio-utils \
	ripgrep \
	rofi \
	screenkey \
	tmux \
	unzip \
	uuid-runtime \
	wget \
	x11-xserver-utils \
	xclip \
	xdg-utils \
	xdotool \
	xinput \
	xss-lock \
	zathura \
	zsh

backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

backup_path() {
	local target="$1"
	if [[ -e "$target" ]]; then
		local rel="${target#"$HOME"/}"
		mkdir -p "$backup_dir/$(dirname "$rel")"
		cp -a "$target" "$backup_dir/$rel"
	fi
}

mkdir -p "$HOME/.config" "$HOME/.local"

for item in ./_config/*; do
	backup_path "$HOME/.config/$(basename "$item")"
done
for item in ./_local/*; do
	backup_path "$HOME/.local/$(basename "$item")"
done
for item in .profile .bookmark .directory_list .p10k.zsh .zshrc; do
	backup_path "$HOME/$item"
done

cp -a ./_config/. "$HOME/.config/"
cp -a ./_local/. "$HOME/.local/"
cp -a .profile .bookmark .directory_list .p10k.zsh .zshrc "$HOME/"

bash ./gtk_theme_setup.sh || echo "warn: GTK theme install failed; theme-toggle falls back to Yaru" >&2
install -m 755 ./_local/bin/theme-toggle "$HOME/.local/bin/theme-toggle"
"$HOME/.local/bin/theme-toggle" --set "$(cat "$HOME/.config/theme" 2>/dev/null || echo macchiato)"

if [[ -d "$backup_dir" ]]; then
	echo "Backed up previous files to $backup_dir"
fi
