# herdr 運用ガイド

[herdr](https://herdr.dev) は複数のコーディングエージェントをターミナル内で管理するワークスペースマネージャです。設定値の理由は [herdr.nix](../nix/modules/home/programs/herdr.nix) のコメントに、ツールをまたぐ運用と設計判断をここに書きます。

## 役割と全体像

herdr に任せるのは「ワークスペース・タブ・ペインの管理」「エージェントの状態把握と通知」「既存 worktree のワークスペース化」です。worktree の作成・削除とシェルレベルの移動は gtr / fish に任せます（[worktree ワークフロー](worktree.md)を参照）。

## キーバインド

prefix はデフォルトの `Ctrl+B` で、**順番押し**です（`Ctrl+B` を押して離してから次のキー）。prefix はペイン内のアプリより先に herdr が横取りするため、Claude Code などのエージェントにフォーカスがあっても効きます。

カスタム定義は次のとおりです（一覧は [cheatsheet.md](cheatsheet.md)、デフォルトキーは `prefix+?` のヘルプ）。

| キー             | 動作                                                         |
| ---------------- | ------------------------------------------------------------ |
| `prefix+alt+r`   | reviewr の diff レビューサイドバーをトグル                   |
| `prefix+alt+b`   | terminal-browser を右スプリットで開く                        |
| `prefix+shift+g` | 既存 worktree をワークスペースとして開く（作成は無効化済み） |
| `prefix+alt+z`   | zoetrope でエージェントのセッションをフローグラフ表示        |
| `prefix+alt+f`   | file-viewer で、差分や Markdown つきでファイルを読む         |

reviewr は、エージェントの成果物をレビューして、行コメントを入力へ送り返すために使います。

ブラウザに `prefix+b` を使わないのは、これが herdr デフォルトのサイドバートグルだからです。

## プラグイン管理

プラグインは [herdr-plugins.nix](../nix/modules/home/programs/herdr-plugins.nix) が Nix でビルドし、switch のたびに `herdr plugin link <store のパス>` で登録します。`link` はビルドを実行せず、プラグインのディレクトリにも書き込まない（設定と状態は `~/.config/herdr/plugins/config/<id>` などに置かれる）ため、読み取り専用の store から登録できます。上流の `[[build]]` がしているリリースのバイナリの取得は、[nix/packages](../nix/packages/) の各パッケージが `fetchurl` で置き換えます。

| プラグイン                                                         | 中身                                                                         |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| [herdr-reviewr](https://github.com/persiyanov/herdr-reviewr)       | エージェントの diff を隣のペインでレビューし、行コメントを返す               |
| [zoetrope](https://github.com/furkankly/zoetrope)                  | フォーカス中のエージェントのセッションをフローグラフで表示する               |
| [herdr-file-viewer](https://github.com/smarzban/herdr-file-viewer) | 読み取り専用のファイルビューア。git の差分、Markdown、構文の色分けを表示する |

版は rev とハッシュで固定し、更新はパッケージの `version` と `hash` を書き換えて行います。herdr 本体と同じく Nix で固定されるため、プラグインの `min_herdr_version` が手元の herdr を追い越していれば、switch の `link` が失敗して気づけます。

`unlink` は herdr のサーバーが動いていないと失敗するため、自動では行いません。宣言から外したプラグインは `herdr plugin unlink <id>` で手動で外します。

`dotfiles herdr-doctor` は config の検証、連携フックの陳腐化、プラグインの一覧を検査します。

上流が herdr プラグインを用意していても、中身がコマンドを1行呼ぶだけのもの（terminal-browser）はプラグインとして入れず、本体を入れて `type = "shell"` のキーで直接呼びます。上流のプラグインは導入時に `curl | bash` で本体を入れ直すため、入手経路が二重になります。

## ブラウザペイン

[terminal-browser](https://github.com/zenbu-labs/terminal-browser) は Electron のオフスクリーン描画で Chromium のフレームを Kitty graphics protocol でペインへ描きます。本体は Homebrew cask で入れ、herdr からは `prefix+alt+b`（`terminal-browser open --split right`）で開きます。

描画には `experimental.kitty_graphics` が必要で、Ghostty が Kitty graphics protocol を解釈できることが前提です。ターミナルを乗り換えるとブラウザペインだけ映らなくなります。

### エージェントに操作させる

素の Playwright や agent-browser は headless か、このセッションと無関係な Chrome ウィンドウで動くため、何が起きたかは事後のスクリーンショットからしか分かりません。terminal-browser なら、エージェントが `terminal-browser open --split right <url>` で隣のペインに開き、agent-browser 互換の `terminal-browser action` で操作するので、作業中のレイアウトの中で様子を見ながら介入できます。

手順は `terminal-browser` skill が正です。新しい端末では cask の導入後に一度だけ `terminal-browser setup` を実行してください。cask 内の skill への symlink を `~/.claude/skills` などへ張り、以後は本体が起動時に版の変化を検知して張り直します。

この skill は agent-skills-nix でも APM でも管理しません。完成版の SKILL.md は release tarball にしか含まれず（リポジトリ上はテンプレート）、cask のパスは版ごとに変わるためです。setup が作る symlink は Home Manager の管理外のエントリなので、`structure = "link"` の配置とも共存します。

Claude Code が headless 側へ流れないよう、`HERDR_ENV=1` のときは terminal-browser を使う旨を [CLAUDE.md](../claude/.claude/CLAUDE.md) に書いています。既存の Playwright 系 skill のほうがトリガー記述が広く、放っておくとそちらが先に発火するためです。

上流の Claude Code プラグイン（`/browser`）は入れません。Claude Code の TUI 内に描画する hooks だけで skill を含まず、上流自身が herdr 内では非常に重いと明記しているためです。

## 通知と表示

- エージェントの done / blocked は macOS 通知センター（`ui.toast.delivery = "system"`）と音で届きます。herdr を見ていなくても気づけます
- サイドバーは要対応（blocked / done）順に並びます（`agent_panel_sort = "priority"`）
- Claude Code と Codex のセッション報告フックは、各端末で一度だけ `herdr integration install claude` / `codex` を実行して入れます。`~/.claude/settings.json` や `~/.codex/config.toml` を herdr 自身が書き換えるため Nix では管理せず、陳腐化は `dotfiles herdr-doctor` が検知します。zoetrope はこのフックが報告するセッション ID を使います
- エージェントが herdr を操作するための skill は、ビルド時に `herdr --skill` で生成して agent-skills で配ります。手元の herdr と必ず同じ版になります

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
