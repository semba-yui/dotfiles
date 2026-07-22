{ pkgs, ... }:
let
  preCommitHook = pkgs.writeShellScript "git-pre-commit" ''
    set -eu

    # 検出内容に秘密値そのものを表示せず、コミット予定の差分だけを検査する。
    ${pkgs.betterleaks}/bin/betterleaks git . \
      --no-banner \
      --pre-commit \
      --redact \
      --staged

    repository_hook="$(git rev-parse --git-common-dir)/hooks/pre-commit"
    if [ -x "$repository_hook" ]; then
      "$repository_hook" "$@"
    fi
  '';

  prePushHook = pkgs.writeShellScript "git-pre-push" ''
    set -eu

    remote_name="$1"
    remote_url="$2"

    case "$remote_url" in
      https://?*@github.com/*) ;;
      https://github.com/*|https://@github.com/*|git@github.com:*|ssh://git@github.com/*)
        echo "push を拒否しました: GitHub のリモート URL にアカウント名がありません。" >&2
        echo "例: https://<github-account>@github.com/<owner>/<repository>.git" >&2
        exit 1
        ;;
    esac

    refs_file="$(mktemp)"
    trap 'rm -f "$refs_file"' EXIT HUP INT TERM
    cat > "$refs_file"

    while read -r local_ref local_oid remote_ref remote_oid; do
      case "$local_oid" in
        *[!0]*) ;;
        *) continue ;;
      esac

      case "$remote_oid" in
        *[!0]*) log_opts="$remote_oid..$local_oid" ;;
        *) log_opts="$local_oid" ;;
      esac

      echo "Betterleaks で push 対象を検査しています: $local_ref -> $remote_ref" >&2
      ${pkgs.betterleaks}/bin/betterleaks git . \
        --log-opts="$log_opts" \
        --no-banner \
        --redact
    done < "$refs_file"

    repository_hook="$(git rev-parse --git-common-dir)/hooks/pre-push"
    if [ -x "$repository_hook" ]; then
      "$repository_hook" "$remote_name" "$remote_url" < "$refs_file"
    fi
  '';
in
{
  programs.git = {
    enable = true;
    hooks = {
      pre-commit = preCommitHook;
      pre-push = prePushHook;
    };
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
