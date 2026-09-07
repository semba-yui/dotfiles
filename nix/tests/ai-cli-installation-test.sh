#!/usr/bin/env bash

set -euo pipefail

test_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../scripts/ai-cli-installation.sh
source "$test_directory/../scripts/ai-cli-installation.sh"
fixture_directory="$test_directory/fixtures/ai-cli"
temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/ai-cli-installation-test.XXXXXX")"
trap 'rm -rf "$temporary_directory"' EXIT

assert_fails() {
  local name="$1"
  shift
  if "$@" >"$temporary_directory/stdout" 2>"$temporary_directory/stderr"; then
    printf 'NG: %s（成功してしまいました）\n' "$name" >&2
    exit 1
  fi
  printf 'OK: %s\n' "$name"
}

# Why: 再実行が既存版を勝手に更新しないことを保証する。
# What: 未導入時だけ取得・導入し、導入済みなら取得せず起動確認する。
# Given: 空の導入先と、ローカルだけで動くインストーラー。
launcher="$temporary_directory/installed/bin/claude"
packages="$temporary_directory/installed/packages"
# When: 初回導入後、取得できない URL で再実行する。
install_ai_cli_if_missing "$launcher" "$packages" "file://$fixture_directory/install.sh" bash \
  "$launcher" "$packages" "$fixture_directory/cli.sh"
install_ai_cli_if_missing "$launcher" "$packages" "file://$temporary_directory/not-found" bash
# Then: 同じ導入版が起動できる。
[[ "$("$launcher" --version)" == "fixture-cli 1.0.0" ]]
printf 'OK: 初回導入と再実行で既存版を維持します\n'

# Why: 中途半端な取得物を実行すると失敗が見えなくなる。
# What: ダウンロード失敗を呼び出し元へ返し、導入しない。
# Given/When: 存在しない URL から新規導入する。
assert_fails "取得失敗で停止します" install_ai_cli_if_missing \
  "$temporary_directory/download-failed/bin/claude" "$temporary_directory/download-failed/packages" \
  "file://$temporary_directory/not-found" bash
# Then: ランチャーは作られない。
[[ ! -e "$temporary_directory/download-failed/bin/claude" ]]

# Why: インストーラーの成功表示だけでは実際の導入を保証できない。
# What: 導入物がなければ失敗として扱う。
# Given/When/Then: 正常終了しても導入しないスクリプトを拒否する。
assert_fails "導入物がない成功応答を拒否します" install_ai_cli_if_missing \
  "$temporary_directory/empty/bin/claude" "$temporary_directory/empty/packages" \
  "file://$fixture_directory/cli.sh" bash --version

# Why: Nix 版や別のランチャーを公式管理のものとして更新しない。
# What: 管理ディレクトリの外へ向くリンクと壊れたリンクを拒否する。
# Given: 管理対象外を指すリンク。
mkdir -p "$temporary_directory/conflict/bin" "$temporary_directory/conflict/packages"
ln -s "$launcher" "$temporary_directory/conflict/bin/claude"
# When/Then: 取得に進まず既存リンクを保護する。
assert_fails "管理対象外のランチャーを拒否します" install_ai_cli_if_missing \
  "$temporary_directory/conflict/bin/claude" "$temporary_directory/conflict/packages" \
  "file://$fixture_directory/install.sh" bash
[[ "$(readlink "$temporary_directory/conflict/bin/claude")" == "$launcher" ]]
ln -s "$temporary_directory/missing" "$temporary_directory/conflict/bin/codex"
assert_fails "壊れたリンクを拒否します" verify_ai_cli_installation \
  "$temporary_directory/conflict/bin/codex" "$temporary_directory/conflict/packages"
