{ ... }:
{
  # daemon が公式インストーラーの管理先から起動・更新するため、本体は Nix で配置しない。
  home.file.".codex/AGENTS.md".source = ../../../../codex/.codex/AGENTS.md;
}
