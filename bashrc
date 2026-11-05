# ~/.bashrc: executed by bash(1) for non-login shells.
# Shared across machines (obscure, msit). Machine-specific tweaks go in ~/.bashrc.local

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ---------------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------------

# ~/.local/bin holds uv, uv tools, pipx apps and user-installed binaries
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Rust toolchain (only if installed)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ---------------------------------------------------------------------------
# Git branch in prompt
# ---------------------------------------------------------------------------
[ -f /usr/lib/git-core/git-sh-prompt ] && source /usr/lib/git-core/git-sh-prompt
export GIT_PS1_SHOWDIRTYSTATE=1      # * unstaged, + staged
export GIT_PS1_SHOWUNTRACKEDFILES=1  # % untracked
export GIT_PS1_SHOWUPSTREAM=auto     # < behind, > ahead, = in sync

if declare -F __git_ps1 >/dev/null; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(__git_ps1 " (%s)")\[\033[00m\]\$ '
fi

# ---------------------------------------------------------------------------
# FZF (portable: works with Debian/Ubuntu names and with older fzf versions)
# ---------------------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
    # Debian/Ubuntu name these fdfind / batcat; other distros use fd / bat
    FD=$(command -v fdfind || command -v fd)
    BAT=$(command -v batcat || command -v bat)

    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --bind shift-up:preview-up,shift-down:preview-down'

    if [ -n "$FD" ]; then
        export FZF_DEFAULT_COMMAND="$FD --type f --hidden --follow --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND="$FD --type d --hidden --follow --exclude .git"
    fi

    # Ctrl+T: syntax-highlighted preview, Ctrl+/ toggles it
    if [ -n "$BAT" ]; then
        export FZF_CTRL_T_OPTS="--preview '$BAT -n --color=always --line-range :200 {}' --bind 'ctrl-/:toggle-preview'"
    fi

    # Alt+C: directory listing preview
    export FZF_ALT_C_OPTS="--preview 'ls -la {}'"

    # fzf 0.48+ has built-in shell integration; older apt versions ship example files
    if _fzf_init=$(fzf --bash 2>/dev/null); then
        eval "$_fzf_init"
    else
        for _f in /usr/share/doc/fzf/examples/key-bindings.bash \
                  /usr/share/doc/fzf/examples/completion.bash; do
            [ -f "$_f" ] && . "$_f"
        done
    fi
    unset FD BAT _fzf_init _f
fi

# ---------------------------------------------------------------------------
# Machine-specific overrides (not part of the shared repo)
# ---------------------------------------------------------------------------
[ -f ~/.bashrc.local ] && . ~/.bashrc.local
