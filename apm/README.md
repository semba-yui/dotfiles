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

依存はSHAで固定します。更新するときは導入先の内容を確認して`apm.yml`のSHAを変更し、lockと生成物を更新します。

ただし`dotfiles ai-update`（`apm update --global`）はこのリポジトリの依存構成では使えません。APM 0.21.0はSHA固定の依存に対して上流のannotated tagを探し、見つからないとSHAをbranchやlightweight tagへ置き換えることを拒んで中断します。現在の依存にはannotated tagを打っていないリポジトリが含まれるため、この検査を必ず通過できません。

`apm.yml`へ依存を追加する、またはSHAを書き換えるときは`--frozen`なしの`apm install --global`を直接実行し、生成された`apm.lock.yaml`の差分を確認してから`dotfiles ai-check`で`--frozen`の再現性を検証します。`dotfiles ai-install`は既にlock済みの状態を再現するためのものなので、lockに無い依存では失敗します。
