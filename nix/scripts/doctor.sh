#!/usr/bin/env bash

set -euo pipefail

flake_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(git -C "$flake_directory" rev-parse --show-toplevel)"
expected_repository="$HOME/ghq/github.com/semba-yui/dotfiles"
hostname="$(scutil --get LocalHostName)"
failures=0
manual_checks=0

pass() {
  printf 'OK: %s\n' "$1"
}

fail() {
  printf 'NG: %s\n' "$1" >&2
  failures=$((failures + 1))
}

skip() {
  printf 'SKIP: %s\n' "$1"
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "$1 を実行できます"
  else
    fail "$1 が PATH にありません"
  fi
}

check_installed() {
  if [[ -d $2 ]]; then
    pass "$1がインストールされています"
  else
    fail "$1がインストールされていません"
  fi
}

manual() {
  printf 'MANUAL: %s\n' "$1"
  manual_checks=$((manual_checks + 1))
}

printf 'dotfiles のセットアップ状態を診断します。\n\n'

# ホストの置き方は hosts/default.nix が決めるので、ファイルの有無ではなく Flake に登録されたホスト名で確かめる。
registered_hosts="$(nix eval --raw "$flake_directory#darwinConfigurations" --apply 'hosts: builtins.concatStringsSep "\n" (builtins.attrNames hosts)')"
if ! grep -Fqx "$hostname" <<<"$registered_hosts"; then
  fail "$hostname のホスト設定がありません"
  exit 1
fi
pass "$hostname のホスト設定があります"

# ホストごとに導入するものが異なるため、検査対象をホストの宣言から決める。
# shellcheck disable=SC2016 # ${...} は Nix の文字列補間であり、シェルに展開させない。
declared="$(nix eval --raw "$flake_directory#darwinConfigurations.\"$hostname\".config" --apply '
  config:
  let home = config.home-manager.users.${config.system.primaryUser};
  in builtins.concatStringsSep "\n" (
    map (package: "package:" + (package.pname or package.name)) home.home.packages
    ++ map (cask: "cask:" + cask.name) (if config.homebrew.enable then config.homebrew.casks else [ ])
  )')"

declares() {
  grep -Fqx "$1" <<<"$declared"
}

check_command darwin-rebuild
check_command nix

for command_name in betterleaks fish gh git git-credential-manager just lefthook nh oxfmt twg; do
  if declares "package:$command_name"; then
    check_command "$command_name"
  else
    skip "$command_name はこのホストの管理対象ではありません"
  fi
done

if bash "$flake_directory/scripts/ai-cli.sh" check; then
  pass "Claude Code と Codex は公式インストーラーで管理されています"
else
  fail "AI CLI の導入先または PATH を確認してください"
fi

if declares package:twg; then
  if [[ ! -e "$HOME/.local/bin/twg" && ! -L "$HOME/.local/bin/twg" ]]; then
    pass "Nix 管理外の twg が ~/.local/bin にありません"
  else
    fail "Nix 管理外の twg が ~/.local/bin にあります"
  fi

  twg_upkeep_launch_agent="$HOME/Library/LaunchAgents/com.atlassian.twg.upkeep.plist"
  if [[ ! -e $twg_upkeep_launch_agent && ! -L $twg_upkeep_launch_agent ]]; then
    pass "TWG upkeep の LaunchAgent は無効です"
  else
    fail "TWG upkeep の LaunchAgent が有効です: $twg_upkeep_launch_agent"
  fi
fi

if [[ $repository_root == "$expected_repository" ]]; then
  pass "dotfiles は想定した場所にあります"
else
  fail "dotfiles の場所が想定と異なります: $repository_root"
fi

if declares package:fish; then
  login_shell="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{ print $2 }')"
  if [[ $login_shell == */fish ]]; then
    pass "fish がログインシェルです"
  else
    fail "ログインシェルが fish ではありません: ${login_shell:-不明}"
  fi
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

if declares package:lefthook; then
  # lefthookはリポジトリ内で実行して初めて導入状態を判定できるため、subshellで移動する。
  if (cd "$repository_root" && lefthook check-install >/dev/null 2>&1); then
    pass "秘密検出のgit hooksが導入されています"
  else
    fail "秘密検出のgit hooksが未導入です: dotfiles hooks-install を実行してください"
  fi
fi

# アプリの導入は自動で確認し、macOSが保護する権限や認証は手動確認として残す。
if declares cask:google-japanese-ime; then
  check_installed Google日本語入力 "/Library/Input Methods/GoogleJapaneseInput.app"
  manual "Google日本語入力を入力ソースへ追加する"
fi
if declares cask:cleanshot; then
  check_installed "CleanShot X" "/Applications/CleanShot X.app"
  manual "CleanShot Xへライセンスを登録する"
  manual "CleanShot Xへ画面収録など必要な権限を許可する"
fi
if declares cask:karabiner-elements; then
  check_installed Karabiner-Elements "/Applications/Karabiner-Elements.app"
  manual "Karabiner-Elementsへ入力監視などの権限を許可する"
fi
if declares cask:raycast; then
  check_installed Raycast "/Applications/Raycast.app"
  manual "Raycastを起動し、Spotlightの代わりに使うショートカットを設定する"
fi
if declares package:git-credential-manager; then
  manual "利用するGitHubアカウントをGit Credential Managerで認証する"
fi

printf '\n診断結果: NG %d件、手動確認 %d件\n' "$failures" "$manual_checks"

if ((failures > 0)); then
  exit 1
fi
