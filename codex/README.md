# Codex

`~/.codex/` へ配置する、Codex専用の設定を管理します。

- `.codex/AGENTS.md`: Codexだけに適用する共通指示
- `.codex/agents/`: Codex専用のcustom agent
- `.codex/hooks/`: Codex専用のhook
- `.codex/plugins/`: Codex専用のskillなどをまとめるローカルplugin

`~/.codex/config.toml` にはプロジェクトの信頼状態などが混在するため管理しません。認証、セッション、memory、ログ、plugin cacheも管理対象外です。複数ツールで使うskillは `../agents/.agents/skills/` に置きます。
