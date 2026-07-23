{ pkgs, ... }:
{
  # 複数のコーディングエージェントを、ターミナル内の一貫した操作で管理できるようにする。
  # プラグイン本体は Nix 化できない（git clone + ビルドの imperative 管理）ため、
  # `dotfiles herdr-plugins` で宣言済みバージョンへ揃える。justfile を参照。
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
      };

      keys = {
        # worktree の作成は gtr（gtr.copy.* / gtr.hooks.postCreate が走る）へ一本化し、
        # フックを迂回する herdr ネイティブ作成の入口を塞ぐ。
        new_worktree = "";

        # gtr が作った既存 checkout をワークスペース化する入口として、
        # 空いた prefix+shift+g を「開く」側に割り当てる。
        open_worktree = "prefix+shift+g";

        command = [
          {
            key = "prefix+alt+g";
            type = "popup";
            command = "lazygit";
            width = "90%";
            height = "90%";
          }
          # diff レビュー用サイドバー（エージェントへ行コメントを送り返せる）。
          {
            key = "prefix+alt+r";
            type = "plugin_action";
            command = "persiyanov.reviewr.toggle";
          }
          # ghq プロジェクトを fzf で選んでワークスペース化する。
          # worktree-open アクションは gtr のフックを迂回するため割り当てない。
          {
            key = "prefix+alt+s";
            type = "plugin_action";
            command = "sessionizer.open";
          }
        ];
      };
    };
  };

  # herdr-sessionizer のビルド・実行に必要。
  home.packages = [ pkgs.bun ];

  # sessionizer のプロジェクト探索先を ghq 配下へ固定する。放置すると初回実行時に
  # サンプル（nvim/copilot レイアウト）が自動生成されるため、先に宣言しておく。
  # depth = 4 は ghq の <root>/github.com/<owner>/<repo>（深さ3）に加えて、
  # gtr の <repo>-worktrees/<branch>（深さ4）の checkout も picker に載せるため。
  xdg.configFile."herdr/plugins/config/sessionizer/config.toml".text = ''
    [projects]
    roots = ["~/ghq"]
    git_only = true
    depth = 4
  '';
}
