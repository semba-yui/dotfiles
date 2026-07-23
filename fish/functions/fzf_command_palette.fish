function fzf_command_palette --description "カスタム DX 操作の一覧から fzf で選んで実行する"
    # パレット自体がチートシートを兼ねる（定義がそのまま一覧なので陳腐化しない）。
    # 表示は「コマンド │ キー │ 説明」。実行文字列はタブ区切りの第2フィールドに
    # 隠し、--with-nth=1 で表示から外す。コマンド名を常に目にさせることで、
    # 頻用する操作が自然に直接入力へ移行するのを狙う。
    begin
        printf '%-18s│ %-7s│ %s\t%s\n' fzf_ghq_repos 'Ctrl-]' 'ghq リポジトリ + gtr worktree へ移動' fzf_ghq_repos
        printf '%-18s│ %-7s│ %s\t%s\n' fzf_git_branches Ctrl-O 'ブランチを切り替える' fzf_git_branches
        printf '%-18s│ %-7s│ %s\t%s\n' fzf_zoxide_jump Alt-Z 'よく行くディレクトリへジャンプ (zoxide)' fzf_zoxide_jump
        printf '%-18s│ %-7s│ %s\t%s\n' 'gtr cd' - 'worktree 一覧から移動 (Ctrl-E:エディタ / Ctrl-A:AI / Ctrl-D:削除)' 'gtr cd'
        printf '%-18s│ %-7s│ %s\t%s\n' gwn - 'ブランチを選んで worktree を作成し移動' gwn
        printf '%-18s│ %-7s│ %s\t%s\n' gwd - 'worktree を選んで削除（複数可）' gwd
        printf '%-18s│ %-7s│ %s\t%s\n' fkill - 'プロセスを選んで kill' fkill
        # herdr のペイン内でだけ意味を持つ操作は、環境変数で出し分ける。
        if test "$HERDR_ENV" = 1
            printf '%-18s│ %-7s│ %s\t%s\n' gwo - 'gtr worktree を herdr ワークスペースとして開く' gwo
        end
    end | fzf \
        --delimiter=\t \
        --with-nth=1 \
        --prompt='DX> ' \
        --header='Enter で実行' |
        read -l selection

    if test -n "$selection"
        eval (string split \t -- $selection)[2]
    end
    commandline -f repaint
end
