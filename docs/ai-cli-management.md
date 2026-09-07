# Claude CodeとCodexの管理

Claude CodeとCodexの本体は公式インストーラーで導入し、最新版を追います。
公式の自動更新を許可し、バージョンはNixで固定しません。

| 対象                                       | 管理主体                     |
| ------------------------------------------ | ---------------------------- |
| 本体と`~/.local/bin`の起動用リンク         | 各ツールの公式インストーラー |
| `~/.local/bin`のPATH登録                   | Home Manager                 |
| `CLAUDE.md`・`AGENTS.md`・statusline       | GitとHome Manager            |
| `settings.json`・`config.toml`・認証・履歴 | 各ツールとユーザー           |
| APM管理の外部skills                        | APMのmanifestとlock          |

Codexのバックグラウンドサーバーは、公式インストーラーの管理先から起動・更新します。
Nix storeへのリンクで公式の管理先を置き換えると、更新の所有権が競合します。
Claude Codeも公式のネイティブ導入にそろえ、本体とランチャーを同じ管理主体に任せます。

## 導入

Home Managerを反映して新しいシェルを開き、次を実行します。

```sh
dotfiles ai-cli-install
dotfiles doctor
```

未導入のツールだけ公式インストーラーを取得して実行します。
Claude Codeは`latest`、Codexは`latest`の正式リリースを導入します。
導入済みなら取得せず起動確認だけ行います。壊れたリンクや管理先が異なる実行ファイルは上書きしません。
インストーラーはユーザー権限で実行し、Nixのbuild・check・activationには組み込みません。

公式の管理先は次のとおりです。

| ツール      | 起動用リンク          | 本体の管理先                                   |
| ----------- | --------------------- | ---------------------------------------------- |
| Claude Code | `~/.local/bin/claude` | `~/.local/share/claude/`                       |
| Codex       | `~/.local/bin/codex`  | `${CODEX_HOME:-~/.codex}/packages/standalone/` |

Codexの補助実行ファイル`codex-code-mode-host`も公式インストーラーに任せます。

## 更新

Claude Codeは`latest`チャンネルで自動更新します。
Codexは公式のdaemonを含む更新機構に任せます。
手動で更新する場合は次を実行します。

```sh
dotfiles ai-cli-update
```

このコマンドは両方の導入先を確認してから、`claude update`と`codex update`を実行します。
一方の更新に失敗した場合、もう一方で完了した更新は巻き戻しません。
各ツールの案内に従って再起動してください。

`dotfiles update`はNixのFlake入力を更新します。
`dotfiles ai-update`はAPM管理の外部skillsに使い、本体の更新とは分離します。

## 診断と復旧

`dotfiles doctor`は、本体が公式の管理先にあること、バージョンを取得できること、PATHが公式の起動用リンクを選ぶことを検査します。
詳細は`claude doctor`と`codex doctor`で確認できます。

PATHの競合時は`type -a claude`と`type -a codex`で重複する導入先を確認します。
Nix管理の本体はHome Managerのパッケージ設定から外し、構成を反映してください。
起動用リンクを独自のラッパーで置き換えないでください。

Nixの世代を戻しても、両CLIのバージョンは戻りません。
不具合時は[Claude Codeのバージョン指定](https://code.claude.com/docs/en/setup#install-a-specific-version)と
[Codexの公式インストーラー](https://learn.chatgpt.com/docs/codex/cli)を使って、動作確認済みの版を再導入します。
Codexのインストーラーは`--release VERSION`を受け付けます。
自動更新を許可したままでは固定が持続するとは限らないため、復旧時には各ツールの更新設定も確認してください。
認証や履歴を含む`~/.claude`・`~/.codex`全体の削除は不要です。
