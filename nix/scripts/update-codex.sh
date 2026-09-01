#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
flake_directory="$(cd -- "$script_directory/.." && pwd)"
repository_root="$(git -C "$flake_directory" rev-parse --show-toplevel)"
release_lock="$flake_directory/packages/codex-release.json"
latest_release_url="https://api.github.com/repos/openai/codex/releases/latest"
download_base_url="https://github.com/openai/codex/releases/download"
artifact_name="codex-package-aarch64-apple-darwin.tar.gz"
checksums_name="codex-package_SHA256SUMS"
expected_team_identifier="2DC432GLL2"
temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/codex-update.XXXXXX")"
release_lock_backup="$temporary_directory/codex-release.backup.json"
restore_release_lock=false

cleanup() {
  local exit_code=$?
  trap - EXIT

  if [[ $restore_release_lock == "true" ]]; then
    cp "$release_lock_backup" "$release_lock"
    printf 'Codex update: 検証に失敗したため release lock を元に戻しました。\n' >&2
  fi

  rm -rf "$temporary_directory"
  exit "$exit_code"
}
trap cleanup EXIT

if ! git -C "$repository_root" diff --quiet -- "$release_lock" ||
  ! git -C "$repository_root" diff --cached --quiet -- "$release_lock"; then
  printf 'Codex update: release lock に未確認の変更があります。先に確認してください。\n' >&2
  exit 1
fi

# 上流は stable と同じ速さで alpha を出すため、tag 一覧の先頭ではなく latest release を正とする。
printf '公式の最新 stable リリースを取得します。\n'
tag="$(
  curl --fail --location --silent --show-error "$latest_release_url" |
    jq -e -r '.tag_name'
)"
if [[ ! $tag =~ ^rust-v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Codex update: stable リリースではない tag を受け取りました: %s\n' "$tag" >&2
  exit 1
fi
version="${tag#rust-v}"

if [[ "$(jq -r '.version' "$release_lock")" == "$version" ]]; then
  printf 'Codex %s はすでに最新です。\n' "$version"
  exit 0
fi

artifact_url="$download_base_url/$tag/$artifact_name"

checksums_file="$temporary_directory/$checksums_name"
printf '公開 checksum を取得します。\n'
curl --fail --location --silent --show-error "$download_base_url/$tag/$checksums_name" --output "$checksums_file"
expected_sha256="$(awk -v name="$artifact_name" '$2 == name { print $1 }' "$checksums_file")"
if [[ ! $expected_sha256 =~ ^[0-9a-f]{64}$ ]]; then
  printf 'Codex update: %s の SHA-256 を %s から取得できません。\n' "$artifact_name" "$checksums_name" >&2
  exit 1
fi

# fetchurl と同じ名前と hash 方式で取得することで、検証済みの実体をそのままビルドが再利用する。
printf '署名済み macOS arm64 artifact を取得します。\n'
artifact_store_path="$(
  nix store prefetch-file --json --name "$artifact_name" "$artifact_url" |
    jq -r '.storePath'
)"

actual_hash="$(nix hash path --algo sha256 --mode flat "$artifact_store_path")"
expected_hash="$(nix hash convert --hash-algo sha256 --to sri "$expected_sha256")"
if [[ $actual_hash != "$expected_hash" ]]; then
  printf 'Codex update: artifact の SHA-256 が公開 checksum と一致しません: %s\n' "$actual_hash" >&2
  exit 1
fi

# codex は補助バイナリを同梱するため、PATH へ出す実行ファイルをすべて検証する。
extract_directory="$temporary_directory/extract"
mkdir -p "$extract_directory"
tar -xzf "$artifact_store_path" -C "$extract_directory"
for executable_path in "$extract_directory/bin/codex" "$extract_directory/bin/codex-code-mode-host"; do
  codesign --verify --deep --strict "$executable_path"
  actual_team_identifier="$(codesign --display --verbose=4 "$executable_path" 2>&1 | awk -F= '/^TeamIdentifier=/{ print $2 }')"
  if [[ $actual_team_identifier != "$expected_team_identifier" ]]; then
    printf 'Codex update: %s の signer TeamIdentifier が OpenAI と一致しません: %s\n' \
      "$(basename "$executable_path")" "${actual_team_identifier:-不明}" >&2
    exit 1
  fi
done

next_release_lock="$temporary_directory/codex-release.json"
jq -n \
  --arg version "$version" \
  --arg url "$artifact_url" \
  --arg hash "$expected_hash" \
  '{ version: $version, artifacts: { "aarch64-darwin": { url: $url, hash: $hash } } }' \
  >"$next_release_lock"

cp "$release_lock" "$release_lock_backup"
restore_release_lock=true
cp "$next_release_lock" "$release_lock"

printf 'Codex %s の Nix package をビルドします。\n' "$version"
nix build "path:$flake_directory#codex" --no-link

restore_release_lock=false
git -C "$repository_root" diff --stat -- "$release_lock"
printf 'release lock を %s へ更新しました。switch と commit は実行していません。\n' "$version"
