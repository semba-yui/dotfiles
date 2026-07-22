{ ... }:

{
  programs.fzf = {
    enable = true;

    # find ではなく fd を使い、.git を除外しつつ隠しファイルも検索対象にする。
    defaultCommand = "fd --type f --hidden --follow --exclude .git";

    defaultOptions = [
      "--height 60%"
      "--layout=reverse"
      "--border"
    ];

    # Ctrl-T: ファイル選択。bat でシンタックスハイライト付きプレビュー。
    fileWidget = {
      command = "fd --type f --hidden --follow --exclude .git";
      options = [
        "--preview 'bat --style=numbers --color=always --line-range :200 {}'"
      ];
    };

    # Alt-C: ディレクトリ移動。eza のツリーでプレビュー。
    changeDirWidget = {
      command = "fd --type d --hidden --follow --exclude .git";
      options = [
        "--preview 'eza --tree --level=2 --color=always {}'"
      ];
    };
  };
}
