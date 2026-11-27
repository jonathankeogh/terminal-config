# antigravity

Version-controlled backup of my Antigravity CLI (`agy`) configuration, mirroring
the `claude/` setup.

## Contents

- **`settings.json`** — Antigravity CLI settings (fullscreen alt-screen mode,
  high verbosity for full thinking/tool visibility, notifications, unlimited
  prompt history, auto agent mode + `command(ls *)`, custom status line).
  `trustedWorkspaces` is deliberately omitted from the public repo; `agy` will
  prompt once per folder on a fresh machine.
- **`statusline-command.sh`** — custom status line ported from
  `claude/statusline-command.sh`: `user@host:dir (branch)` in PS1 colors,
  active model and effort, estimated session cost, quota usage %, context window
  %, active tasks/subagents, and cached transcript disk usage. Wraps onto up to
  4 lines using `terminal_width`.
- **`hooks.json` + `dublin-time-hook.sh`** — `PreInvocation` hook injecting
  the `Europe/Dublin` date/time and day of week once per user turn.
- **`apparmor-antigravity-cli`** — optional Ubuntu 24.04+ AppArmor profile
  granting `userns` only to `/home/*/.local/bin/agy` so the terminal sandbox and
  `auto` mode work without weakening `kernel.apparmor_restrict_unprivileged_userns`
  globally.
- Global `AGENTS.md` is shared with Claude Code (`claude/AGENTS.md` linked into
  `~/.gemini/config/AGENTS.md`).

## Install

`install.sh` at the repo root symlinks:
- `antigravity/settings.json` → `~/.gemini/antigravity-cli/settings.json`
- `antigravity/statusline-command.sh` → `~/.gemini/antigravity-cli/statusline-command.sh`
- `antigravity/hooks.json` → `~/.gemini/config/hooks.json`
- `antigravity/dublin-time-hook.sh` → `~/.gemini/config/dublin-time-hook.sh`
- `claude/AGENTS.md` → `~/.gemini/config/AGENTS.md`

## Not tracked

OAuth tokens, conversation histories, `brain/` artifacts, transcripts, caches,
and logs are never stored in this repo (see `.gitignore`).
