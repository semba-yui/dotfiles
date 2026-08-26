#!/usr/bin/env bash

set -euo pipefail

test_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
home_module="$test_directory/../modules/home/programs/teamwork-graph-cli.nix"

pass() {
  printf 'OK: %s\n' "$1"
}

fail() {
  printf 'NG: %s\n' "$1" >&2
  exit 1
}

test_secret_store_is_not_overridden() {
  # Why: backend を固定すると TWG の認証情報保存と fallback の責務を launcher が奪ってしまう。
  # What: launcher が TWG 公式デフォルトの secret store 選択を上書きしない。
  # Given: Home Manager が生成する TWG launcher の宣言。
  # When: secret store の環境変数上書きを検索する。
  if rg --quiet 'TWG_SECRET_STORE' "$home_module"; then
    fail "TWG の secret store を launcher で上書きしません"
  fi

  # Then: TWG 自身が auth.conf を含む公式の保存方式を選択できる。
  pass "TWG の secret store を launcher で上書きしません"
}

test_optional_telemetry_remains_disabled() {
  # Why: secret store の責務を戻しても、任意テレメトリを止める既存の境界は維持する。
  # What: launcher が TWG プロセスだけに DO_NOT_TRACK=1 を設定する。
  # Given: Home Manager が生成する TWG launcher の宣言。
  # When: telemetry opt-out の環境変数を検索する。
  if ! rg --quiet 'export DO_NOT_TRACK=1' "$home_module"; then
    fail "TWG launcher の任意テレメトリを無効化します"
  fi

  # Then: secret store の変更と独立して telemetry opt-out が残る。
  pass "TWG launcher の任意テレメトリを無効化します"
}

test_secret_store_is_not_overridden
test_optional_telemetry_remains_disabled
