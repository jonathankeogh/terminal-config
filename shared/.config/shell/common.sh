# Shared by zsh (mac/.zshrc) and bash (linux/.bashrc.local): keep it valid in both.
export PATH="$HOME/.local/bin:$PATH"

# yazi shell wrapper: `y` cd's to yazi's last directory on quit (q); Q quits without cd
y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}
