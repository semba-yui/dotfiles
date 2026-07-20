# Claude Code

`~/.claude/` へ配置する、Claude Code専用の設定を管理します。

- `.claude/settings.json`: 端末間で共有するユーザー設定
- `.claude/CLAUDE.md`: Claude Codeだけに適用する共通指示
- `.claude/agents/`: Claude Code専用のsub-agent
- `.claude/skills/`: Claude Code専用のskill
- `.claude/hooks/`: Claude Code専用のhook設定とスクリプト

認証、履歴、キャッシュ、プロジェクト状態など、Claude Codeが実行中に生成するファイルは管理しません。複数ツールで使うskillは `../agents/.agents/skills/` に置きます。
