#!/bin/bash
# Status line derived from PS1 in ~/.bashrc:
#   PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:\w\[\e[1;33m\]\$(__git_ps1 ' (%s)')\[\e[0m\]\$ "
# Plus the session cost (USD) from cost.total_cost_usd, and Claude.ai rate-limit
# usage: session (5-hour) and weekly (7-day) percentages from rate_limits.
# (rate_limits appears only for Pro/Max after the first API response; each window
# may be absent, so those segments simply don't render when missing.)
# Uses python3 (not jq) so it has no extra dependencies.

input=$(cat)

# Parse the payload once; emit one field per line so paths with spaces survive.
# Read with a while loop rather than mapfile, which macOS's bash 3.2 lacks.
fields=()
while IFS= read -r line; do
    fields+=("$line")
done < <(printf '%s' "$input" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    print(); print(); print(); print(); sys.exit()
cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd") or ""
cost = (data.get("cost") or {}).get("total_cost_usd")
cost = "" if cost is None else "%.2f" % cost
rl = data.get("rate_limits") or {}
def pct(window):
    v = (rl.get(window) or {}).get("used_percentage")
    return "" if v is None else "%d" % round(v)
cw = data.get("context_window") or {}
cu = cw.get("used_percentage")
ctx = "" if cu is None else "%d" % round(cu)
print(cwd)
print(cost)
print(pct("five_hour"))
print(pct("seven_day"))
print(ctx)
')

cwd="${fields[0]}"
cost="${fields[1]}"
five_h="${fields[2]}"
week="${fields[3]}"
ctx_used="${fields[4]}"

# Abbreviate $HOME to ~ (not ${cwd/#$HOME/\~}: bash 3.2 keeps the backslash).
dir="$cwd"
if [ "$cwd" = "$HOME" ] || [ "${cwd#"$HOME"/}" != "$cwd" ]; then
    dir="~${cwd#"$HOME"}"
fi
user=$(whoami)
host=$(hostname -s)

branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

branch_segment=""
if [ -n "$branch" ]; then
    branch_segment=" ($branch)"
fi

cost_segment=""
if [ -n "$cost" ]; then
    cost_segment=$(printf ' \033[36m$%s\033[0m' "$cost")
fi

usage_segment=""
if [ -n "$five_h" ]; then
    usage_segment+=$(printf ' \033[35m%s%% sess\033[0m' "$five_h")
fi
if [ -n "$week" ]; then
    usage_segment+=$(printf ' \033[35m%s%% wk\033[0m' "$week")
fi

# Context window used %, shown against the auto-compact threshold (default 95%,
# or CLAUDE_AUTOCOMPACT_PCT_OVERRIDE if set). Used % turns red within 10 points.
context_segment=""
if [ -n "$ctx_used" ]; then
    threshold="${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-95}"
    code=32
    if [ "$ctx_used" -ge $((threshold - 10)) ]; then
        code="1;31"
    fi
    context_segment=$(printf ' ctx \033[%sm%s%%\033[0m/%s%%' "$code" "$ctx_used" "$threshold")
fi

printf '\033[1;32m%s@%s\033[0m:%s\033[1;33m%s\033[0m%s%s%s' "$user" "$host" "$dir" "$branch_segment" "$cost_segment" "$usage_segment" "$context_segment"
