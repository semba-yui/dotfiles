function fzf_ghq_repos --description "ghq リポジトリと gtr worktree を fzf で選んで cd する"
    set -l root (ghq root)

    # ghq list は <repo>-worktrees/<branch>（深さ4・.git がファイル）を拾わない場合が
    # あるため、fd の走査結果をマージしてどちらの挙動でも一覧が欠けないようにする。
    begin
        ghq list
        fd --exact-depth 4 --type d . $root |
            string replace -r "^$root/" "" |
            string trim --right --chars=/ |
            string match -r '.*-worktrees/[^/]+$'
    end | sort -u | fzf \
        --prompt='Repo> ' \
        --preview "eza --tree --level=1 --color=always $root/{}" |
        read -l destination

    if test -n "$destination"
        cd $root/$destination
    end
    commandline -f repaint
end
