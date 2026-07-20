# GitHub Copilot CLI

`~/.copilot/` へ配置する、GitHub Copilot CLI専用の設定を管理します。

- `.copilot/settings.json`: 端末間で共有するユーザー設定
- `.copilot/copilot-instructions.md`: Copilotだけに適用する共通指示
- `.copilot/agents/`: Copilot専用のcustom agent
- `.copilot/skills/`: Copilot専用のskill
- `.copilot/hooks/`: Copilot専用のhook

認証、保存済み権限、セッション、導入済みplugin、plugin dataは管理しません。複数ツールで使うskillは `../agents/.agents/skills/` に置きます。
