set default-list

current-host := `hostname -s`

# Nixはnixfmt、それ以外の対応形式はOxfmtで整形する
[group('整形・検証')]
fmt:
    cd nix && nix fmt
    just --justfile justfile --fmt
    oxfmt .

# Flake全体を評価し、リポジトリ全体のフォーマットを検証する
[group('整形・検証')]
check:
    cd nix && nix flake check
    just --justfile justfile --fmt --check
    oxfmt --check .

# APMのmanifest、lock、生成物に不整合や安全上の問題がないか検証する
[group('整形・検証')]
ai-check:
    cd apm && apm install --frozen --dry-run
    cd apm && apm audit --ci

# 端末が宣言した構成どおりにセットアップされているか診断する
[group('整形・検証')]
doctor:
    ./nix/scripts/doctor.sh

# 指定したホストの構成を、反映せずにビルドする
[group('整形・検証')]
build host=current-host:
    cd nix && nix build ".#darwinConfigurations.{{ host }}.system" --no-link

# 指定したホストの構成を、確認後に反映する
[group('反映・更新')]
switch host=current-host:
    cd nix && nh darwin switch . --hostname "{{ host }}" --ask --no-update-lock-file --show-activation-logs

# lock済みのAI依存を再現し、生成物を更新する
[group('反映・更新')]
ai-install:
    cd apm && apm install --frozen

# AI依存の更新内容を確認し、承認後にlockと生成物を更新する
[group('反映・更新')]
ai-update:
    cd apm && apm update

# Flake入力を更新し、検証、反映、commitまで順番に実行する
[group('反映・更新')]
update:
    ./nix/scripts/update.sh
