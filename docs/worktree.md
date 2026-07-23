# worktree ワークフロー

git worktree の作成・削除・移動と、herdr ワークスペースとの連携をまとめます。ツールをまたぐ運用ルールと設計判断だけをここに書き、単一ファイル内で完結する理由は各定義元のコメントに委ねます。

## 方針: 作成は gtr に一本化する

worktree の作成は必ず gtr（[git-worktree-runner](../nix/packages/git-worktree-runner.nix)）を経由します。gtr はリポジトリごとの設定に従って、作成時にファイルコピー（`gtr.copy.include` / `.worktreeinclude`）と依存セットアップ（`gtr.hooks.postCreate`）を自動実行します。herdr のネイティブ worktree 作成にはこのフック機構がなく、経路が混ざるとセットアップ漏れの worktree ができるため、herdr 側の作成バインドは意図的に無効化しています（理由は [herdr.nix](../nix/modules/home/programs/herdr.nix) の `new_worktree` コメントを参照）。

同じ理由で、herdr プラグイン sessionizer の worktree-open アクションにもキーを割り当てていません。

## 日常操作

| 操作             | 入口                                                                        | 説明                                                                                    |
| ---------------- | --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| 作成             | [`gwn`](../fish/functions/gwn.fish)                                         | ブランチを fzf で選んで worktree を作成。herdr 内では cd せず子ワークスペースとして開く |
| 移動             | `gtr cd` / [`fzf_ghq_repos`](../fish/functions/fzf_ghq_repos.fish) (Ctrl-]) | worktree 一覧・ghq リポジトリから cd する                                               |
| ワークスペース化 | [`gwo`](../fish/functions/gwo.fish) / `prefix+shift+g`                      | 既存の worktree を herdr の子ワークスペースとして開く（作成はしない）                   |
| 削除             | [`gwd`](../fish/functions/gwd.fish)                                         | worktree を fzf で選んで削除（複数可）                                                  |

いずれも Alt-X のコマンドパレットから呼べます。

## 運用ルール

- **`gwd` の前に、対応する herdr ワークスペースを閉じる（`prefix+shift+d`）。** 開いたまま削除すると、消えたディレクトリを指すワークスペースが残ります。ツールをまたぐ制約のためコードで強制できず、このルールが唯一の防止策です。

## 設計判断の記録

- **herdr と gtr の責務分担**（2026-07 の herdr 導入時に決定）: 「作成・削除 = gtr、ワークスペース化・閲覧 = herdr」。gtr は `git worktree add` を素直に使うため、gtr が作った checkout は herdr の `worktree open` がそのまま採用できます。逆方向（herdr が作って gtr のフックを走らせる）は成立しません。
- **sessionizer が gtr の worktree も一覧に載せる仕掛け**: gtr は `<repo>-worktrees/<branch>`（ghq root から深さ4）に checkout を置くため、sessionizer の探索設定を `depth = 4` にしています（[herdr.nix](../nix/modules/home/programs/herdr.nix) の sessionizer 設定コメントを参照）。
