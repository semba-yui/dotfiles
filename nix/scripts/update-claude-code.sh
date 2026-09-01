#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
flake_directory="$(cd -- "$script_directory/.." && pwd)"
repository_root="$(git -C "$flake_directory" rev-parse --show-toplevel)"
release_lock="$flake_directory/packages/claude-code-release.json"
base_url="https://downloads.claude.ai/claude-code-releases"
platform_key="darwin-arm64"
expected_team_identifier="Q6L2SF6YDW"
temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/claude-code-update.XXXXXX")"
release_lock_backup="$temporary_directory/claude-code-release.backup.json"
restore_release_lock=false

cleanup() {
  local exit_code=$?
  trap - EXIT

  if [[ $restore_release_lock == "true" ]]; then
    cp "$release_lock_backup" "$release_lock"
    printf 'Claude Code update: 検証に失敗したため release lock を元に戻しました。\n' >&2
  fi

  rm -rf "$temporary_directory"
  exit "$exit_code"
}
trap cleanup EXIT

if ! git -C "$repository_root" diff --quiet -- "$release_lock" ||
  ! git -C "$repository_root" diff --cached --quiet -- "$release_lock"; then
  printf 'Claude Code update: release lock に未確認の変更があります。先に確認してください。\n' >&2
  exit 1
fi

printf '公式の最新バージョンを取得します。\n'
version="$(curl --fail --location --silent --show-error "$base_url/latest")"
if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Claude Code update: 公式が返したバージョンが SemVer ではありません: %s\n' "$version" >&2
  exit 1
fi

next_release_lock="$temporary_directory/claude-code-release.json"
printf '公式 manifest を取得します。\n'
curl --fail --location --silent --show-error "$base_url/$version/manifest.json" --output "$next_release_lock"

# 更新処理が未検証の上流 JSON をそのまま Nix の入力にしないよう、依存する値だけ形式を確認する。
expected_sha256="$(
  jq -e -r \
    --arg version "$version" \
    --arg platform_key "$platform_key" '
      def reject($message): error("Claude Code manifest: " + $message);
      def require($condition; $message): if $condition then . else reject($message) end;

      require(.version == $version; "version must match the published latest version")
      | require(.platforms | type == "object" and has($platform_key); "\($platform_key) platform is required")
      | .platforms[$platform_key]
      | require(.binary == "claude"; "binary name must be claude")
      | require(.checksum | type == "string" and test("^[0-9a-f]{64}$"); "checksum must be a SHA-256 digest")
      | .checksum
    ' "$next_release_lock"
)"

if cmp -s "$release_lock" "$next_release_lock"; then
  printf 'Claude Code %s はすでに最新です。\n' "$version"
  exit 0
fi

# fetchurl と同じ名前と hash 方式で取得することで、検証済みの実体をそのままビルドが再利用する。
printf '署名済み macOS arm64 artifact を取得します。\n'
artifact_store_path="$(
  nix store prefetch-file --json --name claude "$base_url/$version/$platform_key/claude" |
    jq -r '.storePath'
)"

actual_hash="$(nix hash path --algo sha256 --mode flat "$artifact_store_path")"
expected_hash="$(nix hash convert --hash-algo sha256 --to sri "$expected_sha256")"
if [[ $actual_hash != "$expected_hash" ]]; then
  printf 'Claude Code update: artifact の SHA-256 が manifest と一致しません: %s\n' "$actual_hash" >&2
  exit 1
fi

codesign --verify --deep --strict "$artifact_store_path"
actual_team_identifier="$(codesign --display --verbose=4 "$artifact_store_path" 2>&1 | awk -F= '/^TeamIdentifier=/{ print $2 }')"
if [[ $actual_team_identifier != "$expected_team_identifier" ]]; then
  printf 'Claude Code update: signer TeamIdentifier が Anthropic と一致しません: %s\n' \
    "${actual_team_identifier:-不明}" >&2
  exit 1
fi

cp "$release_lock" "$release_lock_backup"
restore_release_lock=true
cp "$next_release_lock" "$release_lock"

printf 'Claude Code %s の Nix package をビルドします。\n' "$version"
nix build "path:$flake_directory#claude-code" --no-link

restore_release_lock=false
git -C "$repository_root" diff --stat -- "$release_lock"
printf 'release lock を %s へ更新しました。switch と commit は実行していません。\n' "$version"
