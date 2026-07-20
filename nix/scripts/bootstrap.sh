#!/usr/bin/env bash

set -euo pipefail

repository_url="https://semba-yui@github.com/semba-yui/dotfiles.git"
default_repository="$HOME/ghq/github.com/semba-yui/dotfiles"
check_only=false

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--check]

Options:
  --check  システムへ反映せず、現在のホスト設定を検証してビルドする
  --help   このヘルプを表示する
EOF
}

while (($# > 0)); do
  case "$1" in
  --check)
    check_only=true
    ;;
  --help)
    usage
    exit 0
    ;;
  *)
    echo "bootstrap: 不明な引数です: $1" >&2
    usage >&2
    exit 2
    ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "bootstrap: macOSで実行してください。" >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "bootstrap: Xcode Command Line Toolsが必要です。" >&2
  echo "xcode-select --install を実行し、完了後にbootstrapを再実行してください。" >&2
  exit 1
fi

for command_name in curl git scutil sudo; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "bootstrap: 必要なコマンドがありません: $command_name" >&2
    exit 1
  fi
done

script_path="${BASH_SOURCE[0]:-}"
repository_directory="$default_repository"
if [[ -n $script_path && -f $script_path ]]; then
  script_repository="$(git -C "$(dirname -- "$script_path")" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n $script_repository && -f "$script_repository/nix/flake.nix" ]]; then
    repository_directory="$script_repository"
  fi
fi

if [[ ! -d "$repository_directory/.git" ]]; then
  if [[ $check_only == "true" ]]; then
    echo "bootstrap: --checkはdotfilesのcheckout内で実行してください。" >&2
    exit 1
  fi

  if [[ -e $repository_directory ]]; then
    echo "bootstrap: clone先がすでに存在します: $repository_directory" >&2
    exit 1
  fi

  mkdir -p "$(dirname -- "$repository_directory")"
  git clone "$repository_url" "$repository_directory"
fi

if [[ $check_only != "true" ]]; then
  if [[ -n "$(git -C "$repository_directory" status --porcelain)" ]]; then
    echo "bootstrap: dotfilesに未コミットの変更があります。" >&2
    exit 1
  fi

  git -C "$repository_directory" pull --ff-only
fi

if ! command -v nix >/dev/null 2>&1; then
  if [[ $check_only == "true" ]]; then
    echo "bootstrap: Nixがインストールされていません。" >&2
    exit 1
  fi

  installer_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-lix-installer.XXXXXX")"
  trap 'rm -rf "$installer_directory"' EXIT
  curl -fsSL https://install.lix.systems/lix -o "$installer_directory/install-lix"
  sh "$installer_directory/install-lix" install

  # インストール直後の同じプロセスからNixを利用できるよう、daemon profileを読み込む。
  # shellcheck disable=SC1091
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

flake_directory="$repository_directory/nix"
hostname="$(scutil --get LocalHostName)"
available_hosts="$(nix eval --json "$flake_directory#darwinConfigurations" --apply builtins.attrNames)"

if ! grep -Fq "\"$hostname\"" <<<"$available_hosts"; then
  echo "bootstrap: $hostname のホスト設定がありません。" >&2
  echo "利用可能なホスト: $available_hosts" >&2
  exit 1
fi

configured_user="$(nix eval --raw "$flake_directory#darwinConfigurations.$hostname.config.system.primaryUser")"
configured_home="$(nix eval --raw "$flake_directory#darwinConfigurations.$hostname.config.users.users.$configured_user.home")"

if [[ "$(id -un)" != "$configured_user" ]]; then
  echo "bootstrap: 現在のユーザーとホスト設定が一致しません。" >&2
  echo "現在: $(id -un)、設定: $configured_user" >&2
  exit 1
fi

if [[ $HOME != "$configured_home" ]]; then
  echo "bootstrap: 現在のホームディレクトリとホスト設定が一致しません。" >&2
  echo "現在: $HOME、設定: $configured_home" >&2
  exit 1
fi

echo "Flake全体を検証します。"
nix flake check "$flake_directory"

build_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bootstrap.XXXXXX")"
trap 'rm -rf "${installer_directory:-}" "$build_directory"' EXIT

echo "$hostname の構成を、反映せずにビルドします。"
nix build "$flake_directory#darwinConfigurations.$hostname.system" \
  --out-link "$build_directory/result"

if [[ $check_only == "true" ]]; then
  echo "bootstrapの検証が完了しました。システムへは反映していません。"
  exit 0
fi

echo "$hostname へ構成を反映します。sudoの認証が必要です。"
sudo "$build_directory/result/sw/bin/darwin-rebuild" switch \
  --flake "$flake_directory#$hostname"

echo "初期セットアップが完了しました。新しいシェルで dotfiles doctor を実行してください。"
