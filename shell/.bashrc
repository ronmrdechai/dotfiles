# Make sure shell is interactive
[[ $- != *i* ]] && return

# Set shell options
shopt -s cdspell
shopt -s direxpand 2>/dev/null || true
shopt -s histappend
shopt -s checkwinsize
shopt -s no_empty_cmd_completion

# General options
export EDITOR=nvim
export PAGER=less
export GIT_PAGER=less
export HISTCONTROL="ignoredups:erasedups"
export LESSHISTFILE=-
export FZF_DEFAULT_COMMAND='rg --hidden --ignore .git --ignore .hg -g ""'
export PLATFORM=$(uname)
export PYTHONWARNINGS=ignore

# Prompt
PROMPT_COMMAND='case $PWD in
        $HOME) HPWD="~";;
        $HOME/*/*) HPWD="${PWD#"${PWD%/*/*}/"}";;
        $HOME/*) HPWD="~/${PWD##*/}";;
        /*/*/*) HPWD="${PWD#"${PWD%/*/*}/"}";;
        *) HPWD="$PWD";;
      esac'

_show_command_time_prompt='test -n "$_show_command_time" && echo -e "[ \033[4m$(date +%T)\033[0m ]"'
PS0="\$(${_show_command_time_prompt} && echo -e \\n)"
PROMPT_COMMAND+="; ${_show_command_time_prompt}"

if [[ ${PLATFORM} == "Darwin" ]]; then
  scm_prompt="${scm_prompt:-/opt/facebook/hg/share/scm-prompt.sh}"
  if [[ -z "${git_prompt:-}" ]]; then
    for git_prompt in \
      /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh \
      /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-prompt.sh \
      /opt/homebrew/etc/bash_completion.d/git-prompt.sh \
      /usr/local/etc/bash_completion.d/git-prompt.sh; do
      [[ -f "${git_prompt}" ]] && break
    done
  fi
else
  scm_prompt="${scm_prompt:-/usr/share/scm/scm-prompt.sh}"
  if [[ -z "${git_prompt:-}" ]]; then
    for git_prompt in \
      /usr/share/git-core/contrib/completion/git-prompt.sh \
      /usr/share/git/completion/git-prompt.sh \
      /etc/bash_completion.d/git-prompt; do
      [[ -f "${git_prompt}" ]] && break
    done
  fi
fi

PS1=""
if [[ -f "${scm_prompt}" ]]; then
  . "${scm_prompt}"
  PS1+='\[\033[35m\]$(_scm_prompt "%s ")'
elif [[ -f "${git_prompt}" ]]; then
  . ${git_prompt}
  PS1+='\[\033[35m\]$(__git_ps1 "%s ")'
fi
PS1+='\[\033[37m\][\h \[\033[1m\]\[\033[4m\]$HPWD\[\033[0m\]\[\033[37m\]] \[\033[33m\]'
PS1+='\$\[\033[0m\] '

# Edit path like variables
pathedit () {
  local var=$1
  local elem=$2
  eval $var="$elem:\$$var"
}

pathedit PATH "$HOME/.vim/bin"
pathedit PATH "$HOME/.bin"
pathedit PATH "$HOME/bin"
pathedit PATH "$HOME/.cargo/bin"
pathedit PATH "$HOME/.local/bin"

# Homebrew options
if [[ ${PLATFORM} == "Darwin" ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  pathedit PATH "$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin"
  pathedit MANPATH "$HOMEBREW_PREFIX/share/man:$HOMEBREW_PREFIX/manpages"
  export HOMEBREW_NO_EMOJI=1
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1

  [[ -f $HOMEBREW_PREFIX/etc/bash_completion ]] && \
    . $HOMEBREW_PREFIX/etc/bash_completion

  [[ -d $HOMEBREW_PREFIX/share/cmake/completions ]] && \
    for file in $HOMEBREW_PREFIX/share/cmake/completions/*; do
      . $file
    done
  pathedit PATH /opt/homebrew/opt/coreutils/libexec/gnubin
fi

if [[ ${PLATFORM} = "Linux" ]]; then
  # Custom LS_COLORS
  [[ -f $HOME/.ls_colors ]] && eval $(dircolors -b $HOME/.ls_colors)

  # Home directory Gentoo prefix or pkgsrc
  if [[ -d "$HOME/gentoo" ]]; then
    pathedit PATH "$HOME/gentoo/bin:$HOME/gentoo/sbin"
    pathedit MANPATH "$HOME/gentoo/share/man"
  elif [[ -d "$HOME/pkg" ]]; then
    pathedit PATH "$HOME/pkg/bin:$HOME/pkg/sbin"
    pathedit MANPATH "$HOME/pkg/share/man"
  fi
fi

# Aliases
alias ls="ls --color=auto -F"
alias ll="ls --color=auto -FAlh"
alias vim="nvim"
alias vi="vim"
alias sudo="sudo "

# Home directory bash completions
if [[ -d "$HOME/.bash_completion.d" ]]; then
  for file in $HOME/.bash_completion.d/*; do
    source $file
  done
fi

# Home directory prefix
if [[ -d "$HOME/.prefix" ]]; then
    pathedit PATH "$HOME/.prefix/bin:$HOME/.prefix/sbin"
    pathedit MANPATH "$HOME/.prefix/share/man"
fi

# Unset helpers
unset scm_prompt
unset git_prompt
unset pathedit

# Edit and source ~/.bashrc
bashrc () {
  $EDITOR $HOME/.bashrc && . $HOME/.bashrc
}

# Edit ~/.vimrc
vimrc () {
  $EDITOR $HOME/.config/nvim/init.lua
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

vc () {
  ${EDITOR} $(git ls-files --others --exclude-standard && git diff --name-only --diff-filter=d HEAD^)
}

vd () {
  ${EDITOR} $(git ls-files --others --exclude-standard && git diff --name-only --diff-filter=d)
}

vf () {
  local files
  IFS=$'\n' files=($(fzf --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR} "${files[@]}"
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
