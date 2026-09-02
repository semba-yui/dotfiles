# Claude Code と Codex のバージョン固定

Claude Code（`claude`）と Codex（`codex`）は、nixpkgs のバージョンではなく、
上流の公式リリースを `nix/packages/*-release.json` で直接固定します。

| 対象              | 正本                                    | 更新方法                      |
| ----------------- | --------------------------------------- | ----------------------------- |
| `claude` バイナリ | `nix/packages/claude-code-release.json` | `dotfiles claude-code-update` |
| `codex` バイナリ  | `nix/packages/codex-release.json`       | `dotfiles codex-update`       |
| 各ツールの設定    | `claude/`・`codex/` ディレクトリ        | Home Manager から直接リンク   |

## nixpkgs 版を使わない理由

どちらも上流が日次に近い頻度でリリースし、nixpkgs への取り込みは数日遅れます。
Codex は nixpkgs では Rust ソースからのビルドで、リリース当日には版が存在しません。

固定方法は、それぞれ上流が公式に配布している成果物へ寄せています。

- Claude Code は nixpkgs の derivation をそのまま使い、`manifest` 引数だけを差し替えます。
  公式 manifest は加工せず保存するため、上流との差分は `curl | diff` だけで確認できます。
- Codex は公式インストーラ（`install.sh`）が使う署名済み配布物
  `codex-package-aarch64-apple-darwin.tar.gz` を展開して配置します。
  `bin/codex` は自身の実行ファイルの実体パスを基点に `codex-path/`・`codex-resources/` を探すため、
  配布物のディレクトリ構造を崩さず `$out/lib/codex/` へ置き、PATH へは symlink だけを出します。

## トレードオフ

`flake.lock` の nixpkgs が固定した版より新しくなっても、release lock が優先されます。
更新経路は release lock の更新だけで、`dotfiles update` はこれを Flake 入力と同時に行います。

nixpkgs 側の derivation が上流の変更に追随できなくなった場合（Claude Code の起動オプション変更など）は、
`nix flake update` で nixpkgs を進めたうえで release lock を更新します。

## 更新

`dotfiles update` は Flake 入力の更新に続けて次の2タスクを実行し、検証・反映・commit までまとめて行います。
バイナリだけを更新する場合は個別に実行します。

```sh
dotfiles claude-code-update
dotfiles codex-update
```

各タスクは、公式が公開する最新版、公開 SHA-256、取得物の SHA-256、macOS code signature、
発行元の TeamIdentifier（Anthropic は `Q6L2SF6YDW`、OpenAI は `2DC432GLL2`）を照合します。
すべて一致した場合だけ release lock を更新して package をビルドします。
構成の反映と commit は行いません。

差分とビルドを確認してから反映します。

```sh
git diff -- nix/packages/claude-code-release.json nix/packages/codex-release.json
dotfiles build LCDEV0215
dotfiles switch LCDEV0215
```

## 所有権が競合するコマンド

次のコマンドは Nix の管理対象を書き換えるため使用しません。

- `claude update` / `claude install`
- `codex --upgrade`、公式 `install.sh`、`npm install -g @openai/codex`

Claude Code の自動更新は Nix の wrapper が `DISABLE_AUTOUPDATER=1` で無効化します。

## nixpkgs 版へ戻す

`nix/modules/home/programs/claude-code.nix` と `nix/modules/home/programs/codex.nix` の
`package` 行を削除すると、Home Manager の既定である nixpkgs 版に戻ります。
その場合は `nix/packages/` の derivation と release lock、`justfile` の更新タスクも削除します。
