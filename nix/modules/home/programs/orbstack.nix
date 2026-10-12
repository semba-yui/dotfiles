_: {
  # OrbStack は初回起動時に ~/.ssh/config へこの Include を書き込むが、Home Manager が ssh_config を管理すると
  # その追記は失われる。ホスト定義より前に置く必要があるため includes で先頭に宣言する。
  programs.ssh.includes = [ "~/.orbstack/ssh/config" ];
}
