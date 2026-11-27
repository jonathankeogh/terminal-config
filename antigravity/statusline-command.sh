#!/bin/bash
# Status line for Antigravity CLI, ported from claude/statusline-command.sh.
# Shows: user@host:dir (branch) in PS1 colors, active model + effort, estimated
# session cost (USD), Gemini and Claude+GPT quota usage (5h & weekly), context
# window usage %, last-call cache hit % + age, active tasks / subagents, and
# disk used by saved transcripts.
# Wraps onto up to 4 lines using live terminal_width from the JSON payload.
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
cost_val = (data.get("cost") or {}).get("total_usd")
cost = "" if cost_val is None else "%.2f" % cost_val
cw = data.get("context_window") or {}
cu = cw.get("used_percentage")
ctx = "" if cu is None else "%d" % round(cu)
m = data.get("model") or {}
model = m.get("display_name") or m.get("id") or ""
effort = m.get("effort") or ""
# Avoid duplicating effort if display_name already includes it, e.g. "Gemini 4 Neon (High)"
if effort and effort.lower() in model.lower():
    effort = ""

# Quota buckets: group Gemini (gemini-*) and Claude+GPT (3p-*) into clean 5h/wk indicators
q = data.get("quota") or {}
def used_pct(key):
    v = q.get(key)
    if not isinstance(v, dict) or v.get("disabled"):
        return None
    rf = v.get("remaining_fraction")
    if rf is None:
        return None
    return max(0, min(100, round((1.0 - rf) * 100)))

def fmt_group(prefix, label):
    parts = []
    p5 = used_pct(f"{prefix}-5h")
    pw = used_pct(f"{prefix}-weekly")
    if p5 is not None:
        parts.append(f"{p5}%/5h")
    if pw is not None:
        parts.append(f"{pw}%/wk")
    return f"{label} " + " ".join(parts) if parts else ""

gem_q = fmt_group("gemini", "gem")
tp_q = fmt_group("3p", "claude+gpt")
known = {"gemini-5h", "gemini-weekly", "3p-5h", "3p-weekly"}
extra_q = []
for k, v in sorted(q.items()):
    if k in known or not isinstance(v, dict) or v.get("disabled"):
        continue
    rf = v.get("remaining_fraction")
    if rf is not None:
        extra_q.append(f"{max(0, min(100, round((1.0 - rf) * 100)))}% {k}")
other_q = " ".join(extra_q)

# Cache hit % and age since last PLANNER_RESPONSE in transcript.jsonl (reads tail only).
cache_pct = ""
cache_age = ""
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
            if b"PLANNER_RESPONSE" not in raw:
                continue
            try:
                e = json.loads(raw)
            except Exception:
                continue
            if e.get("type") != "PLANNER_RESPONSE" or not e.get("created_at"):
                continue
            inp = e.get("input_tokens") or 0
            cr = e.get("cache_read_tokens") or 0
            tot = inp + cr
            if tot > 0:
                cache_pct = "%d" % round(100 * cr / tot)
            ts = datetime.fromisoformat(e["created_at"].replace("Z", "+00:00"))
            age = max(0, int((datetime.now(timezone.utc) - ts).total_seconds()))
            cache_age = str(age)
            break
    except Exception:
        pass
if not cache_pct:
    cu_obj = cw.get("current_usage") or {}
    cr = cu_obj.get("cache_read_input_tokens") or 0
    cc = cu_obj.get("cache_creation_input_tokens") or 0
    inp = cu_obj.get("input_tokens") or 0
    tot = inp + cc + cr
    if tot > 0:
        cache_pct = "%d" % round(100 * cr / tot)

tasks = data.get("task_count") or 0
subs = sum(1 for s in (data.get("subagents") or []) if isinstance(s, dict) and s.get("status") == "running")
tw = data.get("terminal_width") or ""
print(cwd)
print(cost)
print(gem_q)
print(tp_q)
print(other_q)
print(ctx)
print(cache_pct)
print(cache_age)
print(model)
print(effort)
print(str(tasks) if tasks else "")
print(str(subs) if subs else "")
print(str(tw))
')

cwd="${fields[0]}"
cost="${fields[1]}"
gem_q="${fields[2]}"
tp_q="${fields[3]}"
other_q="${fields[4]}"
ctx_used="${fields[5]}"
cache_pct="${fields[6]}"
cache_age="${fields[7]}"
model="${fields[8]}"
effort="${fields[9]}"
tasks="${fields[10]}"
subs="${fields[11]}"
tw="${fields[12]}"

# Abbreviate $HOME to ~ (not ${cwd/#$HOME/\~}: bash 3.2 keeps the backslash).
dir="$cwd"
if [ "$cwd" = "$HOME" ] || [ "${cwd#"$HOME"/}" != "$cwd" ]; then
    dir="~${cwd#"$HOME"}"
fi
user=$(whoami)
host=$(hostname -s)

branch=""
if [ -n "$cwd" ] && git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

branch_segment=""
if [ -n "$branch" ]; then
    branch_segment=" ($branch)"
fi

model_segment=""
if [ -n "$model" ]; then
    model_info="$model"
    [ -n "$effort" ] && model_info+=" · $effort"
    model_segment=$(printf ' \033[1;34m%s\033[0m' "$model_info")
fi

cost_segment=""
if [ -n "$cost" ]; then
    cost_segment=$(printf ' \033[36m$%s\033[0m' "$cost")
