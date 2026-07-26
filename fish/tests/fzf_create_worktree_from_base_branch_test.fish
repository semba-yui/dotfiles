set -l testDirectory (path dirname (status filename))
source "$testDirectory/../functions/fzf_create_worktree_from_base_branch.fish"

set -g recordedGtrCalls
set -g recordedHerdrCalls
set -g invalidBranchName
set -g existingBranchRef
set -g gtrExitStatus 0
set -g insideGitRepository 1
set -g defaultRemoteExists 1
set -g defaultRemoteFetchStatus 0
set -g selectedBaseBranch origin/main
set -g promptedNewBranch feature/search
set -g baseBranchSelectionCount 0
set -g newBranchPromptCount 0

function git
    if test "$argv[1]" = rev-parse
        return (test "$insideGitRepository" = 1)
    end

    if test "$argv[1]" = config
        return 1
    end

    if test "$argv[1]" = remote; and test "$argv[2]" = get-url
        return (test "$defaultRemoteExists" = 1)
    end

    if test "$argv[1]" = remote
        if test "$defaultRemoteExists" = 1
            echo origin
        end
        return
    end

    if test "$argv[1]" = fetch
        return $defaultRemoteFetchStatus
    end

    if test "$argv[1]" = check-ref-format
        test "$invalidBranchName" != 1
        return
    end

    if test "$argv[1]" = show-ref
        test "$argv[4]" = "$existingBranchRef"
        return
    end

    if test "$argv[1]" = gtr; and test "$argv[2]" = go
        echo "/tmp/worktrees/$argv[3]"
        return
    end

    return 1
end

function gtr
    set -a recordedGtrCalls (string join " " -- $argv)
    return $gtrExitStatus
end

function herdr
    set -a recordedHerdrCalls (string join " " -- $argv)
end

function commandline
end

function select_gtr_worktree_base_branch
    set -g baseBranchSelectionCount (math $baseBranchSelectionCount + 1)
    echo "$selectedBaseBranch"
end

function prompt_new_gtr_worktree_branch_name
    set -g newBranchPromptCount (math $newBranchPromptCount + 1)
    echo "$promptedNewBranch"
end

function reset_worktree_creation_test_state
    set -g recordedGtrCalls
    set -g recordedHerdrCalls
    set -g invalidBranchName
    set -g existingBranchRef
    set -g gtrExitStatus 0
    set -g insideGitRepository 1
    set -g defaultRemoteExists 1
    set -g defaultRemoteFetchStatus 0
    set -g selectedBaseBranch origin/main
    set -g promptedNewBranch feature/search
    set -g baseBranchSelectionCount 0
    set -g newBranchPromptCount 0
    set -e HERDR_ENV
end

function assert_worktree_creation_equal
    set -l expected "$argv[1]"
    set -l actual "$argv[2]"
    set -l message "$argv[3]"

    if test "$expected" != "$actual"
        echo "FAIL: $message" >&2
        echo "  expected: $expected" >&2
        echo "  actual:   $actual" >&2
        exit 1
    end
end

reset_worktree_creation_test_state
create_gtr_worktree_from_base_branch origin/main feature/search origin
assert_worktree_creation_equal 0 "$status" "通常環境では worktree 作成に成功する"
assert_worktree_creation_equal \
    "new feature/search --from origin/main --track none --remote origin --no-fetch --cd" \
    "$recordedGtrCalls[1]" \
    "通常環境では新規 branch を作成して移動する"
assert_worktree_creation_equal 0 (count $recordedHerdrCalls) "通常環境では herdr を呼ばない"

reset_worktree_creation_test_state
create_gtr_worktree_from_base_branch origin/main feature/search >/dev/null 2>&1
assert_worktree_creation_equal 2 "$status" "base・新規 branch・remote の不足を usage error として扱う"
assert_worktree_creation_equal 0 (count $recordedGtrCalls) "引数不足では gtr を呼ばない"

reset_worktree_creation_test_state
set -g HERDR_ENV 1
create_gtr_worktree_from_base_branch origin/main feature/search origin
assert_worktree_creation_equal 0 "$status" "herdr 内では worktree 作成とワークスペース化に成功する"
assert_worktree_creation_equal \
    "new feature/search --from origin/main --track none --remote origin --no-fetch" \
    "$recordedGtrCalls[1]" \
    "herdr 内では現在ペインを移動しない"
