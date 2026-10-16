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

# TWG の release lock は flake.nix の twg-cli 入力（skills）の rev と互換性を合わせる必要があるため、ここでは更新しない。
lock_files=(
  "$flake_directory/flake.lock"
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

echo "Flake 入力を更新します。"
"$script_directory/update-flake-inputs.sh" "$flake_directory"

if git -C "$repository_root" diff --quiet -- "${lock_files[@]}"; then
  echo "Flake 入力はすでに最新です。"
else
  git -C "$repository_root" diff --stat -- "${lock_files[@]}"
fi

# キャッシュにない版が降りてくると、検証の途中でソースからのビルドが始まり 1 時間近くかかることがある。
# flake check は現在のホストに限らず全ホストの構成と自作パッケージをビルドするため、checks 全体を見る。
# 自作パッケージは入力が動くたびにソースからビルドされ、そのまま進めてよいことが多いため、中断ではなく確認にする。
echo "ローカルでソースからビルドするパッケージを確認します。"
system="$(nix config show system)"
check_names="$(nix eval --json ".#checks.$system" --apply builtins.attrNames | jq -r '.[]')"
check_installables=()
while IFS= read -r check_name; do
  check_installables+=(".#checks.$system.$check_name")
done <<<"$check_names"
# 取得するだけのパスは出力パスで表示されるため、.drv で終わる行がビルド予定の derivation になる。
dry_run_log="$(nix build --dry-run --no-link "${check_installables[@]}" 2>&1)"
source_build_names="$(
  sed -nE 's|^ +(/nix/store/[^ ]+\.drv)$|\1|p' <<<"$dry_run_log" |
    nix derivation show --stdin |
    jq -r -f "$script_directory/list-source-builds.jq"
)"
if [[ -n $source_build_names ]]; then
  echo "次のパッケージはバイナリキャッシュになく、ローカルでソースからビルドします。"
  while IFS= read -r source_build_name; do
    echo "  $source_build_name"
  done <<<"$source_build_names"
  read -r -p "このまま検証と反映に進みますか？ [y/N] " local_build_consent
  if [[ $local_build_consent != [yY] ]]; then
    echo "dotfiles update: ローカルでのビルドを避けるため中断しました。" >&2
    exit 1
  fi
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
  git -C "$repository_root" commit -m "chore: Flake入力を更新"
fi

echo "更新が完了しました。確認後に git push を実行してください。"
