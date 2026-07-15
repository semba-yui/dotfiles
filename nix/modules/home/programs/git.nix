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
  home.file = {
    ".config/git/hooks/pre-commit".source = preCommitHook;
    ".config/git/hooks/pre-push".source = prePushHook;
  };

  programs.git = {
    enable = true;
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
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };

      diff = {
        renames = true;
        algorithm = "histogram";
      };

      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      column.ui = "auto";

      core = {
        editor = "nvim";
        excludesFile = "~/.config/git/ignore";
        # 共通の安全検査を全リポジトリへ適用しつつ、hook 内からリポジトリ固有の hook も引き継ぐ。
        hooksPath = "~/.config/git/hooks";
      };

      url."https://github.com/".insteadOf = [
        "git@github.com:"
        "ssh://git@github.com/"
      ];

      ghq.root = "~/ghq";

      gtr.ai.default = "claude";
      gtr.editor.default = "zed";
    };
  };
}
