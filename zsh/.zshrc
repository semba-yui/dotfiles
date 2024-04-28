#################################  INIT  #################################

# init starship
eval "$(starship init zsh)"

# init sheldon
eval "$(sheldon source)"

# init zoxide
eval "$(zoxide init zsh)"

# init mise
eval "$(mise activate zsh)"

# init zsh-abbr
source /opt/homebrew/share/zsh-abbr/zsh-abbr.zsh

#################################  HISTORY  #################################
# history
# 履歴を保存するファイル
HISTFILE=$HOME/.zsh-history
# メモリに保存される履歴の件数
HISTSIZE=1000000
# HISTFILE で指定したファイルに保存される履歴の件数
SAVEHIST=1000000

# share .zshhistory
# 実行時に履歴をファイルに追加していく
setopt inc_append_history
# 履歴を他のシェルとリアルタイム共有する
setopt share_history
# 同じコマンドをhistoryに残さない
setopt hist_ignore_all_dups
# historyに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks
# 重複するコマンドが保存されるとき、古い方を削除する
setopt hist_save_no_dups
# 実行時に履歴をファイルに追加していく
setopt inc_append_history

# 不要なコマンドを history
zshaddhistory() {
    local line="${1%%$'\n'}"
    [[ ! "$line" =~ "^(cd|history|jj?|lazygit|la|ll|ls|eza|rm|rmdir|trash)($| )" ]]
}

#################################  eza  #################################
# eza の設定
if [[ $(command -v eza) ]]; then
    # ls は既存のコマンドを置き換えるので alias も定義して override する
    alias ls='eza --icons'
    abbr -S l='eza --icons'
    abbr -S ls='eza --icons'
    abbr -S la='eza -a --icons'
    abbr -S ll='eza -aal --icons'
    abbr -S lt='eza -T -L 3 -a -I "node_modules|.git|.cache" --icons'
    abbr -S lta='eza -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
fi

#################################  fzf  #################################

# fzf の設定
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fzf history
function fzf-select-history() {
    BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER" --reverse)
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history

# ghq と組み合わせて リポジトリをインクリメンタルに検索しつつ移動 (プレビューはREADME)
function ghq-fzf() {
    local src=$(ghq list |fzf --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/README.*")
    if [ -n "$src" ]; then
        BUFFER="cd $(ghq root)/$src"
        zle accept-line
    fi
    zle -R -c
}
zle -N ghq-fzf
bindkey '^]' ghq-fzf

#################################  man  #################################

# manにシンタックスハイライトを有効化
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;33m") \
        LESS_TERMCAP_md=$(printf "\e[1;33m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
        man "$@"
}

# GPG

GPG_TTY=$(tty)
export GPG_TTY
