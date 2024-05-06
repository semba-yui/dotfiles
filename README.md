# dotfiles

Configuration Files For Mac

# Environment

- Mac OS (Apple Silicon)
- zsh

# How to use

## Grant permission to install.sh

```shell
chmod +x install.sh
```

## Run install.sh

```shell
./install.sh
```

# Update Brewfile

```shell
brew bundle dump --force --file=homebrew/Brewfile
```

# 作りについて

`install.sh` では、対象をホワイトリスト形式で管理するため、for文で指定などはしていない。

# その他初回セットアップ時にやること

## App Store 経由でインストール

- X Code
- LINE
- CompareMerge2 

## Mac の設定変更

- FileVault を ON
- siri を OFF
- spotlight を OFF
- Dock のサイズ・拡大を変更
- Dock を自動的に非表示
- Bluetooth を表示
- バッテリーの残量の表示
- 入力の自動変換・自動ピリオドを削除
- mac の起動音を削除
- Touch ID の追加

## フォント変更

- IDE、iTerm2 などのフォントを HackGen Nerd に変更
