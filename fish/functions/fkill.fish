function fkill --description "fzf でプロセスを選んで kill する"
    set -l signal TERM
    if test (count $argv) -gt 0
        set signal $argv[1] # 例: fkill KILL
    end

    ps -eo pid,user,pcpu,pmem,comm | sed 1d | fzf \
        --multi \
        --header='TAB で複数選択 / enter で kill' |
        awk '{print $1}' | read --list --local pids

    test -n "$pids"; and kill -$signal $pids
end
