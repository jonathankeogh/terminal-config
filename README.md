# terminal-config

All my terminal and Claude Code config in one place, for my Mac and Linux servers.

```
shared/   every machine: git, tmux, vim, Ghostty terminfo, shell helpers for zsh and bash
mac/      zsh (.zshrc, .zprofile) and the Brewfile
linux/    bash additions (.bashrc.local), scripts in bin/, packages.sh
claude/   Claude Code: settings, status line, global AGENTS.md, desktop status line mod
.githooks pre-commit secret check
```

## Install

```bash
git clone git@github.com:jonathankeogh/terminal-config.git ~/terminal-config
~/terminal-config/install.sh --packages
```

`--packages` first installs the tools the config uses: `mac/Brewfile` on macOS,
and on Linux (Ubuntu/Debian) `linux/packages.sh`, which uses apt plus the latest
yazi and gitleaks releases from GitHub. Leave it off to only link files.

`install.sh` symlinks each file into `$HOME`, so there is one copy of each file
and editing it anywhere edits the repo. It is safe to re-run. Any real file in
the way is moved to `~/.terminal-config-backup/<timestamp>/` first. On Linux it
leaves the distro `.bashrc` alone and appends one line that sources
`~/.bashrc.local`. It also clones the tmux plugins if they are missing.

## Secrets and per-machine settings

This repo is public, so nothing secret or machine-specific goes in it:

- **`~/.shell.local`**: secrets (`export FOO_API_KEY=...`) and shell overrides.
  `install.sh` creates it (readable only by you), and `.zshrc` / `.bashrc.local`
  source it last.
- **`~/.gitconfig.local`**: git settings for one machine, such as a work email.
  `.gitconfig` includes it last, so it wins.

As a safety net, `install.sh` points this repo's git hooks at `.githooks/`, whose
pre-commit hook runs `gitleaks` on the staged changes and refuses a commit that
contains a secret. For a false alarm, commit with `--no-verify`.

## Syncing

To sync between machines, commit and push, then `git pull` on the other machine.
New files need a `link` line in `install.sh`.

## History

This repo merged two older repos with `git subtree`, keeping their commits:
`dotfiles` (now `mac/` and `shared/`) and `claude-code-settings` (now `claude/`).
