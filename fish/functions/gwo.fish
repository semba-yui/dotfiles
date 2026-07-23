function gwo --description "gtr worktree を fzf で選んで herdr ワークスペースとして開く"
    if test "$HERDR_ENV" != 1
        echo "gwo: herdr の外では使えない（cd だけなら fzf_ghq_repos か 'gtr cd' を使う）" >&2
        return 1
    end

    # --porcelain は path\tbranch\tstatus 形式。先頭行は main worktree なので除外する。
    git gtr list --porcelain | tail -n +2 | fzf \
        --delimiter=\t \
        --with-nth=2,3 \
        --prompt='Open worktree in herdr> ' \
        --preview 'git -C {1} log --oneline --color=always -10; echo ---; git -C {1} status --short' |
        read -l selection
    test -z "$selection"; and return

    # 既存 checkout を herdr の子ワークスペースとして採用する（作成は gwn / gtr 側の責務）。
    herdr worktree open --cwd $PWD --path (string split \t -- $selection)[1]
    commandline -f repaint
end
