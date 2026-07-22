function gwd --description "gtr worktree を fzf で選んで削除する（複数可）"
    # --porcelain は path\tbranch\tstatus 形式。先頭行は main worktree なので除外する。
    # パイプ中で git gtr rm を呼ぶと削除確認プロンプトが fzf の残り出力を読んでしまうため、
    # 選択結果を変数へ受けてからループし、stdin を端末のまま渡す。
    set -l selections (git gtr list --porcelain | tail -n +2 | fzf \
        --multi \
        --delimiter=\t \
        --with-nth=2,3 \
        --prompt='Remove worktree> ' \
        --header='TAB で複数選択 / enter で削除' \
        --preview 'git -C {1} log --oneline --color=always -10; echo ---; git -C {1} status --short')

    for line in $selections
        git gtr rm (string split \t -- $line)[2]
    end
end
