#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
flake_directory="$(cd -- "$script_directory/.." && pwd)"
repository_root="$(git -C "$flake_directory" rev-parse --show-toplevel)"
release_tool="$script_directory/teamwork-graph-cli-release.sh"
release_lock="$flake_directory/packages/teamwork-graph-cli-release.json"
manifest_url="https://teamwork-graph.atlassian.com/cli/manifest.json"
expected_team_identifier="UPXU4CQZ5P"
temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/teamwork-graph-cli-update.XXXXXX")"
release_lock_backup="$temporary_directory/teamwork-graph-cli-release.backup.json"
restore_release_lock=false

cleanup() {
  local exit_code=$?
  trap - EXIT

  if [[ $restore_release_lock == "true" ]]; then
    cp "$release_lock_backup" "$release_lock"
    printf 'Teamwork Graph CLI update: 検証に失敗したため release lock を元に戻しました。\n' >&2
  fi

  rm -rf "$temporary_directory"
  exit "$exit_code"
}
trap cleanup EXIT

if ! git -C "$repository_root" diff --quiet -- "$release_lock" ||
  ! git -C "$repository_root" diff --cached --quiet -- "$release_lock"; then
  printf 'Teamwork Graph CLI update: release lock に未確認の変更があります。先に確認してください。\n' >&2
  exit 1
fi

manifest_file="$temporary_directory/manifest.json"
release_candidate_file="$temporary_directory/release-candidate.json"
checksums_file="$temporary_directory/SHA256SUMS"
parsed_release_file="$temporary_directory/parsed-release.json"
artifact_file="$temporary_directory/twg"
next_release_lock="$temporary_directory/teamwork-graph-cli-release.json"

printf '公式 stable manifest を取得します。\n'
curl --fail --location --silent --show-error "$manifest_url" --output "$manifest_file"
"$release_tool" parse-manifest "$manifest_file" >"$release_candidate_file"

checksums_url="$(jq -r '.checksumsUrl' "$release_candidate_file")"
printf '公開 checksum を取得します。\n'
curl --fail --location --silent --show-error "$checksums_url" --output "$checksums_file"
"$release_tool" parse-checksums "$release_candidate_file" "$checksums_file" >"$parsed_release_file"

artifact_url="$(jq -r '.url' "$parsed_release_file")"
printf '署名済み macOS arm64 artifact を取得します。\n'
curl --fail --location --silent --show-error "$artifact_url" --output "$artifact_file"
chmod +x "$artifact_file"

expected_sha256="$(jq -r '.sha256' "$parsed_release_file")"
actual_sha256="$(shasum -a 256 "$artifact_file" | awk '{ print $1 }')"
"$release_tool" verify-checksum "$expected_sha256" "$actual_sha256"

codesign --verify --deep --strict "$artifact_file"
actual_team_identifier="$(codesign --display --verbose=4 "$artifact_file" 2>&1 | awk -F= '/^TeamIdentifier=/{ print $2 }')"
if [[ $actual_team_identifier != "$expected_team_identifier" ]]; then
  printf 'Teamwork Graph CLI update: signer TeamIdentifier が Atlassian と一致しません: %s\n' \
    "${actual_team_identifier:-不明}" >&2
  exit 1
fi

version="$(jq -r '.version' "$parsed_release_file")"
nix_hash="$(nix hash convert --hash-algo sha256 --to sri "$actual_sha256")"
jq -n \
  --arg version "$version" \
  --arg url "$artifact_url" \
  --arg hash "$nix_hash" \
  '{
    version: $version,
    artifacts: {
      "aarch64-darwin": {
        url: $url,
        hash: $hash
      }
    }
  }' >"$next_release_lock"

if cmp -s "$release_lock" "$next_release_lock"; then
  printf 'Teamwork Graph CLI %s はすでに最新です。\n' "$version"
  exit 0
fi

cp "$release_lock" "$release_lock_backup"
restore_release_lock=true
cp "$next_release_lock" "$release_lock"

printf 'Teamwork Graph CLI %s の Nix package をビルドします。\n' "$version"
nix build "path:$flake_directory#teamwork-graph-cli" --no-link

restore_release_lock=false
git -C "$repository_root" diff -- "$release_lock"
printf 'release lock を更新しました。switch と commit は実行していません。\n'
