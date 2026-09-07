#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=ai-cli-installation.sh
source "$script_directory/ai-cli-installation.sh"

if [[ $# != 1 ]]; then
  printf 'Usage: ai-cli.sh install|update|check\n' >&2
  exit 2
fi

bin_directory="$HOME/.local/bin"
claude_launcher="$bin_directory/claude"
claude_packages="$HOME/.local/share/claude"
codex_launcher="$bin_directory/codex"
codex_packages="${CODEX_HOME:-$HOME/.codex}/packages/standalone"

case "$1" in
install)
  # Codex のインストーラーは Nix 版も npm 版と判定し、profile へ PATH を追記する。
  for cli in claude codex; do
    if [[ ! -e "$bin_directory/$cli" && ! -L "$bin_directory/$cli" ]] &&
      existing_command="$(command -v "$cli")"; then
      printf 'NG: %s が別の導入先にあります: %s。既存の管理元から外し、構成を反映してください。\n' \
        "$cli" "$existing_command" >&2
      exit 1
    fi
  done
  # PATH は Home Manager が管理する。公式インストーラーによる profile への追記を避ける。
  export PATH="$bin_directory:$PATH"
  install_ai_cli_if_missing "$claude_launcher" "$claude_packages" \
    https://claude.ai/install.sh bash latest
  CODEX_INSTALL_DIR="$bin_directory" CODEX_NON_INTERACTIVE=1 \
    install_ai_cli_if_missing "$codex_launcher" "$codex_packages" \
    https://chatgpt.com/codex/install.sh sh --release latest
  ;;
update)
  # 片方が未導入なら、もう片方を更新する前に利用者へ知らせる。
  verify_ai_cli_installation "$claude_launcher" "$claude_packages"
  verify_ai_cli_installation "$codex_launcher" "$codex_packages"
  export PATH="$bin_directory:$PATH"
  "$claude_launcher" update
  "$codex_launcher" update
  ;;
check)
  failures=0
  for cli in claude codex; do
    if [[ $cli == claude ]]; then
      packages="$claude_packages"
    else
      packages="$codex_packages"
    fi
    if ! verify_ai_cli_installation "$bin_directory/$cli" "$packages"; then
      failures=$((failures + 1))
      continue
    fi
    resolved_command="$(command -v "$cli" || true)"
    if [[ $resolved_command != "$bin_directory/$cli" ]]; then
      printf 'NG: PATH が公式ランチャーを選んでいません: %s → %s\n' "$cli" "${resolved_command:-未検出}" >&2
      failures=$((failures + 1))
    else
      printf 'OK: %s → %s\n' "$cli" "$(realpath "$resolved_command")"
    fi
  done
  [[ $failures == 0 ]]
  ;;
*)
  printf 'Usage: ai-cli.sh install|update|check\n' >&2
  exit 2
  ;;
esac
