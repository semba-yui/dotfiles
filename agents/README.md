# 共通Agent設定

複数のAIツールで同じ内容を使う設定を管理します。単一ツールだけで使うものは、対象ツールのトップレベルディレクトリへ置きます。現時点でskillは未コミットで、必要になった時点で以下の構成に従って追加します。

- `.agents/skills/<name>/SKILL.md`: Claude Code、Codex、GitHub Copilot CLIで共通利用するskill

CodexとGitHub Copilot CLIは `~/.agents/skills/` を直接読みます。Claude CodeにはHome Managerで同じskillを `~/.claude/skills/` に配置します。

外部配布のskillは`../apm/`、公開できないskillは別のprivate repositoryまたは端末上だけで管理します。APM生成物や非公開skillと名前が重複しないようにしてください。
