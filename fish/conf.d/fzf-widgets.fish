# fzf 系 widget のキー割り当て。
# fzf 本体（config.fish で source）が Ctrl-R / Ctrl-T / Alt-C を使うため、それ以外を割り当てる。
# Ctrl-] / Ctrl-O / Alt-Z は fish のデフォルト（emacs プリセット）では未使用。
# Ctrl-G は定番だがデフォルトの cancel を潰すため避けた。
status is-interactive; or exit

bind ctrl-\] fzf_ghq_repos # ghq リポジトリ + gtr worktree へ cd
bind ctrl-o fzf_git_branches # ブランチ切替
bind alt-z fzf_zoxide_jump # zoxide の frecent ディレクトリへジャンプ
