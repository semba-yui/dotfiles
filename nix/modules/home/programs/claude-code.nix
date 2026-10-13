{
  config,
  lib,
  pkgs,
  ...
}:

let
  repositoryDirectory = builtins.dirOf config.programs.nh.darwinFlake;

  playSystemSound = name: {
    type = "command";
    command = "afplay /System/Library/Sounds/${name}.aiff";
    async = true;
  };

  declaredSettings = (pkgs.formats.json { }).generate "claude-settings.json" {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";

    advisorModel = "fable";
    askUserQuestionTimeout = "never";
    autoCompactEnabled = true;
    autoUpdatesChannel = "latest";
    editorMode = "normal";
    preferredNotifChannel = "ghostty";
    switchModelsOnFlag = false;
    tui = "fullscreen";

    env = {
      CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      DISABLE_ERROR_REPORTING = "1";
      ENABLE_LSP_TOOL = "1";
    };

    # 待ち状態の種類を音で聞き分けられるようにする。
    hooks = {
      Notification = [
        {
          matcher = "idle_prompt";
          hooks = [ (playSystemSound "Submarine") ];
        }
        {
          matcher = "permission_prompt";
          hooks = [ (playSystemSound "Ping") ];
        }
      ];
      Stop = [ { hooks = [ (playSystemSound "Funk") ]; } ];
    };

    permissions = {
      defaultMode = "auto";

      allow = [
        "Bash(cat:*)"
        "Bash(echo:*)"
        "Bash(ls:*)"
        "Bash(mkdir:*)"
        "Bash(npm init:*)"
        "Bash(npm install:*)"
        "Bash(pnpm install:*)"
        "Bash(yarn install:*)"
        "WebSearch"
      ];

      ask = [
        "Bash(git checkout:*)"
        "Bash(git push:*)"
        "Bash(git reset:*)"
        "Bash(rm:*)"
      ];

      # 取り消せない操作、秘密情報への接触、レビューや検査の迂回を、許可の確認ごと塞ぐ。
      deny = [
        "Bash(brew install:*)"
        "Bash(chmod 777:*)"
        "Bash(gh repo delete:*)"
        "Bash(git commit --no-verify:*)"
        "Bash(git config:*)"
        "Bash(git push --force:*)"
        "Bash(git push -f:*)"
        "Bash(git push origin --force:*)"
        "Bash(git push origin -f:*)"
        "Bash(git rebase:*)"
        "Bash(nc:*)"
        "Bash(npm publish:*)"
        "Bash(pnpm publish:*)"
        "Bash(psql:*)"
        "Bash(sudo:*)"
        "Bash(wget:*)"
        "Edit(**/.env)"
        "Edit(**/.env.*.local)"
        "Edit(**/.env.dev*)"
        "Edit(**/.env.local)"
        "Edit(**/.env.prod*)"
        "Edit(**/.env.stag*)"
        "Edit(~/.ssh/**)"
        "Read(**/.env)"
        "Read(**/.env.*.local)"
        "Read(**/.env.dev*)"
        "Read(**/.env.local)"
        "Read(**/.env.prod*)"
        "Read(**/.env.stag*)"
        "Read(~/.ssh/**)"
      ];
    };

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
  # 宣言した項目だけを既存の設定へ重ねる。重ね方は merge-claude-settings.jq とそのテストを参照。
  home.activation.mergeClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_file="$HOME/.claude/settings.json"
    run mkdir -p "$HOME/.claude"
    if [[ -f $settings_file ]]; then
      merged_file="$(mktemp "$HOME/.claude/.settings.json.XXXXXX")"
      ${lib.getExe pkgs.jq} -s -f ${../../../scripts/merge-claude-settings.jq} "$settings_file" ${declaredSettings} >"$merged_file"
      run mv "$merged_file" "$settings_file"
    else
      run install -m 0644 ${declaredSettings} "$settings_file"
    fi
  '';
}
