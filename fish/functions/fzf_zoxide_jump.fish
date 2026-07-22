function fzf_zoxide_jump --description "zoxide の frecent ディレクトリへ fzf でジャンプする"
    # zi と同等だが、widget として cd + repaint まで自前で行う。
    zoxide query --interactive | read -l destination
    if test -n "$destination"
        cd $destination
    end
    commandline -f repaint
end
