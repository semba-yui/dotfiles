#!/usr/bin/env bash

set -euo pipefail

flake_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(git -C "$flake_directory" rev-parse --show-toplevel)"
expected_repository="$HOME/ghq/github.com/semba-yui/dotfiles"
hostname="$(scutil --get LocalHostName)"
failures=0
warnings=0

pass() {
  printf 'OK: %s\n' "$1"
}

fail() {
  printf 'NG: %s\n' "$1" >&2
  failures=$((failures + 1))
}

warn() {
  printf '確認: %s\n' "$1"
  warnings=$((warnings + 1))
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "$1 を実行できます"
  else
    fail "$1 が PATH にありません"
  fi
}

printf 'dotfiles のセットアップ状態を診断します。\n\n'

for command_name in darwin-rebuild fish gh git git-credential-manager just nh nix oxfmt; do
  check_command "$command_name"
done

if [[ $repository_root == "$expected_repository" ]]; then
  pass "dotfiles は想定した場所にあります"
else
  fail "dotfiles の場所が想定と異なります: $repository_root"
fi

if nix eval --json "$flake_directory#darwinConfigurations" --apply builtins.attrNames |
  grep -Fq "\"$hostname\""; then
  pass "$hostname のホスト設定があります"
else
  fail "$hostname のホスト設定がありません"
fi

login_shell="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{ print $2 }')"
if [[ $login_shell == */fish ]]; then
  pass "fish がログインシェルです"
else
  fail "ログインシェルが fish ではありません: ${login_shell:-不明}"
fi

remote_url="$(git -C "$repository_root" remote get-url origin 2>/dev/null || true)"
case "$remote_url" in
https://?*@github.com/*)
  pass "GitHubのremote URLにアカウント名があります"
  ;;
*)
  fail "GitHubのremote URLにアカウント名がありません: ${remote_url:-未設定}"
  ;;
esac

if [[ -d "/Library/Input Methods/GoogleJapaneseInput.app" ]]; then
  pass "Google日本語入力がインストールされています"
else
  fail "Google日本語入力がインストールされていません"
fi

if [[ -d "/Applications/CleanShot X.app" ]]; then
  pass "CleanShot Xがインストールされています"
else
  fail "CleanShot Xがインストールされていません"
fi

if [[ -e "$HOME/Applications/Home Manager Apps/Raycast.app" ]]; then
  pass "Raycastがインストールされています"
else
  fail "Raycastがインストールされていません"
fi

printf '\nmacOSが保護する内部状態は自動判定せず、次を手動で確認してください。\n'
warn "Google日本語入力を入力ソースへ追加する"
warn "Raycastを起動し、Spotlightの代わりに使うショートカットを設定する"
warn "CleanShot Xへライセンスを登録する"
warn "CleanShot Xへ画面収録など必要な権限を許可する"
warn "利用するGitHubアカウントをGit Credential Managerで認証する"

printf '\n診断結果: NG %d件、手動確認 %d件\n' "$failures" "$warnings"

if ((failures > 0)); then
  exit 1
fi
