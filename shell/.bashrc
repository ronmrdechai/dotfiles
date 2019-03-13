# Make sure shell is interactive
[[ $- != *i* ]] && return

# Set shell options
shopt -s cdspell
shopt -s direxpand
shopt -s histappend
shopt -s checkwinsize
shopt -s no_empty_cmd_completion

# General options
export EDITOR=vim
export PAGER=less
export HISTCONTROL="ignoredups:erasedups"
export LESSHISTFILE=-
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git --ignore .hg -g ""'
export PATH="$PATH:$HOME/.bin"
export PLATFORM=$(uname)
export PYTHONWARNINGS=ignore

[[ -d "$HOME/.vim/bin" ]] && PATH="$HOME/.vim/bin:$PATH"

# Prompt
PROMPT_COMMAND='case $PWD in
        $HOME) HPWD="~";;
        $HOME/*/*) HPWD="${PWD#"${PWD%/*/*}/"}";;
        $HOME/*) HPWD="~/${PWD##*/}";;
        /*/*/*) HPWD="${PWD#"${PWD%/*/*}/"}";;
        *) HPWD="$PWD";;
      esac'

_show_command_time_prompt='$(test -n "$_show_command_time" && echo -e "[ \033[4m\A\033[0m ]\n\n")'
if [[ ${PLATFORM} == "Darwin" ]]; then
  scm_prompt="/opt/facebook/hg/share/scm-prompt.sh"
else
  scm_prompt="/usr/share/scm/scm-prompt.sh"
fi

export PS0="${_show_command_time_prompt}"

PS1=""
PS1="${_show_command_time_prompt}"
if [[ -f "${scm_prompt}" ]]; then
  . ${scm_prompt}
  PS1+='\[\033[35m\]$(_scm_prompt "%s ")'
  unset scm_prompt
fi
PS1+='\[\033[37m\][\h \[\033[1m\]\[\033[4m\]$HPWD\[\033[0m\]\[\033[37m\]] \[\033[33m\]'
PS1+='\$\[\033[0m\] '
export PS1

# Homebrew options
if [[ ${PLATFORM} == "Darwin" ]]; then
  export HOMEBREW_PREFIX="$HOME/.homebrew"
  export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
  export MANPATH="$MANPATH:$HOMEBREW_PREFIX/share/man"
  export MANPATH="$MANPATH:$HOMEBREW_PREFIX/manpages"
  export HOMEBREW_NO_EMOJI=1
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1

  [[ -f $HOMEBREW_PREFIX/etc/bash_completion ]] && \
    . $HOMEBREW_PREFIX/etc/bash_completion

  [[ -d $HOMEBREW_PREFIX/share/cmake/completions ]] && \
    for file in $HOMEBREW_PREFIX/share/cmake/completions/*; do
      . $file
    done
  fi

# Aliases
if [[ ${PLATFORM} == "Darwin" ]]; then
  alias ls="ls -FG"
  alias ll="ls -FGAlh"
else
  alias ls="ls --color=auto -F"
  alias ll="ls --color=auto -FAlh"
fi
alias vi="vim"
alias sudo="sudo "

if [[ ${PLATFORM} = "Linux" ]]; then
  # Custom LS_COLORS
  [[ -f $HOME/.ls_colors ]] && eval $(dircolors -b $HOME/.ls_colors)

  # Home directory Gentoo prefix or pkgsrc
  if [[ -d "$HOME/gentoo" ]]; then
    export PATH="$HOME/gentoo/bin:$HOME/gentoo/sbin:$PATH"
    export MANPATH="$HOME/gentoo/share/man:$MANPATH"
  elif [[ -d "$HOME/pkg" ]]; then
    export PATH="$HOME/pkg/bin:$HOME/pkg/sbin:$PATH"
    export MANPATH="$HOME/pkg/share/man:$MANPATH"
  fi
fi

# Home directory bash completions
if [[ -d "$HOME/.bash_completion.d" ]]; then
  for file in $HOME/.bash_completion.d/*; do
    source $file
  done
fi

# Edit and source ~/.bashrc
bashrc () {
  $EDITOR $HOME/.bashrc && . $HOME/.bashrc
}

# Edit ~/.vimrc
vimrc () {
  $EDITOR $HOME/.vim/vimrc
}

# Edit and source ~/.tmux.conf
tmuxconf () {
  $EDITOR $HOME/.tmux.conf
  [[ -n "$TMUX" ]] && tmux source-file $HOME/.tmux.conf
}

# Either connect to an existing tmux session, open a new one
# or close the current one depeding on the context
tm () {
  if [[ -z "$TMUX" ]]; then
    local session=${1:-$USER}
    if tmux has-session -t $session &>/dev/null; then
      tmux attach-session -d -t $session
    else
      tmux new-session -s $session
    fi
  else
    tmux detach-client
  fi
}

toggle-command-time () {
  if [[ -n "$_show_command_time" ]]; then
    unset _show_command_time
  else
    export _show_command_time=1
  fi
}

if [[ ${PLATFORM} == "Darwin" ]]; then
  # Open a file in quicklook
  function ql { qlmanage -p "$@" >/dev/null 2>&1; }

  # View a dot file
  function viewdot {
    local temp=$(mktemp ./.viewdot.XXXXXX)
    mv $temp ${temp}.png
    dot -Tpng $1 -o ${temp}.png && ql ${temp}.png
    rm ${temp}.png
  }

  # Run clang-format and produce a diff of changes
  function clang-format-diff {
    local args=()
    while grep -q "^-" <<< "$1"; do
      args+=("$1")
      shift
    done

    if [[ $# -eq 0 ]]; then
      echo "Usage: clang-format-diff [options...] <file> [<file>...]"
      return
    fi

    for file in "$@"; do
      clang-format $file | colordiff "${args[@]}" $file -
    done
  }
fi

# Source custom, untracked configurations
for bashrc in $HOME/.bash.*; do
  [[ -f "${bashrc}" ]] && source "${bashrc}"
done
