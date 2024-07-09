export PATH=$PATH:"$HOME/.cargo/bin"

ZSH_THEME=""
HIST_STAMPS="mm/dd/yyyy"
HISTSIZE=10000
SAVEHIST=10000
bindkey -e

# Fixing zsh history problems on multiple terminals
setopt inc_append_history
setopt share_history

# Ignore duplicate commands in history file
setopt histignorealldups

# Fixing some keys inside zsh
autoload -Uz select-word-style
select-word-style bash

# Add highlight enabled tab completion with colors
zstyle ':completion:*' menu select
eval "$(dircolors)"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Get bash's compgen
autoload -Uz compinit
compinit
autoload -Uz bashcompinit
bashcompinit
autoload -Uz compinit
compinit

command_not_found_handler () {
    if [ -x /usr/lib/command-not-found ]
    then
        /usr/lib/command-not-found -- "$1"
        return $?
    else
        if [ -x /usr/share/command-not-found/command-not-found ]
        then
            /usr/share/command-not-found/command-not-found -- "$1"
            return $?
        else
            printf "%s: command not found\n" "$1" >&2
            return 127
        fi
    fi
}

# custom ZSH keybinds
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char

# set editor
export EDITOR="/usr/bin/nvim"

# settings for Auto Notify
export AUTO_NOTIFY_THRESHOLD=20
export AUTO_NOTIFY_EXPIRE_TIME=10000
export AUTO_NOTIFY_IGNORE=("man" "sleep" "vim" "nvim" "less" "more" "tail" "watch" "git commit" "lazygit" "top" "htop" "btop" "ssh")

# source plugins
source $HOME/.zsh.plugins

# source aliases
source $HOME/.zsh.aliases

eval "$(starship init zsh)"
