{ ... }:
let
  fullName = "仙波 琉一朗 / Ryuichiro Semba";

  identities = {
    semba-yui = {
      name = fullName;
      email = "65758369+semba-yui@users.noreply.github.com";
    };
    lc-semba-ryuichiro = {
      name = fullName;
      email = "86405487+lc-semba-ryuichiro@users.noreply.github.com";
    };
  };

  # 1 つの org につき経路を 2 本張る。片方だけでは取りこぼす clone があるため。
  #   gitdir   … transport 非依存。ただし ~/ghq の外に置いた clone には効かない
  #   hasconfig… 置き場所に依存しない。ただし SSH 形式で保存された URL には効かない
  # 両方が発火しても同じ値を二重に書くだけなので害はない。
  identityByOwner = owner: identity: [
    {
      condition = "gitdir:~/ghq/github.com/${owner}/";
      contents.user = identity;
      contentSuffix = "git-identity-${owner}-gitdir.gitconfig";
    }
    {
      condition = "hasconfig:remote.*.url:https://*github.com/${owner}/**";
      contents.user = identity;
      contentSuffix = "git-identity-${owner}-remote.gitconfig";
    }
  ];
in
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
    # 順序に意味がある。git は後に読んだ include を優先するため、先に「clone 時に選んだ
    # identity」を、後に「repo が実際に属する org」を置き、org を勝たせている。
    includes =
      # 他人の repo をどの名義で触るかは owner からは決まらないので、clone 時に付けた
      # userinfo を指定として扱う。
      [
        {
          condition = "hasconfig:remote.*.url:https://semba-yui@github.com/**";
          contents.user = identities.semba-yui;
          contentSuffix = "git-identity-semba-yui.gitconfig";
        }
      ]
      ++ identityByOwner "semba-yui" identities.semba-yui
      # 既定と同値だが明示する。userinfo 由来の誤マッチをこちらで上書きするため。
      ++ identityByOwner "lc-semba-ryuichiro" identities.lc-semba-ryuichiro;
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
