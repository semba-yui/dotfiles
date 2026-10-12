{ pkgs, ... }:

let
  tode = pkgs.callPackage ../../../packages/tode.nix { };
in
{
  home.packages = [ tode ];

  # 上流の herdr プラグインは `tode --split right` を呼ぶだけで、導入時に curl | bash で本体を
  # 入れ直すため使わない。同じコマンドを直接割り当てる。
  programs.herdr.settings.keys.command = [
    {
      key = "prefix+alt+c";
      type = "shell";
      command = "tode --split right";
      description = "VS Code を右スプリットで開く";
    }
  ];
}
