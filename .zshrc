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
