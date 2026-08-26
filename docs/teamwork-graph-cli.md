# Teamwork Graph CLI

Teamwork Graph CLI（`twg`）は、バイナリ、agent skills、認証情報を別の仕組みで管理します。
公式の一括セットアップは、それらの所有者を混在させるため使用しません。

| 対象                    | 正本                                 | 更新方法                                        |
| ----------------------- | ------------------------------------ | ----------------------------------------------- |
| `twg` バイナリ          | Nix の release lock                  | `dotfiles teamwork-graph-cli-update`            |
| TWG skills              | `apm/apm.yml` と `apm/apm.lock.yaml` | 他の APM 依存と同時に SHA を変更                |
| secret                  | `~/.config/twg/auth.conf`（`0600`）  | `twg login` / `twg auth refresh` / `twg logout` |
| consent・非 secret 設定 | `~/.config/twg/`                     | `twg consent` などの対話コマンド                |

## 初回セットアップ

Nix 構成をビルドして反映します。

```sh
dotfiles build LCDEV0215
dotfiles switch LCDEV0215
```

規約を確認した本人が consent とブラウザ認証を行います。
同意を自動化する `--agree` / `--yes` は使いません。

```sh
twg consent
twg login
twg whoami
twg doctor
```

Nix の launcher は `DO_NOT_TRACK=1` を `twg` のプロセスだけに設定します。
secret store は環境変数で上書きせず、TWG 公式デフォルトの `~/.config/twg/auth.conf` を使用します。
TWG はこのファイルを所有者だけが読み書きできる `0600` で作成します。
シェル全体の環境変数や PATH の追加設定は不要です。

## バイナリの更新

```sh
dotfiles teamwork-graph-cli-update
```

このタスクは公式 stable manifest、公開 SHA-256、取得物の SHA-256、macOS code signature、Atlassian の TeamIdentifier を照合します。
成功した場合だけ Nix の release lock を更新して package をビルドします。
構成の反映、commit、skills の更新は行いません。

差分とビルドを確認してから反映します。

```sh
git diff -- nix/packages/teamwork-graph-cli-release.json
dotfiles build LCDEV0215
dotfiles switch LCDEV0215
```

## skills の更新

TWG skills は root skill と sibling skills を同一 commit に固定します。
TWG だけを自動更新せず、他の APM 依存を見直すときに、CLI との互換性を確認して `apm/apm.yml` の SHA を変更します。

```sh
apm install --global
git diff -- apm/apm.yml apm/apm.lock.yaml
dotfiles ai-check
```

lock の `virtual_path` と `deployed_files` を確認し、指定した `skills/<name>` の外側が展開されていたら更新を採用しません。

## 所有権が競合するコマンド

次のコマンドは Nix または APM の管理対象を書き換えるため使用しません。

- `twg setup`
- `twg update`
- `twg skills install`
- `twg upkeep enable`
- `twg uninstall`

認証操作には `twg login`、`twg auth refresh`、`twg logout` を使用します。

## 削除

完全に削除する場合は、最初に `twg logout` で `~/.config/twg/auth.conf` の認証情報を消します。
続いて Nix の package・Home Manager module・更新タスクと、APM manifest の TWG skills を宣言から削除し、`apm install --global` と `dotfiles switch LCDEV0215` で各管理対象へ反映します。
`~/.config/twg/` に残る非 secret 設定は、内容を確認してから別途削除します。
