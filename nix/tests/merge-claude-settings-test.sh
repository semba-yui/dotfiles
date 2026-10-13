#!/usr/bin/env bash

set -euo pipefail

test_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
merge_filter="$test_directory/../scripts/merge-claude-settings.jq"
temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/merge-claude-settings-test.XXXXXX")"

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

merge_settings() {
  printf '%s' "$1" >"$temporary_directory/current.json"
  printf '%s' "$2" >"$temporary_directory/declared.json"
  jq -s -f "$merge_filter" "$temporary_directory/current.json" "$temporary_directory/declared.json"
}

assert_json_equal() {
  local test_name="$1"
  local actual="$2"
  local expected="$3"

  if [[ "$(jq -S -c . <<<"$actual")" != "$(jq -S -c . <<<"$expected")" ]]; then
    printf 'actual:   %s\nexpected: %s\n' "$(jq -S -c . <<<"$actual")" "$(jq -S -c . <<<"$expected")" >&2
    fail "$test_name"
  fi

  pass "$test_name"
}

other_tool_hook='{"hooks":[{"type":"command","command":"/bin/sh /opt/other-tool/claude-hook.sh","timeout":10}]}'
declared_stop_hook='{"hooks":[{"type":"command","command":"afplay /System/Library/Sounds/Funk.aiff","async":true}]}'

test_hook_added_by_other_tool_to_declared_event_is_kept() {
  local actual

  # Why: 他のツールが登録した hook を消すと、そのツールがエージェントの状態を受け取れなくなる。
  # What: 宣言したイベントでも、既存の hook を残したうえで宣言した hook を足す。
  # Given: 他のツールが Stop に hook を登録した設定と、Stop に通知音を宣言した設定。
  # When: 設定をマージする。
  actual="$(merge_settings \
    "{\"hooks\":{\"Stop\":[$other_tool_hook]}}" \
    "{\"hooks\":{\"Stop\":[$declared_stop_hook]}}")"

  # Then: 既存の hook の後ろに宣言した hook が並ぶ。
  assert_json_equal \
    "宣言したイベントでも他のツールの hook が残ります" \
    "$actual" \
    "{\"hooks\":{\"Stop\":[$other_tool_hook,$declared_stop_hook]}}"
}

test_reapplying_declaration_does_not_duplicate_hooks() {
  local merged_once
  local merged_twice

  # Why: dotfiles update のたびに同じ hook が増えると、通知音が重なって鳴る。
  # What: 宣言した hook がすでにある設定へ、同じ宣言をマージしても変わらない。
  # Given: 一度マージした設定。
  merged_once="$(merge_settings \
    "{\"hooks\":{\"Stop\":[$other_tool_hook]}}" \
    "{\"hooks\":{\"Stop\":[$declared_stop_hook]}}")"

  # When: 同じ宣言をもう一度マージする。
  merged_twice="$(merge_settings "$merged_once" "{\"hooks\":{\"Stop\":[$declared_stop_hook]}}")"

  # Then: 一度目の結果と同じになる。
  assert_json_equal "同じ宣言を二度マージしても hook が重複しません" "$merged_twice" "$merged_once"
}

test_permission_rules_follow_declaration() {
  local actual

  # Why: 権限は Nix の宣言だけを正とし、宣言から外した規則が端末に残らないようにする。
  # What: permissions の配列は宣言した内容で置き換わる。
  # Given: 宣言から外した規則を含む設定。
  # When: 設定をマージする。
  actual="$(merge_settings \
    '{"permissions":{"ask":["Bash(curl:*)","Bash(rm:*)"]}}' \
    '{"permissions":{"ask":["Bash(rm:*)"]}}')"

  # Then: 宣言した規則だけが残る。
  assert_json_equal \
    "permissions の配列は宣言で置き換わります" \
    "$actual" \
    '{"permissions":{"ask":["Bash(rm:*)"]}}'
}

test_settings_not_declared_are_kept() {
  local actual

  # Why: settings.json は Claude Code 自身やプラグインも書き換えるため、宣言外の項目を消すと設定が失われる。
  # What: 宣言していないキーと hook のイベントはそのまま残る。
  # Given: 宣言外のキーと、宣言していないイベントの hook を持つ設定。
  # When: 別のキーとイベントだけを宣言してマージする。
  actual="$(merge_settings \
    "{\"enabledPlugins\":{\"example@marketplace\":true},\"hooks\":{\"SessionStart\":[$other_tool_hook]}}" \
    "{\"theme\":\"dark\",\"hooks\":{\"Stop\":[$declared_stop_hook]}}")"

  # Then: 宣言外のキーとイベントは変わらず、宣言した項目が加わる。
  assert_json_equal \
    "宣言していないキーと hook のイベントは残ります" \
    "$actual" \
    "{\"enabledPlugins\":{\"example@marketplace\":true},\"theme\":\"dark\",\"hooks\":{\"SessionStart\":[$other_tool_hook],\"Stop\":[$declared_stop_hook]}}"
}

test_hook_added_by_other_tool_to_declared_event_is_kept
test_reapplying_declaration_does_not_duplicate_hooks
test_permission_rules_follow_declaration
test_settings_not_declared_are_kept
