{
  config,
  lib,
  pkgs,
  ...
}:

let
  # 公式の `npx skills add` は GitHub の master を取るため、手元の herdr と版がずれる。
  # `herdr --skill` はそのバイナリに同梱された版の合った skill を出力するので、ビルド時に生成する。
  herdrSkill = pkgs.runCommand "herdr-skill" { } ''
    mkdir -p "$out"
    ${lib.getExe config.programs.herdr.package} --skill > "$out/SKILL.md"
  '';
in
{
  imports = [ ./agent-skills.nix ];

  programs.agent-skills = {
    sources.herdr = {
      path = herdrSkill;
      filter.maxDepth = 0;
    };
    skills.enableAll = [ "herdr" ];
  };

  # 複数のコーディングエージェントを、ターミナル内の一貫した操作で管理できるようにする。
  programs.herdr = {
    enable = true;

    # 変更は Home Manager が config.toml 生成後に `herdr server reload-config` で即反映する。
    settings = {
      onboarding = false;

      # Ghostty (Catppuccin Mocha) と配色を揃える。ビルトインの catppuccin は
      # flavor 名が非公開のため、Mocha と色が違う場合は theme.custom でピン留めする。
      theme.name = "catppuccin";

      ui = {
        # herdr を見ていない間も done / blocked に気づけるよう macOS 通知センターへ直接送る。
        toast = {
          delivery = "system";
          delay_seconds = 1;
        };

        # バックグラウンドのワークスペースで状態が変わったら音でも知らせる。
        sound.enabled = true;

        # 複数エージェント運用時、サイドバーを要対応（blocked / done）順に並べる。
        agent_panel_sort = "priority";
      };

      # 日本語 IME との衝突対策（macOS 専用・experimental）。
      # prefix モード中だけ英字配列へ切り替え、TUI エージェント上では IME 候補窓を追従させる。
      experimental = {
        switch_ascii_input_source_in_prefix = true;
        reveal_hidden_cursor_for_cjk_ime = true;
        cjk_ime_agents = [
          "claude"
          "codex"
        ];

        # terminal-browser がペイン内に Chromium を描画するのに必要。Ghostty は
        # Kitty graphics protocol を解釈できるため、有効にしても通常のペインは変わらない。
        kitty_graphics = true;
      };

      keys = {
        # worktree の作成は gtr（gtr.copy.* / gtr.hooks.postCreate が走る）へ一本化し、
        # フックを迂回する herdr ネイティブ作成の入口を塞ぐ。
        new_worktree = "";

        # gtr が作った既存 checkout をワークスペース化する入口として、
        # 空いた prefix+shift+g を「開く」側に割り当てる。
        open_worktree = "prefix+shift+g";

        command = [
          # diff レビュー用サイドバー（エージェントへ行コメントを送り返せる）。
          {
            key = "prefix+alt+r";
            type = "plugin_action";
            command = "persiyanov.reviewr.toggle";
          }
          # 上流の herdr プラグインはこの 1 行を呼ぶだけで、導入時に curl | bash で本体を入れ直す。
          # 本体は Homebrew cask に一本化したいので、プラグインを介さず shell で直接呼ぶ。
          {
            key = "prefix+alt+b";
            type = "shell";
            command = "terminal-browser open --split right";
            description = "ブラウザを右スプリットで開く";
          }
        ];
      };
    };
  };
}
