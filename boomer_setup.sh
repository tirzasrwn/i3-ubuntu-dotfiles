#!/usr/bin/env bash
#
# boomer_setup.sh
# Builds and installs tsoding/boomer (Zoomer app for Linux) on Ubuntu.
#
# - Clones the repo into a temp dir with --depth=1 (shallow clone)
# - Installs only the packages needed to build it
# - Builds with nimble
# - Copies the resulting binary to $HOME/.local/bin
# - Removes any build packages that this script itself installed
# - Cleans up the temp dir
#
set -euo pipefail

REPO_URL="https://github.com/tsoding/boomer.git"
INSTALL_DIR="$HOME/.local/bin"
BIN_NAME="boomer"

# Packages required to build boomer on Debian/Ubuntu.
# (git + nim/nimble are the toolchain, the rest are the X11/GL headers boomer links against)
BUILD_PACKAGES=(git nim libgl1-mesa-dev libx11-dev libxext-dev libxrandr-dev)

TMP_DIR=""
NEWLY_INSTALLED=()

log() { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[!]\033[0m %s\n' "$*" >&2; }

cleanup() {
	local status=$?

	if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
		log "Removing temp directory: $TMP_DIR"
		rm -rf -- "$TMP_DIR"
	fi

	if [[ ${#NEWLY_INSTALLED[@]} -gt 0 ]]; then
		log "Removing build packages that were installed by this script: ${NEWLY_INSTALLED[*]}"
		sudo apt-get purge -y "${NEWLY_INSTALLED[@]}" || err "Failed to remove some packages, you may want to remove them manually."
		sudo apt-get autoremove -y || true
	fi

	exit "$status"
}
trap cleanup EXIT

is_installed() {
	dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

install_build_deps() {
	log "Checking build dependencies..."
	local to_install=()

	for pkg in "${BUILD_PACKAGES[@]}"; do
		if is_installed "$pkg"; then
			log "Already installed: $pkg"
		else
			to_install+=("$pkg")
		fi
	done

	if [[ ${#to_install[@]} -gt 0 ]]; then
		log "Installing: ${to_install[*]}"
		sudo apt-get update
		sudo apt-get install -y --no-install-recommends "${to_install[@]}"
		NEWLY_INSTALLED=("${to_install[@]}")
	else
		log "All build dependencies already present, nothing to install/remove."
	fi
}

build_boomer() {
	TMP_DIR="$(mktemp -d)"
	log "Using temp dir: $TMP_DIR"

	log "Cloning $REPO_URL (depth=1)..."
	git clone --depth 1 "$REPO_URL" "$TMP_DIR/boomer"

	cd "$TMP_DIR/boomer"

	log "Building with nimble..."
	nimble build -y

	if [[ ! -f "$BIN_NAME" ]]; then
		err "Build finished but binary '$BIN_NAME' was not found."
		exit 1
	fi

	log "Installing binary to $INSTALL_DIR"
	mkdir -p "$INSTALL_DIR"
	install -m 755 "$BIN_NAME" "$INSTALL_DIR/$BIN_NAME"
}

check_path() {
	case ":$PATH:" in
	*":$INSTALL_DIR:"*)
		ok "$INSTALL_DIR is already in your PATH."
		;;
	*)
		err "$INSTALL_DIR is not in your PATH."
		echo "  Add this to your ~/.bashrc or ~/.zshrc:"
		echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
		;;
	esac
}

main() {
	install_build_deps
	build_boomer
	ok "boomer installed at $INSTALL_DIR/$BIN_NAME"
	check_path
	echo
	echo "Try it with: $BIN_NAME --help"
}

main "$@"
