# claude-code-settings

Version-controlled backup of my [Claude Code](https://claude.com/claude-code)
configuration.

## Contents

- **`settings.json`** — Claude Code settings (model, theme, TUI mode, status line hook,
  no Claude attribution on commits or PRs).
- **`statusline-command.sh`** — custom status line: `user@host:dir (branch)`
  in PS1 colors, plus the active model and reasoning effort (e.g. `Opus 5.5 · medium`),
  session cost, Claude.ai rate-limit usage (5-hour session % and 7-day weekly %),
  context-window usage, and prompt-cache time left. Wraps onto up to 4 lines
  when the terminal is too narrow for one.
- **`desktop-statusline/`** — the status line's usage figures for the desktop
  app's Code tab, which ignores the `statusLine` setting: session cost, rate-limit
  usage, context use and prompt-cache time left. A Claude Code plugin (function
  hooks) that reads them from the plugin API and shows them with `$.ui.status`. The
  identity, model and effort segments are left out because the app shows those itself.
- **`AGENTS.md`** — global instructions applied to every project on the machine.

## Install on a new machine

Clone the repo, then symlink each file into `~/.claude`. Symlinks mean there is
only one copy of each file: edit it anywhere and the repo sees the change.

```bash
git clone git@github.com:jonathankeogh/claude-code-settings.git ~/claude-code-settings
mkdir -p ~/.claude/rules
chmod +x ~/claude-code-settings/statusline-command.sh

ln -sfn ~/claude-code-settings/settings.json         ~/.claude/settings.json
ln -sfn ~/claude-code-settings/statusline-command.sh ~/.claude/statusline-command.sh
ln -sfn ~/claude-code-settings/AGENTS.md             ~/.claude/rules/AGENTS.md
```

If `~/.claude` already has real files, move them away first — `ln -sfn` does not
replace a regular file safely in every shell:

```bash
mkdir -p ~/.claude/backups/pre-symlink
mv ~/.claude/settings.json ~/.claude/statusline-command.sh ~/.claude/rules/AGENTS.md \
   ~/.claude/backups/pre-symlink/ 2>/dev/null
```

To sync between machines, commit and push here, then `git pull` on the other
machine. Git is not automatic.

## Not tracked

Secrets and session data are deliberately excluded (see `.gitignore`):
credentials, command history, conversation transcripts (`projects/`), caches,
and daemon/session state.
