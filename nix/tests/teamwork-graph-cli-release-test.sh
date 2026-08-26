#!/usr/bin/env bash

set -euo pipefail

test_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
release_tool="$test_directory/../scripts/teamwork-graph-cli-release.sh"
fixture_directory="$test_directory/fixtures/teamwork-graph-cli"
temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/teamwork-graph-cli-release-test.XXXXXX")"

cleanup() {
  rm -rf "$temporary_directory"
}
trap cleanup EXIT

pass() {
  printf 'OK: %s\n' "$1"
}

fail() {
  printf 'NG: %s\n' "$1" >&2
  exit 1
}

assert_command_fails() {
  local test_name="$1"
  shift

  if "$@" >"$temporary_directory/stdout" 2>"$temporary_directory/stderr"; then
    fail "$test_name"
  fi

  pass "$test_name"
}

test_stable_darwin_arm64_manifest_is_parsed() {
  local actual
  local expected

  # Why: 更新処理が上流 JSON の未検証値をダウンロード処理へ渡さないことを保証する。
  # What: stable の macOS arm64 リリースだけが具体的な候補へ変換される。
  # Given: 公式配布形式と同じ stable manifest。
  # When: manifest をリリース候補へ parse する。
  actual="$("$release_tool" parse-manifest "$fixture_directory/manifest-stable.json")"
  expected='{"version":"1.2.5","fileName":"twg-darwin-arm64-v1.2.5","url":"https://teamwork-graph.atlassian.com/cli/twg-darwin-arm64-v1.2.5","checksumsUrl":"https://teamwork-graph.atlassian.com/cli/SHA256SUMS-v1.2.5"}'

  # Then: 後続処理に必要な検証済みの値だけが残る。
  if [[ "$(jq -S -c . <<<"$actual")" != "$(jq -S -c . <<<"$expected")" ]]; then
    fail "stable の macOS arm64 manifest を parse できます"
  fi

  pass "stable の macOS arm64 manifest を parse できます"
}

test_published_checksum_is_parsed() {
  local candidate_file="$temporary_directory/candidate.json"
  local actual

  # Why: checksum 一覧の別 artifact を誤って採用すると Nix の固定値が信頼できなくなる。
  # What: 候補のファイル名に完全一致する SHA-256 だけを選ぶ。
  # Given: parse 済み候補と複数 artifact の checksum 一覧。
  "$release_tool" parse-manifest "$fixture_directory/manifest-stable.json" >"$candidate_file"

  # When: checksum 一覧をリリース情報へ parse する。
  actual="$("$release_tool" parse-checksums "$candidate_file" "$fixture_directory/SHA256SUMS-v1.2.5")"

  # Then: 公式の darwin-arm64 SHA-256 が追加される。
  if [[ "$(jq -r '.sha256' <<<"$actual")" != "bc17b9c058da19ae5725ae5d8aa9b26dd539b6982bdf864dff5424d112a9b6f6" ]]; then
    fail "対象 artifact の checksum を parse できます"
  fi

  pass "対象 artifact の checksum を parse できます"
}

test_invalid_manifest_values_are_rejected() {
  local invalid_manifest="$temporary_directory/invalid-manifest.json"

  # Why: 配布 channel や origin の暗黙補正は意図しないバイナリ取得につながる。
  # What: 許可していない channel、version、origin、platform をすべて fail fast で拒否する。
  # Given/When/Then: 各制約だけを壊した manifest を parse すると失敗する。
  jq '.channel = "beta"' "$fixture_directory/manifest-stable.json" >"$invalid_manifest"
  assert_command_fails "stable 以外の channel を拒否します" "$release_tool" parse-manifest "$invalid_manifest"

  jq '.version = "1.2"' "$fixture_directory/manifest-stable.json" >"$invalid_manifest"
  assert_command_fails "厳密な SemVer でない version を拒否します" "$release_tool" parse-manifest "$invalid_manifest"

  jq '.checksumsUrl = "https://example.com/SHA256SUMS-v1.2.5"' "$fixture_directory/manifest-stable.json" >"$invalid_manifest"
  assert_command_fails "公式 origin 以外の checksum URL を拒否します" "$release_tool" parse-manifest "$invalid_manifest"

  jq '.assets["darwin-arm64"].url = "https://example.com/twg-darwin-arm64-v1.2.5"' "$fixture_directory/manifest-stable.json" >"$invalid_manifest"
  assert_command_fails "公式 origin 以外の artifact URL を拒否します" "$release_tool" parse-manifest "$invalid_manifest"

  jq 'del(.assets["darwin-arm64"])' "$fixture_directory/manifest-stable.json" >"$invalid_manifest"
  assert_command_fails "darwin-arm64 がない manifest を拒否します" "$release_tool" parse-manifest "$invalid_manifest"
}

test_checksum_mismatch_is_rejected() {
  # Why: 公開 checksum と取得物の不一致を Nix hash の更新より前に止める必要がある。
  # What: 同じ形式でも値が異なる SHA-256 を拒否する。
  # Given: 公開値と異なる取得物の SHA-256。
  # When/Then: checksum を照合すると失敗する。
  assert_command_fails \
    "取得物の checksum 不一致を拒否します" \
    "$release_tool" verify-checksum \
    "bc17b9c058da19ae5725ae5d8aa9b26dd539b6982bdf864dff5424d112a9b6f6" \
    "ac17b9c058da19ae5725ae5d8aa9b26dd539b6982bdf864dff5424d112a9b6f6"
}

test_stable_darwin_arm64_manifest_is_parsed
test_published_checksum_is_parsed
test_invalid_manifest_values_are_rejected
test_checksum_mismatch_is_rejected
