{
  config,
  lib,
  pkgs,
  ...
}:

let
  repositoryDirectory = builtins.dirOf config.programs.nh.darwinFlake;

  declaredSettings = (pkgs.formats.json { }).generate "claude-settings.json" {
    statusLine = {
      type = "command";
      command = "bash ~/.claude/scripts/statusline.sh";
    };
  };
in
{
  home.file.".claude/scripts/statusline.sh" = {
    source = config.lib.file.mkOutOfStoreSymlink "${repositoryDirectory}/claude/.claude/scripts/statusline.sh";
    force = true;
  };

  # 本体とランチャーは公式の自動更新に任せ、共有する指示だけを配置する。
  home.file.".claude/CLAUDE.md".source = ../../../../claude/.claude/CLAUDE.md;

  # settings.json はプラグインや画面上の変更で Claude Code 自身も書き換えるため、ファイルごと置き換えず、
  # 宣言した項目だけを既存の設定へ重ねる。
  home.activation.mergeClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_file="$HOME/.claude/settings.json"
    run mkdir -p "$HOME/.claude"
    if [[ -f $settings_file ]]; then
      merged_file="$(mktemp "$HOME/.claude/.settings.json.XXXXXX")"
      ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$settings_file" ${declaredSettings} >"$merged_file"
      run mv "$merged_file" "$settings_file"
    else
      run install -m 0644 ${declaredSettings} "$settings_file"
    fi
  '';
}
