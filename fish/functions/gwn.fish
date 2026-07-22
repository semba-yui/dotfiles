function gwn --description "既存ブランチを fzf で選んで gtr worktree を作成し cd する"
    git branch --all --sort=-committerdate --format='%(refname:short)' |
        string match --invert 'origin/HEAD' |
        string replace -r '^origin/' "" |
        sort -u |
        fzf --prompt='Worktree from branch> ' \
            --preview 'git log --oneline --graph --color=always -20 {}' |
        read -l branch
    test -z "$branch"; and return

    # gtr（git gtr init fish が生成する wrapper 関数）経由で --cd を効かせる。
    # ローカル/リモートの既存ブランチは gtr がそのまま checkout / tracking する。
    gtr new $branch --cd
end
