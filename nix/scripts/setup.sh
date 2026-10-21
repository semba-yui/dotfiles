#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: setup.sh plan|apply

  plan   システムを変更せず、現在のホストの構成をビルドする
  apply  Nix が未導入なら公式インストーラーで導入し、nix-darwin を適用する

失敗しても、同じコマンドを再実行すれば続きから進む。
EOF
}

flake_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
hostname="$(scutil --get LocalHostName)"
work_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-setup.XXXXXX")"
trap 'rm -rf "$work_directory"' EXIT
build_result="$work_directory/result"
nix_daemon_profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
# Nix 公式インストーラーが追記し、nix-darwin が未知の内容として適用を中止するファイル。
nix_installer_etc_files=(/etc/bashrc /etc/zshrc)

# 初回適用前は nix.conf で Flakes が無効なため、子プロセスを含めて有効化する。
export NIX_CONFIG='experimental-features = nix-command flakes'

fail() {
  printf 'NG: %s\n' "$1" >&2
  exit 1
}

plan() {
  # Nix の導入直後は、同じシェルの PATH にまだ nix がない。
  if ! command -v nix >/dev/null 2>&1 && [[ -f $nix_daemon_profile ]]; then
    # shellcheck disable=SC1090
    source "$nix_daemon_profile"
  fi
  command -v nix >/dev/null 2>&1 || fail "Nix が未導入です。setup.sh apply で導入してください"

  # Flake は未追跡ファイルを読まないため、追加したホスト定義が評価から黙って消える。commit は不要。
  local untracked_files
  untracked_files="$(git -C "$flake_directory" ls-files --others --exclude-standard -- .)"
  [[ -z $untracked_files ]] || fail "未追跡ファイルは Flake から見えません。git add してください:"$'\n'"$untracked_files"

  # ホストの置き方は hosts/default.nix が決めるので、ファイルの有無ではなく Flake に登録されたホスト名で確かめる。
  local registered_hosts
  registered_hosts="$(nix eval --raw "$flake_directory#darwinConfigurations" --apply 'hosts: builtins.concatStringsSep "\n" (builtins.attrNames hosts)')"
  grep -Fqx "$hostname" <<<"$registered_hosts" ||
    fail "$hostname のホスト設定がありません: nix/hosts/$hostname/ を追加してください"

  echo "$hostname の構成をビルドします（反映しません）。"
  nix build "$flake_directory#darwinConfigurations.\"$hostname\".system" --out-link "$build_result"
}

apply() {
  if ! command -v nix >/dev/null 2>&1 && [[ ! -f $nix_daemon_profile ]]; then
    curl -fsSL --proto '=https' --tlsv1.2 https://nixos.org/nix/install -o "$work_directory/install-nix"
    sh "$work_directory/install-nix" --daemon
  fi

  plan

  local etc_file answer
  for etc_file in "${nix_installer_etc_files[@]}"; do
    [[ -f $etc_file && ! -L $etc_file ]] || continue
    printf '\n----- %s -----\n' "$etc_file"
    cat "$etc_file"
    read -r -p "$etc_file は nix-darwin が置き換えます。$etc_file.before-nix-darwin へ退避しますか？ [y/N] " answer
    [[ $answer == [yY] ]] || fail "退避しなかったため中止しました"
    # 以前の退避先を上書きするとその内容を失うため、mv -n で守る。
    sudo mv -n "$etc_file" "$etc_file.before-nix-darwin"
    [[ ! -e $etc_file ]] || fail "$etc_file.before-nix-darwin が既にあります。中身を確認してください"
  done

  sudo "$build_result/sw/bin/darwin-rebuild" switch --flake "$flake_directory#$hostname"
  echo "完了しました。新しいターミナルで dotfiles ai-cli-install と dotfiles doctor を実行してください。"
}

case "${1:-}" in
plan)
  plan
  echo "plan が完了しました。システムは変更していません。"
  ;;
apply) apply ;;
*)
  usage >&2
  exit 2
  ;;
esac
