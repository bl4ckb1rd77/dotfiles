export PATH=$PATH:"$HOME/.cargo/bin"
export ZSH="$HOME/.oh-my-zsh"
# export QT_QPA_PLATFORMTHEME="qt6ct"
ZSH_THEME=""
HIST_STAMPS="mm/dd/yyyy"
plugins=(git zsh-autosuggestions ansible archlinux)
alias kssh='kitten ssh'
alias rr='reboot-required'
alias nv='nvim'
alias webcam='mpv /dev/video0'
# alias ncmpcpp='ncmpcpp -s playlist -S browser'
# alias clear='clear; ufetch'

#[ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"

source $ZSH/oh-my-zsh.sh
# ufetch
#Star Ship
eval "$(starship init zsh)"
