{
  config,
  lib,
  pkgs,
  ...
}:

let
  herdrReviewr = pkgs.callPackage ../../../packages/herdr-reviewr.nix { };
  zoetrope = pkgs.callPackage ../../../packages/zoetrope.nix { };
  herdrPluginRoots = [
    herdrReviewr
    "${zoetrope}/share/herdr-plugin"
  ];
in
{
  imports = [ ./herdr.nix ];

  # zoetrope のプラグインは、PATH にある zoe を呼ぶ。
  home.packages = [ zoetrope ];

  programs.herdr.settings.keys.command = [
    # フォーカス中のエージェントのセッションを、フローグラフとして重ねて表示する。
    {
      key = "prefix+alt+z";
      type = "plugin_action";
      command = "furkankly.zoetrope.open";
    }
  ];

  # link は登録だけで、サーバーが動いていなくても通り、同じ id は新しい store のパスで置き換わる。
  # unlink はサーバーが動いていないと失敗するため自動では行わない。ここから外したプラグインは
  # `herdr plugin unlink <id>` で手動で外す。
  home.activation.linkHerdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for plugin_root in ${lib.escapeShellArgs herdrPluginRoots}; do
      run ${lib.getExe config.programs.herdr.package} plugin link "$plugin_root" >/dev/null
    done
  '';
}
