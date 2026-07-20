{
  config,
  lib,
  pkgs,
  ...
}:

let
  flakeDirectory = config.programs.nh.darwinFlake;

  dotfilesUpdate = pkgs.writeShellApplication {
    name = "dotfiles-update";

    runtimeInputs = [
      pkgs.git
      pkgs.nh
      pkgs.nix
    ];

    text = ''
      flake_directory=${lib.escapeShellArg flakeDirectory}
      repository_root="$(git -C "$flake_directory" rev-parse --show-toplevel)"

      if [[ "$(git -C "$repository_root" branch --show-current)" != "main" ]]; then
        echo "dotfiles-update: main ブランチで実行してください。" >&2
        exit 1
      fi

      if [[ -n "$(git -C "$repository_root" status --porcelain)" ]]; then
        echo "dotfiles-update: 未コミットの変更があります。先に確認してください。" >&2
        exit 1
      fi

      echo "dotfiles の main ブランチを同期します。"
      git -C "$repository_root" pull --ff-only

      lock_file="$flake_directory/flake.lock"
      lock_backup="$(/usr/bin/mktemp "''${TMPDIR:-/tmp}/dotfiles-flake-lock.XXXXXX")"
      /bin/cp "$lock_file" "$lock_backup"

      restore_lock=true
      cleanup() {
        exit_code=$?
        trap - EXIT

        if [[ "$restore_lock" == "true" ]]; then
          /bin/cp "$lock_backup" "$lock_file"
          echo "dotfiles-update: 更新に失敗したため flake.lock を元に戻しました。" >&2
        fi

        /bin/rm -f "$lock_backup"
        exit "$exit_code"
      }
      trap cleanup EXIT

      cd "$flake_directory"

      echo "すべての Flake 入力を更新します。"
      nix flake update

      if git -C "$repository_root" diff --quiet -- nix/flake.lock; then
        echo "Flake 入力はすでに最新です。"
      else
        git -C "$repository_root" diff -- nix/flake.lock
      fi

      echo "Flake 全体を検証します。"
      nix flake check

      hostname="$(/bin/hostname -s)"
      echo "$hostname の構成をビルドし、確認後に反映します。"
      nh darwin switch "$flake_directory" \
        --hostname "$hostname" \
        --ask \
        --no-update-lock-file \
        --show-activation-logs

      # switch後は実環境とlockを一致させるため、commitに失敗してもlockを復元しない。
      restore_lock=false

      if git -C "$repository_root" diff --quiet -- nix/flake.lock; then
        echo "flake.lock の変更はありません。"
      else
        git -C "$repository_root" add nix/flake.lock
        git -C "$repository_root" commit -m "chore: Flake入力を更新"
      fi

      echo "更新が完了しました。確認後に git push を実行してください。"
    '';
  };
in
{
  # Flake更新、検証、反映、commitを安全な順序で実行する入口を一つに統一する。
  home.packages = [ dotfilesUpdate ];
}
