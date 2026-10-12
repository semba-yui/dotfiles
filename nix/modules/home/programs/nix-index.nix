{ inputs, ... }:
{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  # 未導入のコマンドを打ったときに含むパッケージを示し、`, <command>` で導入せずに一度だけ実行できるようにする。
  programs.nix-index-database.comma.enable = true;
}
