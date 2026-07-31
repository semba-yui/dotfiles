# herdr 運用ガイド

[herdr](https://herdr.dev) は複数のコーディングエージェントをターミナル内で管理するワークスペースマネージャです。設定値の理由は [herdr.nix](../nix/modules/home/programs/herdr.nix) のコメントに、ツールをまたぐ運用と設計判断をここに書きます。

## 役割と全体像

herdr に任せるのは「ワークスペース・タブ・ペインの管理」「エージェントの状態把握と通知」「既存 worktree のワークスペース化」です。worktree の作成・削除とシェルレベルの移動は gtr / fish に任せます（[worktree ワークフロー](worktree.md)を参照）。

## キーバインド

prefix はデフォルトの `Ctrl+B` で、**順番押し**です（`Ctrl+B` を押して離してから次のキー）。prefix はペイン内のアプリより先に herdr が横取りするため、Claude Code などのエージェントにフォーカスがあっても効きます。

カスタム定義は次の6つです（一覧は [cheatsheet.md](cheatsheet.md)、デフォルトキーは `prefix+?` のヘルプ）。

| キー             | 動作                                                         |
| ---------------- | ------------------------------------------------------------ |
| `prefix+alt+g`   | lazygit をポップアップ（90%）で開く                          |
| `prefix+alt+r`   | reviewr の diff レビューサイドバーをトグル                   |
| `prefix+alt+s`   | sessionizer — ghq 配下のプロジェクトを選んでワークスペース化 |
| `prefix+alt+b`   | ブラウザペインを右スプリットで開く                           |
| `prefix+shift+b` | ブラウザペインをオーバーレイで開く                           |
| `prefix+shift+g` | 既存 worktree をワークスペースとして開く（作成は無効化済み） |

lazygit は「サッと全体を眺める」用、reviewr は「エージェントの成果物をレビューして行コメントを入力へ送り返す」用と使い分けます。

ブラウザに `prefix+b` を使わないのは、これが herdr デフォルトのサイドバートグルだからです。プラグイン起動は `prefix+alt+*` に揃えつつ、一時的なプレビュー用のオーバーレイだけ空いている `prefix+shift+b` に置いています。

## プラグイン管理

プラグインは git clone + ビルドの imperative な仕組みで Nix 化できないため、justfile で導入対象を固定して再現します。

```sh
dotfiles herdr-plugins  # 3プラグイン（browser / reviewr / sessionizer）を最新へ揃える
dotfiles herdr-doctor   # config 検証・連携フックの陳腐化・プラグイン一覧を検査
```

**バージョンは固定しません。** herdr 本体もプラグインも更新が速く、herdr-browser のように tag を一度も打たないプラグインもあるため、tag ピン留めという前提が成立しないためです。代わりに、更新して壊れたときは `herdr plugin list --json` の `resolved_commit` を `--ref` へ渡して個別に戻します。`dotfiles herdr-plugins` は switch では走らない手動レシピなので、更新のタイミングは自分で選べます。

引き換えに受け入れるリスクが1つあります。herdr 本体は Nix でピン留めされている一方でプラグインは追従するため、プラグインの `min_herdr_version` が手元の herdr を追い越し得ます（実際 reviewr は 0.26.2 時点で 0.7.5 を要求し、herdr 0.7.5 とちょうど同じ高さです）。`nix flake check` はこれを検出しないので、`dotfiles herdr-doctor` が出す `herdr plugin list` の warnings が唯一の signal です。

プラグイン設定の扱いは2つに分かれます。

- sessionizer の探索設定（`~/.config/herdr/plugins/config/sessionizer/config.toml`）は herdr.nix から宣言管理します。放置すると初回実行時にサンプルが自動生成されてしまうためです
- herdr-browser の `browser.json` は宣言管理しません。ツールバーの `[-]` / `[+]` によるズーム変更がこのファイルへ書き戻される仕様で、読み取り専用のシンボリックリンクにすると壊れるためです。HiDPI で CPU 負荷が気になるときの主な調整ノブは `captureScale`（`0.75` で画素数が約44%減）で、必要になった時点で手で書きます。場所は `herdr plugin config-dir official.browser`

## ブラウザペインと CDP 連携

[herdr-browser](https://github.com/ogulcancelik/herdr-browser) はペイン内に実物の Chromium を描画し、その view を Chrome DevTools Protocol クライアントへ公開します。開き方は3つあります。

- `http://localhost:*` / `127.0.0.1` / `[::1]` のリンクを **Control+クリック**（macOS でも Control。通常のクリックはターミナルへの入力のまま）
- `prefix+alt+b`（右スプリット）/ `prefix+shift+b`（オーバーレイ）
- 他のツールから `herdr plugin pane open --plugin official.browser --entrypoint browser`（`--env HERDR_BROWSER_INITIAL_URL=...` で初期 URL を渡せる）

描画には `experimental.kitty_graphics` が必要で、Ghostty が Kitty graphics protocol を解釈できることが前提です。ターミナルを乗り換えるとブラウザペインだけ映らなくなります。

### エージェントに操作させる

本命の用途です。素の Playwright や agent-browser は headless か、このセッションと無関係な Chrome ウィンドウで動くため、何が起きたかは事後のスクリーンショットからしか分かりません。herdr-browser の CDP ゲートウェイへ繋げば、エージェントの操作を作業中のレイアウトの中で見ながら、詰まった瞬間に自分のマウスとキーボードで介入できます。介入しても自動化クライアントの接続は切れません。

手順は APM で導入した `herdr-browser` skill（`~/.claude/skills/herdr-browser/SKILL.md`）が正です。要点だけ書くと、`herdr plugin list --plugin official.browser --json` で `plugin_root` を引き、`bun run "<plugin_root>/src/cli.ts" connect --view <view_id>` が返す `cdp_http_url` を Playwright MCP の `--cdp-endpoint` や agent-browser へ渡します。プラグインはグローバルな実行ファイルを入れないため、パスは毎回この方法で解決します。

Claude Code が headless 側へ流れないよう、`HERDR_ENV=1` のときは CDP ゲートウェイを使う旨を [CLAUDE.md](../claude/.claude/CLAUDE.md) に書いています。既存の Playwright 系 skill のほうがトリガー記述が広く、放っておくとそちらが先に発火するためです。

skill は上流の CLI と一体なので自作せず、[apm.yml](../apm/apm.yml) からプラグイン本体のリポジトリを直接参照しています。ただし**プラグイン本体は最新追従、skill は SHA 固定**なのでずれ得ます。`dotfiles herdr-plugins` でプラグインを更新したら、`apm.yml` の SHA も合わせて更新してください。

### 使わない場面

- リモート SSH セッション（フレームの帯域が大きく非現実的）
- ダウンロード、右クリックメニュー、DevTools、IME、ページ内検索、テキスト選択とコピーが要るとき（いずれも未対応）

Chromium は herdr セッションごとの専用プロファイルで別プロセスとして起動します。普段の Chrome のログイン状態は引き継がれません。

## 通知と表示

- エージェントの done / blocked は macOS 通知センター（`ui.toast.delivery = "system"`）と音で届きます。herdr を見ていなくても気づけます
- サイドバーは要対応（blocked / done）順に並びます（`agent_panel_sort = "priority"`）
- Claude Code と Codex の状態報告フックは `herdr integration install` で導入済み。陳腐化は `dotfiles herdr-doctor` が検知します

## 日本語 IME 対策

experimental 設定で、prefix モード中だけ英字配列へ自動切替し、エージェントの TUI 上でも IME 候補窓がカーソルに追従するようにしています。日本語入力中でも prefix キーがそのまま効きます。

## 設計判断

- **worktree 作成は gtr に一本化**し、herdr の `new_worktree` バインドを無効化 — 経緯は [worktree ワークフロー](worktree.md)
- **テーマはビルトインの `catppuccin`**。公式ドキュメントは flavor 名（Mocha 等）を明言していないため、Ghostty（Catppuccin Mocha）と色味がずれた場合は `theme.custom` で Mocha の16トークンをピン留めする方針

## 今後の候補（第2陣プラグイン）

2026-07 の導入時に見送ったもの。使い勝手が固まってから判断します。

- `Davidcreador/herdr-token-dashboard` — トークン消費のライブダッシュボード。Claude Code のコストは推計値、通知はダッシュボード表示中のみという制約を理解した上で
- `ogulcancelik/herdr-plugin-github-start` — GitHub Issue/PR の URL からエージェント付きタブを起動。herdr 作者本人のサンプル的位置づけで実験段階（コミット2つ）
- `dcolinmorgan/herdr-remote` — メニューバーアプリ / Telegram からの遠隔監視・承認。Herdi.app + relay + cloudflared と構成が別物なので、外出先から承認したいニーズが実際に出てから
