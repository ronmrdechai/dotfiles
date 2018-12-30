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
export HISTCONTROL="ignoredups:erasedups"
export LESSHISTFILE=-
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git --ignore .hg -g ""'
export PATH="$PATH:$HOME/.bin"
export PLATFORM=$(uname)

[[ -d "$HOME/.vim/bin" ]] && PATH="$HOME/.vim/bin:$PATH"

# Prompt
PS1=""
if [[ ${PLATFORM} == "Darwin" ]]; then
    scm_prompt="/opt/facebook/hg/share/scm-prompt.sh"
else
    scm_prompt="/usr/share/scm/scm-prompt.sh"
fi

if [[ -f "${scm_prompt}" ]]; then
    . ${scm_prompt}
    PS1+='\[\033[35m\]$(_scm_prompt "%s ")'
    unset scm_prompt
fi

PS1+='\[\033[37m\][\A \h \[\033[1m\]\[\033[4m\]\W\[\033[0m\]] \[\033[33m\]'
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

# LS_COLORS on Linux
if [[ ${PLATFORM} = "Linux" ]]; then
    [[ -f $HOME/.ls_colors ]] && eval $(dircolors -b $HOME/.ls_colors)
fi

# Home directory pkgsrc
if [[ -d "$HOME/pkg" ]]; then
    export PATH="$HOME/pkg/bin:$HOME/pkg/sbin:$PATH"
    export MANPATH="$HOME/pkg/share/man:$MANPATH"
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
fi

# Open tmux if installed
if [[ -z "${TMUX}" && "${PLATFORM}" == "Darwin" ]]; then
    command -v tmux >/dev/null && tm
fi
