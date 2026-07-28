{ ... }:
{
  programs.git = {
    enable = true;
    ignores = [
      # macOS が作成するメタデータは、プロジェクトの種類にかかわらず追跡しない。
      ".AppleDouble"
      ".DS_Store"
      ".LSOverride"
      "._*"

      # エディタやローカルツールが作成する、共有する意味のない状態だけを除外する。
      "*.swo"
      "*.swp"
      "*~"
      ".idea/**/shelf/"
      ".idea/**/tasks.xml"
      ".idea/**/usage.statistics.xml"
      ".idea/**/workspace.xml"
      "**/.claude/settings.local.json"

      # JavaScript の依存物は再生成可能であり、リポジトリをまたいで追跡しない。
      "node_modules/"
    ];
    includes = [
      {
        # remote URL に対応する identity だけを適用し、global fallback による誤帰属を防ぐ。
        condition = "hasconfig:remote.*.url:https://semba-yui@github.com/**";
        contents.user = {
          email = "65758369+semba-yui@users.noreply.github.com";
          name = "仙波 琉一朗 / Ryuichiro Semba";
        };
        contentSuffix = "git-identity-semba-yui.gitconfig";
      }
    ];
    settings = {
      user = {
        name = "仙波 琉一朗 / Ryuichiro Semba";
        email = "86405487+lc-semba-ryuichiro@users.noreply.github.com";
      };

      init.defaultBranch = "main";

      color.ui = "auto";

      commit = {
        verbose = true;
        gpgsign = false;
      };

      pull.rebase = true;

      rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
      };

      merge.conflictStyle = "zdiff3";

      rerere = {
        enabled = true;
        autoupdate = true;
      };

      push = {
        autoSetupRemote = true;
        default = "simple";
        followTags = true;
        useForceIfIncludes = true;
      };

      diff = {
        algorithm = "histogram";
        colorMoved = "zebra";
        colorMovedWS = "allow-indentation-change";
        renames = true;
      };

      fetch = {
        prune = true;
        pruneTags = true;
        writeCommitGraph = true;
      };

      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      column.ui = "auto";

      core = {
        editor = "nvim";
        # macOS のファイル名正規化と Git の表現差を吸収し、意図しない名前変更を防ぐ。
        precomposeUnicode = true;
      };

      ghq.root = "~/ghq";

      gtr.ai.default = "claude";
      gtr.editor.default = "zed";

      alias = {
        co = "checkout";
      };
    };
  };
}
