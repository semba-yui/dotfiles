function fzf_git_branches --description "ローカル/リモートブランチを fzf で選んで切り替える"
    if not git rev-parse --git-dir >/dev/null 2>&1
        commandline -f repaint
        return 1
    end

    git branch --all --sort=-committerdate --format='%(refname:short)' |
        string match --invert 'origin/HEAD' |
        fzf --prompt='Branch> ' \
            --preview 'git log --oneline --graph --color=always -20 {}' |
        read -l branch

    if test -n "$branch"
        # origin/ を剥がして git switch に渡す。リモートのみの場合は tracking branch が自動作成される。
        git switch (string replace -r '^origin/' "" -- $branch)
    end
    commandline -f repaint
end
