#!/usr/bin/env bash
# Tools this config uses on Ubuntu/Debian. Run by ./install.sh --packages.
# apt for the basics; yazi from its latest GitHub release into ~/.local/bin,
# since apt has none.
set -euo pipefail

sudo apt-get update -qq
sudo apt-get install -y -qq git tmux vim mosh python3 curl unzip ncurses-bin

case "$(uname -m)" in
x86_64 | aarch64) yazi_arch=$(uname -m) ;;
arm64) yazi_arch=aarch64 ;;
*) echo "no yazi release for $(uname -m); install it by hand" >&2; exit 1 ;;
esac

# release_url <owner/repo> <asset name pattern>
release_url() {
	curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
		python3 -c 'import json,re,sys; print(next(a["browser_download_url"] for a in json.load(sys.stdin)["assets"] if re.fullmatch(sys.argv[1], a["name"])))' "$2"
}

bin="$HOME/.local/bin"
mkdir -p "$bin"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if ! command -v yazi >/dev/null; then
	curl -fsSL -o "$tmp/yazi.zip" "$(release_url sxyazi/yazi "yazi-$yazi_arch-unknown-linux-gnu\.zip")"
	unzip -q "$tmp/yazi.zip" -d "$tmp"
	install -m 755 "$tmp"/yazi-*/yazi "$tmp"/yazi-*/ya "$bin/"
	echo "installed  yazi -> $bin"
fi
