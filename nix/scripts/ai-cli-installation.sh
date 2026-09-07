#!/usr/bin/env bash

verify_ai_cli_installation() {
  local launcher="$1"
  local package_directory="$2"
  local executable_path package_path

  if [[ ! -x $launcher ]]; then
    printf 'NG: %s を実行できません。dotfiles ai-cli-install で導入してください。\n' "$launcher" >&2
    return 1
  fi
  executable_path="$(realpath "$launcher")" || return
  package_path="$(realpath "$package_directory")" || return
  case "$executable_path" in
  "$package_path"/*) ;;
  *)
    printf 'NG: %s は公式の管理ディレクトリ外を指しています: %s\n' "$launcher" "$executable_path" >&2
    return 1
    ;;
  esac
  "$launcher" --version
}

install_ai_cli_if_missing() (
  local launcher="$1"
  local package_directory="$2"
  local installer_url="$3"
  local interpreter="$4"
  shift 4

  # 壊れたリンクも既存の所有物として扱い、インストーラーに上書きさせない。
  if [[ -e $launcher || -L $launcher ]]; then
    verify_ai_cli_installation "$launcher" "$package_directory"
    return
  fi

  local installer_directory
  installer_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-ai-cli-installer.XXXXXX")" || return
  trap 'rm -rf "$installer_directory"' EXIT

  # パイプ経由では取得途中のスクリプトも実行されるため、取得完了後に起動する。
  curl -fsSL "$installer_url" -o "$installer_directory/install.sh" || return
  "$interpreter" "$installer_directory/install.sh" "$@" || return
  verify_ai_cli_installation "$launcher" "$package_directory"
)
