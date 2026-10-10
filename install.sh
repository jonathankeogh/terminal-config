#!/usr/bin/env bash
# Symlink this repo's config into $HOME. Safe to re-run: links that are already
# correct are skipped, and any real file in the way is moved to a backup folder.
set -euo pipefail

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

# --- Every machine ---
link shared/.gitconfig        "$HOME/.gitconfig"
link shared/.config/git/ignore "$HOME/.config/git/ignore"
link shared/.tmux.conf        "$HOME/.tmux.conf"
link shared/.vimrc            "$HOME/.vimrc"
link shared/.terminfo         "$HOME/.terminfo"

link claude/settings.json         "$HOME/.claude/settings.json"
link claude/statusline-command.sh "$HOME/.claude/statusline-command.sh"
link claude/AGENTS.md             "$HOME/.claude/rules/AGENTS.md"

# tmux session persistence plugins (loaded by .tmux.conf)
for p in tmux-resurrect tmux-continuum; do
	[ -d "$HOME/.tmux/plugins/$p" ] ||
		git clone -q "https://github.com/tmux-plugins/$p" "$HOME/.tmux/plugins/$p"
done

# --- Per OS ---
case "$(uname -s)" in
Darwin)
	link mac/.zshrc    "$HOME/.zshrc"
	link mac/.zprofile "$HOME/.zprofile"
	# Desktop app status line mod; .zshrc loads it in desktop sessions only
	link claude/desktop-statusline "$HOME/.claude/desktop-mods/usage"
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