assert_worktree_creation_equal \
    "worktree open --cwd "(pwd)" --path /tmp/worktrees/feature/search" \
    "$recordedHerdrCalls[1]" \
    "herdr 内では作成した worktree を子ワークスペースとして開く"

reset_worktree_creation_test_state
set -g invalidBranchName 1
create_gtr_worktree_from_base_branch origin/main "invalid branch" origin >/dev/null 2>&1
assert_worktree_creation_equal 1 "$status" "不正な branch 名を拒否する"
assert_worktree_creation_equal 0 (count $recordedGtrCalls) "不正な branch 名では gtr を呼ばない"

reset_worktree_creation_test_state
set -g existingBranchRef refs/heads/feature/search
create_gtr_worktree_from_base_branch origin/main feature/search origin >/dev/null 2>&1
assert_worktree_creation_equal 1 "$status" "既存の local branch 名を拒否する"
assert_worktree_creation_equal 0 (count $recordedGtrCalls) "既存の local branch 名では gtr を呼ばない"

reset_worktree_creation_test_state
set -g existingBranchRef refs/remotes/origin/feature/search
create_gtr_worktree_from_base_branch origin/main feature/search origin >/dev/null 2>&1
assert_worktree_creation_equal 1 "$status" "既存の remote branch 名を拒否する"
assert_worktree_creation_equal 0 (count $recordedGtrCalls) "既存の remote branch 名では gtr を呼ばない"

reset_worktree_creation_test_state
set -g HERDR_ENV 1
set -g gtrExitStatus 1
create_gtr_worktree_from_base_branch origin/main feature/search origin >/dev/null 2>&1
assert_worktree_creation_equal 1 "$status" "gtr の作成失敗を返す"
assert_worktree_creation_equal 0 (count $recordedHerdrCalls) "作成失敗時は herdr を呼ばない"

reset_worktree_creation_test_state
set -g insideGitRepository 0
fzf_create_worktree_from_base_branch >/dev/null 2>&1
assert_worktree_creation_equal 1 "$status" "Git repository 外では失敗する"
assert_worktree_creation_equal 0 "$baseBranchSelectionCount" "Git repository 外では base branch を選択しない"
assert_worktree_creation_equal 0 (count $recordedGtrCalls) "Git repository 外では gtr を呼ばない"

reset_worktree_creation_test_state
set -g defaultRemoteFetchStatus 1
fzf_create_worktree_from_base_branch >/dev/null 2>&1
assert_worktree_creation_equal 1 "$status" "default remote の fetch 失敗を返す"
assert_worktree_creation_equal 0 "$baseBranchSelectionCount" "fetch 失敗時は base branch を選択しない"
assert_worktree_creation_equal 0 (count $recordedGtrCalls) "fetch 失敗時は gtr を呼ばない"

reset_worktree_creation_test_state
set -g selectedBaseBranch
fzf_create_worktree_from_base_branch >/dev/null 2>&1
assert_worktree_creation_equal 0 "$status" "base branch の選択キャンセルを正常終了として扱う"
assert_worktree_creation_equal 1 "$baseBranchSelectionCount" "base branch picker を一度だけ開く"
assert_worktree_creation_equal 0 "$newBranchPromptCount" "base branch の選択キャンセル時は新規 branch 名を尋ねない"
assert_worktree_creation_equal 0 (count $recordedGtrCalls) "base branch の選択キャンセル時は gtr を呼ばない"

reset_worktree_creation_test_state
set -g promptedNewBranch
fzf_create_worktree_from_base_branch >/dev/null 2>&1
assert_worktree_creation_equal 0 "$status" "新規 branch 名の入力キャンセルを正常終了として扱う"
assert_worktree_creation_equal 1 "$newBranchPromptCount" "新規 branch 名を一度だけ尋ねる"
assert_worktree_creation_equal 0 (count $recordedGtrCalls) "新規 branch 名の入力キャンセル時は gtr を呼ばない"

echo "PASS: fzf_create_worktree_from_base_branch"
