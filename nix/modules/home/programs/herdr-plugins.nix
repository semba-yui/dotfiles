{
  config,
  lib,
  pkgs,
  ...
}:

let
  herdrFileViewer = pkgs.callPackage ../../../packages/herdr-file-viewer.nix { };
  herdrReviewr = pkgs.callPackage ../../../packages/herdr-reviewr.nix { };
  zoetrope = pkgs.callPackage ../../../packages/zoetrope.nix { };
  herdrPluginRoots = [
    herdrFileViewer
    herdrReviewr
    "${zoetrope}/share/herdr-plugin"
  ];
in
{
  imports = [
    ./agent-skills.nix
    ./herdr.nix
  ];

  # zoetrope のプラグインは、PATH にある zoe を呼ぶ。
  home.packages = [ zoetrope ];

  # エージェントがファイルや行を Files ペインで開いて見せられるよう、file-viewer 同梱の skill を同じ版で配る。
  programs.agent-skills = {
    sources.herdr-file-viewer = {
      path = herdrFileViewer;
      subdir = "skills";
      filter.maxDepth = 1;
    };
    skills.enableAll = [ "herdr-file-viewer" ];
  };

  programs.herdr.settings.keys.command = [
    # 読み取り専用のファイルビューアを、git の差分や Markdown の表示つきで右に開く。
    {
      key = "prefix+alt+f";
      type = "plugin_action";
      command = "herdr-file-viewer.open-file-viewer";
    }
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
