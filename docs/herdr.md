# herdr 運用ガイド

[herdr](https://herdr.dev) は複数のコーディングエージェントをターミナル内で管理するワークスペースマネージャです。設定値の理由は [herdr.nix](../nix/modules/home/programs/herdr.nix) のコメントに、ツールをまたぐ運用と設計判断をここに書きます。

## 役割と全体像

herdr に任せるのは「ワークスペース・タブ・ペインの管理」「エージェントの状態把握と通知」「既存 worktree のワークスペース化」です。worktree の作成・削除とシェルレベルの移動は gtr / fish に任せます（[worktree ワークフロー](worktree.md)を参照）。

## キーバインド

prefix はデフォルトの `Ctrl+B` で、**順番押し**です（`Ctrl+B` を押して離してから次のキー）。prefix はペイン内のアプリより先に herdr が横取りするため、Claude Code などのエージェントにフォーカスがあっても効きます。

カスタム定義は次の4つです（一覧は [cheatsheet.md](cheatsheet.md)、デフォルトキーは `prefix+?` のヘルプ）。

| キー             | 動作                                                         |
| ---------------- | ------------------------------------------------------------ |
| `prefix+alt+g`   | lazygit をポップアップ（90%）で開く                          |
| `prefix+alt+r`   | reviewr の diff レビューサイドバーをトグル                   |
| `prefix+alt+s`   | sessionizer — ghq 配下のプロジェクトを選んでワークスペース化 |
| `prefix+shift+g` | 既存 worktree をワークスペースとして開く（作成は無効化済み） |

lazygit は「サッと全体を眺める」用、reviewr は「エージェントの成果物をレビューして行コメントを入力へ送り返す」用と使い分けます。

## プラグイン管理

プラグインは git clone + ビルドの imperative な仕組みで Nix 化できないため、justfile でバージョンを固定して再現します。

```sh
dotfiles herdr-plugins  # 宣言済みバージョン（reviewr / sessionizer）へ揃える
dotfiles herdr-doctor   # config 検証・連携フックの陳腐化・プラグイン一覧を検査
```

sessionizer の探索設定（`~/.config/herdr/plugins/config/sessionizer/config.toml`）だけは素の TOML なので、herdr.nix から宣言管理しています。

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
