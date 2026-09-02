#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
flake_directory="$(cd -- "$script_directory/.." && pwd)"
repository_root="$(git -C "$flake_directory" rev-parse --show-toplevel)"

if [[ "$(git -C "$repository_root" branch --show-current)" != "main" ]]; then
  echo "dotfiles update: main ブランチで実行してください。" >&2
  exit 1
fi

if [[ -n "$(git -C "$repository_root" status --porcelain)" ]]; then
  echo "dotfiles update: 未コミットの変更があります。先に確認してください。" >&2
  exit 1
fi

echo "dotfiles の main ブランチを同期します。"
git -C "$repository_root" pull --ff-only

# Flake 入力と、nixpkgs を経由せず上流リリースへ固定している release lock を同時に更新する。
# TWG の release lock は APM skills の SHA と互換性を合わせる必要があるため、ここでは更新しない。
lock_files=(
  "$flake_directory/flake.lock"
  "$flake_directory/packages/claude-code-release.json"
  "$flake_directory/packages/codex-release.json"
)
lock_backup_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-update-locks.XXXXXX")"
for lock_file in "${lock_files[@]}"; do
  cp "$lock_file" "$lock_backup_directory/$(basename "$lock_file")"
done

restore_locks=true
cleanup() {
  exit_code=$?
  trap - EXIT

  if [[ $restore_locks == "true" ]]; then
    for lock_file in "${lock_files[@]}"; do
      cp "$lock_backup_directory/$(basename "$lock_file")" "$lock_file"
    done
    echo "dotfiles update: 更新に失敗したため lock ファイルを元に戻しました。" >&2
  fi

  rm -rf "$lock_backup_directory"
  exit "$exit_code"
}
trap cleanup EXIT

cd "$flake_directory"

echo "すべての Flake 入力を更新します。"
nix flake update

# nixpkgs 側の derivation が変わった場合に、その nixpkgs で release lock のビルドを検証するため、
# Flake 入力の更新後に実行する。
echo "Claude Code と Codex の release lock を更新します。"
"$script_directory/update-claude-code.sh"
"$script_directory/update-codex.sh"

if git -C "$repository_root" diff --quiet -- "${lock_files[@]}"; then
  echo "Flake 入力と release lock はすでに最新です。"
else
  git -C "$repository_root" diff --stat -- "${lock_files[@]}"
fi

echo "Flake 全体を検証します。"
nix flake check

hostname="$(hostname -s)"
echo "$hostname の構成をビルドし、確認後に反映します。"
nh darwin switch "$flake_directory" \
  --hostname "$hostname" \
  --ask \
  --no-update-lock-file \
  --show-activation-logs

# switch後は実環境とlockを一致させるため、commitに失敗してもlockを復元しない。
restore_locks=false

if git -C "$repository_root" diff --quiet -- "${lock_files[@]}"; then
  echo "lock ファイルの変更はありません。"
else
  git -C "$repository_root" add "${lock_files[@]}"
  git -C "$repository_root" commit -m "chore: Flake入力とrelease lockを更新"
fi

echo "更新が完了しました。確認後に git push を実行してください。"
