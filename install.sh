#!/usr/bin/env bash
# Symlink this repo's config into $HOME. Safe to re-run: links that are already
# correct are skipped, and any real file in the way is moved to a backup folder.
# With --packages it first installs the tools the config uses (mac/Brewfile,
# linux/packages.sh).
set -euo pipefail

packages=false
for arg in "$@"; do
	case "$arg" in
	--packages) packages=true ;;
	*) echo "usage: $0 [--packages]" >&2; exit 2 ;;
	esac
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.terminal-config-backup/$(date +%Y%m%d-%H%M%S)"

link() {  # link <path in repo> <destination>
	local src="$REPO/$1" dest="$2"
	if [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then return; fi
	if [ -e "$dest" ] || [ -L "$dest" ]; then
		mkdir -p "$BACKUP/$(dirname "${dest#"$HOME"/}")"
		mv "$dest" "$BACKUP/${dest#"$HOME"/}"
		echo "backed up  ~/${dest#"$HOME"/}"
	fi
	mkdir -p "$(dirname "$dest")"
	ln -s "$src" "$dest"
	echo "linked     ~/${dest#"$HOME"/} -> $1"
}

if $packages; then
	case "$(uname -s)" in
	Darwin) brew bundle --no-upgrade --file="$REPO/mac/Brewfile" ;;
	Linux) "$REPO/linux/packages.sh" ;;
	esac
fi

# --- Every machine ---
link shared/.gitconfig        "$HOME/.gitconfig"
link shared/.config/git/ignore "$HOME/.config/git/ignore"
link shared/.config/shell/common.sh "$HOME/.config/shell/common.sh"
link shared/.tmux.conf        "$HOME/.tmux.conf"
link shared/.vimrc            "$HOME/.vimrc"
link shared/.terminfo         "$HOME/.terminfo"

link claude/settings.json         "$HOME/.claude/settings.json"
link claude/statusline-command.sh "$HOME/.claude/statusline-command.sh"
link claude/AGENTS.md             "$HOME/.claude/rules/AGENTS.md"
# Desktop app status line mod, loaded via CLAUDE_CODE_PLUGIN_DIRS in settings.json.
# Linked everywhere so that path exists; the mod stays off in terminal sessions.
link claude/desktop-statusline    "$HOME/.claude/desktop-mods/usage"

# tmux session persistence plugins (loaded by .tmux.conf)
for p in tmux-resurrect tmux-continuum; do
	[ -d "$HOME/.tmux/plugins/$p" ] ||
		git clone -q "https://github.com/tmux-plugins/$p" "$HOME/.tmux/plugins/$p"
done

# Secrets and this machine's own settings: never in the repo, sourced last by
# the shell rc files. Created once, readable only by you.
if [ ! -e "$HOME/.shell.local" ]; then
	printf '%s\n' "# This machine only, not in terminal-config: secrets (export FOO_API_KEY=...)" \
		"# and overrides. Sourced last by .zshrc / .bashrc.local." >"$HOME/.shell.local"
	chmod 600 "$HOME/.shell.local"
	echo "created    ~/.shell.local"
fi

# Block commits that contain secrets (this repo is public)
git -C "$REPO" config core.hooksPath .githooks

# --- Per OS ---
case "$(uname -s)" in
Darwin)
	link mac/.zshrc    "$HOME/.zshrc"
	link mac/.zprofile "$HOME/.zprofile"
	;;
Linux)
	link linux/.bashrc.local "$HOME/.bashrc.local"
	link linux/bin/kgpu      "$HOME/.local/bin/kgpu"
	# Keep the distro's .bashrc and append one line that loads ours
	line='[ -f ~/.bashrc.local ] && . ~/.bashrc.local  # terminal-config'
	grep -qxF "$line" "$HOME/.bashrc" 2>/dev/null || printf '\n%s\n' "$line" >> "$HOME/.bashrc"
	;;
esac

echo "done. open a new shell (or source your rc file) to pick up changes."