fi

gem_segment=""
if [ -n "$gem_q" ]; then
    gem_segment=$(printf ' \033[35m%s\033[0m' "$gem_q")
fi

tp_segment=""
if [ -n "$tp_q" ]; then
    tp_segment=$(printf ' \033[35m%s\033[0m' "$tp_q")
fi

other_q_segment=""
if [ -n "$other_q" ]; then
    other_q_segment=$(printf ' \033[35m%s\033[0m' "$other_q")
fi

# Context window used %. Turns bold red at >= 85%.
context_segment=""
if [ -n "$ctx_used" ]; then
    code=32
    if [ "$ctx_used" -ge 85 ]; then
        code="1;31"
    fi
    context_segment=$(printf ' ctx \033[%sm%s%%\033[0m' "$code" "$ctx_used")
fi

# Last-call cache hit % and age since last model response.
cache_segment=""
if [ -n "$cache_pct" ] || [ -n "$cache_age" ]; then
    age_str=""
    if [ -n "$cache_age" ]; then
        if [ "$cache_age" -ge 3600 ]; then
            age_str="$((cache_age / 3600))h$(((cache_age % 3600) / 60))m"
        elif [ "$cache_age" -ge 60 ]; then
            age_str="$((cache_age / 60))m"
        else
            age_str="${cache_age}s"
        fi
    fi
    if [ -n "$cache_pct" ]; then
        if [ "$cache_pct" -eq 0 ]; then
            label="cold"
            code="1;31"
        elif [ "$cache_pct" -lt 30 ]; then
            label="${cache_pct}%"
            code="1;31"
        elif [ "$cache_pct" -lt 80 ]; then
            label="${cache_pct}%"
            code=33
        else
            label="${cache_pct}%"
            code=32
        fi
        [ -n "$age_str" ] && label+=" · $age_str"
        cache_segment=$(printf ' cache \033[%sm%s\033[0m' "$code" "$label")
    else
        cache_segment=$(printf ' cache \033[2m%s\033[0m' "$age_str")
    fi
fi

activity_segment=""
if [ -n "$tasks" ] || [ -n "$subs" ]; then
    parts=""
    [ -n "$subs" ] && parts+="${subs} sub"
    [ -n "$tasks" ] && parts+="${parts:+ }${tasks} task"
    activity_segment=$(printf ' \033[33m%s\033[0m' "$parts")
fi

# Disk used by saved Antigravity transcripts & artifacts (brain/ + conversations/),
# measured in the background when over 10 minutes old.
transcripts_segment=""
agy_dir="$HOME/.gemini/antigravity-cli"
size_cache="${XDG_CACHE_HOME:-$HOME/.cache}/antigravity-statusline-transcripts-kb"
if [ -d "$agy_dir/brain" ] || [ -d "$agy_dir/conversations" ]; then
    if [ -z "$(find "$size_cache" -mmin -10 2>/dev/null)" ]; then
        mkdir -p "$(dirname "$size_cache")" && touch "$size_cache"
        ( kb=$(du -sk "$agy_dir/brain" "$agy_dir/conversations" 2>/dev/null | awk '{s+=$1} END {print s}') \
            && [ -n "$kb" ] && printf '%s' "$kb" > "$size_cache.tmp" \
            && mv "$size_cache.tmp" "$size_cache" ) </dev/null >/dev/null 2>&1 &
    fi
    kb=$(cat "$size_cache" 2>/dev/null)
    case "$kb" in
        ''|*[!0-9]*) ;;
        *)
            if [ "$kb" -ge 1048576 ]; then
                size=$(awk -v k="$kb" 'BEGIN { printf "%.1fGB", k / 1048576 }')
            else
                size="$((kb / 1024))MB"
            fi
            transcripts_segment=$(printf ' \033[2mtranscripts %s\033[0m' "$size")
            ;;
    esac
fi

identity=$(printf '\033[1;32m%s@%s\033[0m:%s\033[1;33m%s\033[0m' "$user" "$host" "$dir" "$branch_segment")

# Pack segments into up to 4 lines using terminal_width (falling back to $COLUMNS / stty).
cols="${tw:-${COLUMNS:-}}"
if [ -z "$cols" ]; then
    cols=$( { stty size </dev/tty; } 2>/dev/null | cut -d' ' -f2)
fi
case "$cols" in
    ''|*[!0-9]*|0) width=0 ;;
    *) width=$((cols - 4)) ;;
esac
max_lines=4

visible_len() {
    printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g' | LC_ALL=C.UTF-8 wc -m | tr -d ' '
}

out=""
line=""
line_len=0
lines=1
for seg in "$identity" "$model_segment" "$cost_segment" "$gem_segment" "$tp_segment" "$other_q_segment" "$context_segment" "$cache_segment" "$activity_segment" "$transcripts_segment"; do
    seg="${seg# }"
    [ -z "$seg" ] && continue
    len=$(visible_len "$seg")
    if [ -z "$line" ]; then
        line="$seg"
        line_len=$len
    elif [ "$width" -gt 0 ] && [ $((line_len + 1 + len)) -gt "$width" ] && [ "$lines" -lt "$max_lines" ]; then
        out+="$line"$'\n'
        line="$seg"
        line_len=$len
        lines=$((lines + 1))
    else
        line+=" $seg"
        line_len=$((line_len + 1 + len))
    fi
done
printf '%s%s' "$out" "$line"
