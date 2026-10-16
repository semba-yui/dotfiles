#!/usr/bin/env bash

set -euo pipefail

test_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_build_filter="$test_directory/../scripts/list-source-builds.jq"

pass() {
  printf 'OK: %s\n' "$1"
}

fail() {
  printf 'NG: %s\n' "$1" >&2
  exit 1
}

list_source_builds() {
  jq -r -f "$source_build_filter" <<<"$1"
}

assert_equal() {
  local test_name="$1"
  local actual="$2"
  local expected="$3"

  if [[ $actual != "$expected" ]]; then
    printf 'actual:\n%s\nexpected:\n%s\n' "$actual" "$expected" >&2
    fail "$test_name"
  fi

  pass "$test_name"
}

# `nix derivation show` の出力と同じ形の derivation。属性は判定に関わるものだけに絞る。
structured_package='"zed-editor-1.23.2.drv":{"name":"zed-editor-1.23.2","env":{},"structuredAttrs":{"pname":"zed-editor","src":"/nix/store/zed-source"}}'
env_package='"jq-1.8.1.drv":{"name":"jq-1.8.1","env":{"name":"jq-1.8.1","src":"/nix/store/jq-1.8.1.tar.gz"}}'
multiple_source_package='"vim-plugin-1.0.drv":{"name":"vim-plugin-1.0","env":{"name":"vim-plugin-1.0","srcs":"/nix/store/plugin /nix/store/syntax"}}'
configuration_generation='"home-manager-files.drv":{"name":"home-manager-files","env":{"name":"home-manager-files","buildCommand":"mkdir home-files"}}'

derivations() {
  local IFS=,
  printf '{"derivations":{%s},"version":4}' "$*"
}

test_package_with_structured_attrs_source_is_listed() {
  local actual

  # Why: buildRustPackage や buildGoModule の多くは structuredAttrs を使い、src を env ではなく
  #      structuredAttrs に持つ。見落とすと Zed のような長いビルドを告げずに始めてしまう。
  # What: structuredAttrs に src を持つ derivation を、ソースからのビルドとして挙げる。
  # Given: structuredAttrs に src を持つ derivation。
  # When: ソースからビルドするものを挙げる。
  actual="$(list_source_builds "$(derivations "$structured_package")")"

  # Then: その名前が挙がる。
  assert_equal "structuredAttrs に src を持つパッケージを挙げます" "$actual" "zed-editor-1.23.2"
}

test_package_with_env_source_is_listed() {
  local actual

  # Why: structuredAttrs を使わない derivation は、src を env に持つ。
  # What: env に src を持つ derivation を、ソースからのビルドとして挙げる。
  # Given: env に src を持つ derivation。
  # When: ソースからビルドするものを挙げる。
  actual="$(list_source_builds "$(derivations "$env_package")")"

  # Then: その名前が挙がる。
  assert_equal "env に src を持つパッケージを挙げます" "$actual" "jq-1.8.1"
}

test_package_with_multiple_sources_is_listed() {
  local actual

  # Why: 複数のソースを展開するパッケージは src ではなく srcs を持つ。
  # What: srcs を持つ derivation も、ソースからのビルドとして挙げる。
  # Given: srcs を持つ derivation。
  # When: ソースからビルドするものを挙げる。
  actual="$(list_source_builds "$(derivations "$multiple_source_package")")"

  # Then: その名前が挙がる。
  assert_equal "srcs を持つパッケージを挙げます" "$actual" "vim-plugin-1.0"
}

test_configuration_generation_is_not_listed() {
  local actual

  # Why: Home Manager の設定生成は入力が変わるたびにローカルでビルドされる。これまで挙げると
  #      毎回確認が出て、本当に重いビルドの知らせが読まれなくなる。
  # What: src も srcs も持たない derivation は挙げない。
  # Given: src も srcs も持たない設定生成の derivation。
  # When: ソースからビルドするものを挙げる。
  actual="$(list_source_builds "$(derivations "$configuration_generation")")"

  # Then: 何も挙がらない。
  assert_equal "設定生成は挙げません" "$actual" ""
}

test_source_builds_are_listed_by_name_one_per_line() {
  local actual

  # Why: 確認の前に一覧をそのまま表示するため、並びが入力の順で変わると読みにくい。
  # What: 複数あるときは、ソースからのビルドだけを名前順に 1 行ずつ挙げる。
  # Given: ソースからのビルドと設定生成が混ざった derivation。
  # When: ソースからビルドするものを挙げる。
  actual="$(list_source_builds "$(derivations "$structured_package" "$configuration_generation" "$env_package")")"

  # Then: 設定生成を除いた名前が、名前順に並ぶ。
  assert_equal "ソースからのビルドを名前順に 1 行ずつ挙げます" "$actual" "$(printf 'jq-1.8.1\nzed-editor-1.23.2')"
}

test_unknown_output_format_fails() {
  # Why: Nix の出力形式が変わったときに空の一覧として通すと、事前検知が黙って効かなくなる。
  # What: derivations を持たない入力では、失敗して update を止める。
  # Given: derivations を持たない入力。
  # When: ソースからビルドするものを挙げる。
  # Then: 失敗する。
  if list_source_builds '{"version":5}' >/dev/null 2>&1; then
    fail "derivations を持たない入力では失敗します"
  fi

  pass "derivations を持たない入力では失敗します"
}

test_package_with_structured_attrs_source_is_listed
test_package_with_env_source_is_listed
test_package_with_multiple_sources_is_listed
test_configuration_generation_is_not_listed
test_source_builds_are_listed_by_name_one_per_line
test_unknown_output_format_fails
