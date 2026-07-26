# Claude Code

`~/.claude/` へ配置する、Claude Code専用の設定を管理します。

- `.claude/CLAUDE.md`: Claude Codeだけに適用する共通指示
- `.claude/agents/`: Claude Code専用のsub-agent
- `.claude/skills/`: Claude Code専用のskill
- `.claude/hooks/`: Claude Code専用のhook設定とスクリプト

`~/.claude/settings.json` は、ローカルで有効化したプラグインやMarketplaceの識別子が混在し、Claude Code自身も更新するため管理しません。
認証、履歴、キャッシュ、プロジェクト状態など、Claude Codeが実行中に生成するファイルも管理しません。
複数ツールで使うskillは `../agents/.agents/skills/` に置きます。
