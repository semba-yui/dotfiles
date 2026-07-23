function gwn --description "既存ブランチを fzf で選んで gtr worktree を作成し cd する（herdr 内はワークスペース化）"
    git branch --all --sort=-committerdate --format='%(refname:short)' |
        string match --invert 'origin/HEAD' |
        string replace -r '^origin/' "" |
        sort -u |
        fzf --prompt='Worktree from branch> ' \
            --preview 'git log --oneline --graph --color=always -20 {}' |
        read -l branch
    test -z "$branch"; and return

    if test "$HERDR_ENV" = 1
        # herdr 内では現在ペインを cd させず、gtr（copy / postCreate フックが走る）で
        # 作成した checkout を子ワークスペースとして開く。作成経路は gtr に一本化する。
        gtr new $branch
        and herdr worktree open --cwd $PWD --path (git gtr go $branch)
    else
        # gtr（git gtr init fish が生成する wrapper 関数）経由で --cd を効かせる。
        # ローカル/リモートの既存ブランチは gtr がそのまま checkout / tracking する。
        gtr new $branch --cd
    end
end
