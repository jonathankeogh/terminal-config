# terminal-config

All my terminal and Claude Code config in one place, for my Mac and Linux servers.

```
shared/   every machine: git, tmux, vim, Ghostty terminfo
mac/      zsh (.zshrc, .zprofile)
linux/    bash additions (.bashrc.local) and scripts in bin/
claude/   Claude Code: settings, status line, global AGENTS.md, desktop status line mod
```

## Install

```bash
git clone git@github.com:jonathankeogh/terminal-config.git ~/terminal-config
~/terminal-config/install.sh
```

`install.sh` symlinks each file into `$HOME`, so there is one copy of each file
and editing it anywhere edits the repo. It is safe to re-run. Any real file in
the way is moved to `~/.terminal-config-backup/<timestamp>/` first. On Linux it
leaves the distro `.bashrc` alone and appends one line that sources
`~/.bashrc.local`. It also clones the tmux plugins if they are missing.

To sync between machines, commit and push, then `git pull` on the other machine.
New files need a `link` line in `install.sh`.

## History

This repo merged two older repos with `git subtree`, keeping their commits:
`dotfiles` (now `mac/` and `shared/`) and `claude-code-settings` (now `claude/`).
