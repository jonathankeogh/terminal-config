# --- Git branch ---
git_branch_name() {
  local branch
  branch=$(git symbolic-ref HEAD 2> /dev/null | awk -F/ '{print $NF}')
  [[ -n "$branch" ]] && echo "%F{cyan}[$branch]%f"
}

# --- Conda environment ---
conda_env_prompt() {
  [[ -n "$CONDA_DEFAULT_ENV" ]] && echo "%F{green}($CONDA_DEFAULT_ENV)%f"
}

# Allow $(...) in prompt
setopt prompt_subst

# --- Final prompt ---
prompt='$(git_branch_name)%F{yellow}%~%f $'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="$HOME/.local/bin:$PATH"

# opencode
export PATH=/Users/jkeogh/.opencode/bin:$PATH

# VPS: mosh + tmux (survives sleep/wifi changes); falls back to auto-reconnecting ssh
vps() {
  if command -v mosh >/dev/null && ssh -o BatchMode=yes -o ConnectTimeout=5 vps 'command -v mosh-server' >/dev/null 2>&1; then
    mosh vps -- sh -c 'tmux attach 2>/dev/null || tmux new'
    return
  fi
  while true; do
    ssh -t vps 'tmux attach 2>/dev/null || tmux new'
    [ $? -ne 255 ] && break   # 255 = connection lost; anything else = you exited/detached
    echo "\nConnection lost - reconnecting in 3s (Ctrl+C to stop)..."
    sleep 3
  done
}

# ssh into angelsea and attach to the persistent "macbook" tmux session
alias angelsea="ssh -t angelsea 'tmux new -A -s macbook'"

# Generate a video with audio on angelsea and open it here.
# Usage: vclip "prompt" [seconds]     e.g.  vclip "a fox in the snow, wind howling" 10
vclip() {
  local prompt="$1" secs="${2:-30}" name="clip-$(date +%Y%m%d-%H%M%S).mp4"
  local host="angelsea" dest="$HOME/Movies/video-gen"
  mkdir -p "$dest"
  print -r -- "$prompt" | ssh "$host" \
    "cd ~/video-gen && .venv/bin/python make_clip.py \"\$(cat)\" --seconds $secs --out outputs/$name ${*:3}" \
  && scp "$host:video-gen/outputs/$name" "$dest/" && open "$dest/$name"
}

# Turn off mouse reporting if a program left it on (stops scrolling from typing escape codes)
_reset_mouse_mode() { printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1015l' }
autoload -Uz add-zsh-hook && add-zsh-hook precmd _reset_mouse_mode
