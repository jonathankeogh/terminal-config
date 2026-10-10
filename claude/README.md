# claude

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

## Install

`install.sh` at the repo root symlinks `settings.json`, `statusline-command.sh` and
`AGENTS.md` into `~/.claude`, and on macOS links `desktop-statusline/` to
`~/.claude/desktop-mods/usage`. `mac/.zshrc` sets `CLAUDE_CODE_PLUGIN_DIRS` to
that path in desktop app sessions only: the app reads its environment from a
shell with no terminal attached, so terminal Claude Code never loads the mod. The
link's name, `usage`, is the label the app shows before the line. Quit and reopen
the desktop app after installing so it reads the new environment.

## Not tracked

Secrets and session data are deliberately excluded (see `.gitignore`):
credentials, command history, conversation transcripts (`projects/`), caches,
and daemon/session state.
