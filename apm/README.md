# APM

公開されている外部配布のskills、agents、hooks、plugins、MCP serverをグローバル環境へ導入します。

- `apm.yml`: 利用する公開外部依存、固定するref、展開先の宣言
- `apm.lock.yaml`: 解決したcommit、content hash、配置ファイル
- `config.json`: 端末上のAPM設定であるためGit管理しない
- `apm_modules/`: lockから再生成できるcacheであるためGit管理しない

Home Managerは`~/.apm`をこのディレクトリへ直接リンクします。APMが生成するskill本体は`~/.agents/skills/`や`~/.claude/skills/`へ配置され、Git管理しません。

公開可能な自作skillは`../agents/`または各ツールのディレクトリ、非公開で共有するskillは別のprivate repository、端末限定のskillはホームディレクトリだけで管理します。由来が異なるskillで同じ名前を使わないでください。

```sh
dotfiles ai-install
dotfiles ai-check
dotfiles ai-update
```

依存はSHAで固定します。更新するときは導入先の内容を確認して`apm.yml`のSHAを変更し、`dotfiles ai-update`でlockと生成物を更新します。
