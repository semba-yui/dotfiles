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
