#!/bin/bash
# Status line derived from PS1 in ~/.bashrc:
#   PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:\w\[\e[1;33m\]\$(__git_ps1 ' (%s)')\[\e[0m\]\$ "
# Plus the session cost (USD) from cost.total_cost_usd, and Claude.ai rate-limit
# usage: session (5-hour) and weekly (7-day) percentages from rate_limits.
# Also the active model and reasoning effort (model.display_name, effort.level;
# effort is absent for models without effort support), plus "fast" in fast mode
# and "no think" when extended thinking is off.
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
    sys.exit()
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
# Prompt-cache time left: the cache TTL restarts on every API call that reads or
# writes it, so count down from the last assistant entry in the transcript. The
# window is 1h if that call wrote 1h-tier cache, else 5m. Reads only the tail.
cache_left = ""
cache_ttl = ""
tp = data.get("transcript_path")
if tp:
    try:
        import os
        from datetime import datetime, timezone
        with open(tp, "rb") as f:
            f.seek(0, os.SEEK_END)
            f.seek(max(0, f.tell() - 2_000_000))
            lines = f.read().splitlines()
        for raw in reversed(lines):
            if b"\"assistant\"" not in raw:
                continue
            try:
                e = json.loads(raw)
            except Exception:
                continue
            usage = (e.get("message") or {}).get("usage")
            if e.get("type") != "assistant" or not usage or not e.get("timestamp"):
                continue
            cc = usage.get("cache_creation") or {}
            ttl = 300 if cc.get("ephemeral_5m_input_tokens") and not cc.get("ephemeral_1h_input_tokens") else 3600
            ts = datetime.fromisoformat(e["timestamp"].replace("Z", "+00:00"))
            age = (datetime.now(timezone.utc) - ts).total_seconds()
            cache_left = "%d" % max(0, ttl - age)
            cache_ttl = "%d" % ttl
            break
    except Exception:
        pass
print(cwd)
print(cost)
print(pct("five_hour"))
print(pct("seven_day"))
print(ctx)
print(cache_left)
print(cache_ttl)
print((data.get("model") or {}).get("display_name") or "")
print((data.get("effort") or {}).get("level") or "")
print("1" if data.get("fast_mode") else "")
print("1" if (data.get("thinking") or {}).get("enabled") is False else "")
')

cwd="${fields[0]}"
cost="${fields[1]}"
five_h="${fields[2]}"
week="${fields[3]}"
ctx_used="${fields[4]}"
cache_left="${fields[5]}"
cache_ttl="${fields[6]}"
model="${fields[7]}"
effort="${fields[8]}"
fast="${fields[9]}"
no_think="${fields[10]}"

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

# Active model and reasoning effort, e.g. "Opus 5.5 · medium".
model_segment=""
if [ -n "$model" ]; then
    model_info="$model"
    [ -n "$effort" ] && model_info+=" · $effort"
    [ -n "$fast" ] && model_info+=" · fast"
    [ -n "$no_think" ] && model_info+=" · no think"
    model_segment=$(printf ' \033[1;34m%s\033[0m' "$model_info")
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

# Prompt-cache time left as m:ss. Green, then yellow in the last fifth of the
# window, then red "cold" once expired (the next message re-writes the cache).
cache_segment=""
if [ -n "$cache_left" ]; then
    if [ "$cache_left" -le 0 ]; then
        cache_segment=$(printf ' cache \033[1;31mcold\033[0m')
    else
        code=32
        if [ "$cache_left" -le $((cache_ttl / 5)) ]; then
            code=33
        fi
        cache_segment=$(printf ' cache \033[%sm%d:%02d\033[0m' "$code" $((cache_left / 60)) $((cache_left % 60)))
    fi
fi

printf '\033[1;32m%s@%s\033[0m:%s\033[1;33m%s\033[0m%s%s%s%s%s' "$user" "$host" "$dir" "$branch_segment" "$model_segment" "$cost_segment" "$usage_segment" "$context_segment" "$cache_segment"
