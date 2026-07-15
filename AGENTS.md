# リポジトリガイドライン

## プロジェクト構成とモジュール

このリポジトリは、Nix Flakes、nix-darwin、Home Manager を使って macOS の開発環境を管理します。設定はすべて `nix/` 以下にあります。

- `nix/flake.nix`: Flake 入力、ホスト構成の読み込み、フォーマッター、検証を定義します。ホスト固有の値は持たせません。
- `nix/hosts/default.nix`: 利用可能なホストと nix-darwin 構成の対応を定義します。
- `nix/hosts/<hostname>/`: ユーザー名、ホームディレクトリ、プラットフォームなど、端末固有の設定を管理します。
- `nix/modules/darwin/`: 所有する Mac で共有するシステム設定を、機能単位で管理します。
- `nix/modules/home/default.nix`: 共通の Home Manager モジュールとパッケージを集約します。
- `nix/modules/home/programs/*.nix`: アプリケーションや CLI ツールごとの Home Manager モジュールです。
- `nix/flake.lock`: 依存関係を固定します。入力を更新した場合は、変更内容を確認して一緒にコミットしてください。

プログラムを追加するときは、`zed-editor.nix` のような小文字のケバブケースで専用モジュールを作り、共通 Home Manager モジュールからインポートしてください。端末固有の制約がある場合のみ、ホスト設定に差分を置きます。

## ビルド・テスト・開発コマンド

特記がない限り、`nix/` ディレクトリで実行します。

```sh
cd nix
nix fmt                         # treefmt/nixfmt で Nix ファイルを整形
nix flake check                 # Flake の評価とフォーマットを検証
nix build .#darwinConfigurations.LCDEV0215.system --no-link
sudo darwin-rebuild switch --flake .#LCDEV0215
```

構成を適用せず検証する場合は `build` を使います。`switch` は現在のユーザー環境を変更するため、ビルド結果を確認してから実行してください。依存関係は `nix flake update` で更新し、`flake.lock` の差分を確認します。

## コーディング規約と命名

インデントはスペース 2 個とし、最終的なレイアウトは `nix fmt` に従います。モジュールは宣言的かつ単一の用途に保ち、シェルフックやファイル生成より nix-darwin と Home Manager の標準オプションを優先してください。インポート、パッケージ一覧、許可リストはアルファベット順に並べます。

コメントには、値の選定理由、責務の境界、安全上の制約、副作用など、コードだけでは分からない判断を記載します。オプション名を日本語にしただけの説明や Nix 構文の説明は避け、将来設定を変更する人が「なぜこの値なのか」「なぜ別の方法ではないのか」を判断できる文脈を残してください。

## テスト方針

独立したテストフレームワークやカバレッジ基準はありません。`nix flake check` と `nix build .#darwinConfigurations.LCDEV0215.system --no-link` を必須の検証として扱います。構成を適用する場合は、ビルド成功後に `darwin-rebuild switch` を実行し、対象のコマンド、サービス、アプリが期待どおり動作することを手動で確認してください。

## コミットとプルリクエスト

コミット履歴は少なく、短い件名が中心で、`feat:` のような Conventional Commits 形式も使われています。`feat: fd の設定を追加` や `fix: fish の man キャッシュを無効化` のように、簡潔で具体的な件名を推奨します。

プルリクエストには、ユーザー環境への影響と実行した検証コマンドを記載してください。`flake.lock`、非フリーパッケージ、ホスト固有パスの変更は明記します。GUI の見た目を変更した場合のみスクリーンショットを添付し、関連 Issue があればリンクしてください。
