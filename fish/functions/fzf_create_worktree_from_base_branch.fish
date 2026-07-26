function resolve_gtr_worktree_default_remote --description "gtr が worktree 作成に使う default remote を解決する"
    set -l configuredRemote (git config --get gtr.defaultRemote)
    if test -n "$configuredRemote"
        echo "$configuredRemote"
    else
        echo origin
    end
end

function create_gtr_worktree_from_base_branch --description "指定した base から新規 branch と gtr worktree を作成する"
    if test (count $argv) -ne 3
        echo "usage: create_gtr_worktree_from_base_branch <base-branch> <new-branch> <default-remote>" >&2
        return 2
    end

    set -l baseBranch "$argv[1]"
    set -l newBranch "$argv[2]"
    set -l defaultRemote "$argv[3]"

    if not git check-ref-format --branch "$newBranch" >/dev/null 2>&1
        echo "fzf_create_worktree_from_base_branch: 不正な branch 名: $newBranch" >&2
        return 1
    end

    if git show-ref --verify --quiet "refs/heads/$newBranch"
        echo "fzf_create_worktree_from_base_branch: local branch が既に存在する: $newBranch" >&2
        return 1
    end

    if git show-ref --verify --quiet "refs/remotes/$defaultRemote/$newBranch"
        echo "fzf_create_worktree_from_base_branch: $defaultRemote に branch が既に存在する: $newBranch" >&2
        return 1
    end

    set -l gtrArguments \
        new "$newBranch" \
        --from "$baseBranch" \
        --track none \
        --remote "$defaultRemote" \
        --no-fetch

    if test "$HERDR_ENV" = 1
        set -l repositoryDirectory "$PWD"
        gtr $gtrArguments
        or return

        set -l worktreePath (git gtr go "$newBranch")
        or return

        herdr worktree open --cwd "$repositoryDirectory" --path "$worktreePath"
    else
        gtr $gtrArguments --cd
    end
end

function select_gtr_worktree_base_branch --description "local と default remote から worktree の base branch を選択する"
    set -l defaultRemote "$argv[1]"

    git for-each-ref \
        --sort=-committerdate \
        --format='%(refname:short)' \
        refs/heads \
        "refs/remotes/$defaultRemote" |
        string match --invert "$defaultRemote/HEAD" |
        fzf \
            --prompt='Base branch> ' \
            --header='Enter で base branch を選択' \
            --preview 'git log --oneline --graph --color=always -20 {}'
end

function prompt_new_gtr_worktree_branch_name --description "新規 gtr worktree の branch 名を入力する"
    read --local --prompt-str='New branch> ' newBranch
    or return
    echo "$newBranch"
end

function fzf_create_worktree_from_base_branch --description "base branch を fzf で選んで新規 branch と gtr worktree を作成する"
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "fzf_create_worktree_from_base_branch: Git repository の中で実行してください" >&2
        commandline -f repaint
        return 1
    end

    set -l defaultRemote (resolve_gtr_worktree_default_remote)
    if git remote get-url "$defaultRemote" >/dev/null 2>&1
        git fetch --prune "$defaultRemote"
        or begin
            echo "fzf_create_worktree_from_base_branch: $defaultRemote の fetch に失敗しました" >&2
            commandline -f repaint
            return 1
        end
    else if test (count (git remote)) -gt 0
        echo "fzf_create_worktree_from_base_branch: default remote '$defaultRemote' が存在しません" >&2
        commandline -f repaint
        return 1
    end

    set -l baseBranch (select_gtr_worktree_base_branch "$defaultRemote")
    if test -z "$baseBranch"
        commandline -f repaint
        return
    end

    set -l newBranch (prompt_new_gtr_worktree_branch_name)
    if test -z "$newBranch"
        commandline -f repaint
        return
    end

    create_gtr_worktree_from_base_branch "$baseBranch" "$newBranch" "$defaultRemote"
    set -l creationStatus $status
    commandline -f repaint
    return $creationStatus
end
