# File system (Omarchy-inspired)
if command -v eza &>/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

if command -v bat &>/dev/null; then
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
else
  alias ff='fzf'
fi
alias eff='$EDITOR "$(ff)"'

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tools
alias c='opencode --auto'
alias d='docker'
alias g='git'
alias t='tmux attach || tmux new -s Work'

# Git
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Editors / openers
n() {
  if [ "$#" -eq 0 ]; then
    command nvim .
  else
    command nvim "$@"
  fi
}

open() (
  xdg-open "$@" >/dev/null 2>&1 &
)

# zoxide-backed cd (when available)
if command -v zoxide &>/dev/null; then
  alias cd='zd'
  zd() {
    if (( $# == 0 )); then
      builtin cd ~ || return
    elif [[ -d $1 ]]; then
      builtin cd "$1" || return
    else
      if ! z "$@"; then
        echo "Error: Directory not found"
        return 1
      fi
      printf '\U000F17A9 '
      pwd
    fi
  }
fi
