# claude-code-settings

Version-controlled backup of my [Claude Code](https://claude.com/claude-code)
configuration.

## Contents

- **`settings.json`** — Claude Code settings (model, theme, TUI mode, status line hook).
- **`statusline-command.sh`** — custom status line: `user@host:dir (branch)`
  in PS1 colors, plus session cost and Claude.ai rate-limit usage
  (5-hour session % and 7-day weekly %).

## Install on a new machine

```bash
cp settings.json          ~/.claude/settings.json
cp statusline-command.sh  ~/.claude/statusline-command.sh
chmod +x                  ~/.claude/statusline-command.sh
```

## Not tracked

Secrets and session data are deliberately excluded (see `.gitignore`):
credentials, command history, conversation transcripts (`projects/`), caches,
and daemon/session state.
