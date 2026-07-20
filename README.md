# dotfiles

Nix Flakes、nix-darwin、Home Managerを使い、所有するMacの開発環境を宣言的に管理します。

## 初期セットアップ

### 1. Xcode Command Line Tools

工場出荷状態のmacOSでは、最初にAppleの開発用コマンドをインストールします。

```sh
xcode-select --install
```

GUIの案内に従ってインストールを完了してください。この操作はAppleの確認を伴うため、自動化の対象外です。

### 2. 自動セットアップ

次のコマンドは、Nixの導入、リポジトリのclone、Flakeの検証、現在のホストのビルド、nix-darwinの初回適用を順番に行います。

```sh
curl -fsSL https://raw.githubusercontent.com/semba-yui/dotfiles/main/nix/scripts/bootstrap.sh | bash
```

スクリプトは適用前に、macOS、ホスト名、ユーザー名、ホームディレクトリを検査します。既存のcheckoutに未コミットの変更がある場合や、対応するホスト設定がない場合は変更を加えず停止します。

実行内容を先に確認したい場合は、ダウンロードしてから内容を確認してください。

```sh
curl -fsSL https://raw.githubusercontent.com/semba-yui/dotfiles/main/nix/scripts/bootstrap.sh \
  -o /tmp/dotfiles-bootstrap.sh
less /tmp/dotfiles-bootstrap.sh
bash /tmp/dotfiles-bootstrap.sh
```

### 3. 手動セットアップ

nix-darwinの反映後、macOSが保護する内部状態や秘密情報を手動で設定します。

- Google日本語入力を入力ソースへ追加する
- Raycastを起動し、Spotlightの代わりに使うショートカットを設定する
- CleanShot Xへライセンスを登録する
- CleanShot Xへ画面収録など必要な権限を許可する
- 利用するGitHubアカウントをGit Credential Managerで認証する

### 4. 動作確認

新しいシェルを開き、セットアップ状態を診断します。

```sh
dotfiles doctor
```

初期セットアップ処理だけを再検証し、システムへ反映しない場合は次を実行します。

```sh
./nix/scripts/bootstrap.sh --check
```

## 日常的な操作

`dotfiles`は作業ディレクトリに関係なく実行できます。引数なしでは利用可能なタスクと説明を表示します。

```sh
dotfiles
```

主な操作は次のとおりです。

```sh
dotfiles fmt       # NixとOxfmt対応形式を整形する
dotfiles check     # Flake全体と設定ファイルの整形を検証する
dotfiles doctor    # 現在のセットアップ状態を診断する
dotfiles build     # 現在のホストを反映せずにビルドする
dotfiles switch    # 現在のホストへ確認後に反映する
dotfiles update    # Flake入力を更新し、検証、反映、commitまで行う
dotfiles ai-check   # AI依存のlockと生成物を検証する
dotfiles ai-install # lock済みのAI依存を再現する
dotfiles ai-update  # AI依存の更新内容を確認して更新する
```

## AIツールの設定

Claude Code、Codex、GitHub Copilot CLIの設定は、ツールごとのトップレベルディレクトリで管理します。各ディレクトリは `claude/.claude/` のようにホームディレクトリ上の構造を再現しています。

- `agents/`: 複数ツールで共通利用するskill
- `claude/`: Claude Code専用の設定、agents、skills、hooks
- `codex/`: Codex専用の設定、agents、hooks、plugins
- `copilot/`: GitHub Copilot CLI専用の設定、agents、skills、hooks
- `apm/`: 外部配布されたAI向け資産のmanifest、lock、生成物

編集対象の設定はHome Managerからリポジトリへ直接リンクします。一方、認証、履歴、信頼状態、セッション、キャッシュなど、各ツールが生成する内部状態はGitで管理しません。

## 管理範囲

- nix-darwin: macOSのシステム設定、ログインシェル、Nix、Homebrew
- Home Manager: ユーザー単位のCLI、GUIアプリ、設定ファイル
- Homebrew cask: Nixでの配布が適さないmacOSアプリ
- 手動設定: ライセンス、アカウント認証、macOSが保護する権限と内部状態

端末固有の値は`nix/hosts/<hostname>/`、所有する端末で共通の設定は`nix/modules/`で管理します。

## トラブルシューティング

設定を反映せずに問題を確認する場合は、先に検証とビルドを実行します。

```sh
dotfiles check
dotfiles build
```

Home Managerが既存ファイルとの競合を報告した場合は、対象を確認して退避してから再実行してください。bootstrapや更新処理は、未コミットの変更を自動で破棄しません。
