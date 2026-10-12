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
    lefthook validate
    mise exec -- jactionlint
    just --justfile justfile --fmt --check
    oxfmt --check .

# 端末が宣言した構成どおりにセットアップされているか診断する
[group('整形・検証')]
doctor:
    ./nix/scripts/doctor.sh

# herdr の設定とエージェント連携フック（imperative 管理）が陳腐化していないか検査する
[group('整形・検証')]
herdr-doctor:
    herdr config check
    herdr integration status --outdated-only
    herdr plugin list

# 指定したホストの構成を、反映せずにビルドする
[group('整形・検証')]
build host=current-host:
    cd nix && nix build ".#darwinConfigurations.{{ host }}.system" --no-link

# 指定したホストの構成を、確認後に反映する
[group('反映・更新')]
switch host=current-host:
    cd nix && nh darwin switch . --hostname "{{ host }}" --ask --no-update-lock-file --show-activation-logs

# 初回セットアップの検査を、システムを変更せずに行う
[group('反映・更新')]
plan:
    bash ./nix/scripts/setup.sh plan

# 初回セットアップ・修復として、確認を取りながらNixの導入とnix-darwinの適用を行う
[group('反映・更新')]
apply:
    bash ./nix/scripts/setup.sh apply

# lefthook.ymlのhookを.git/hooksへ導入する（clone直後の一度だけ。hook種別を増やしたら再実行）
[group('反映・更新')]
hooks-install:
    lefthook install

# Flake入力を更新し、検証、反映、commitまで順番に実行する
[group('反映・更新')]
update:
    ./nix/scripts/update.sh

# Claude CodeとCodexを公式インストーラーで導入する（導入済みなら起動確認だけ行う）
[group('反映・更新')]
ai-cli-install:
    bash ./nix/scripts/ai-cli.sh install

# Claude CodeとCodexの公式更新コマンドを実行する
[group('反映・更新')]
ai-cli-update:
    bash ./nix/scripts/ai-cli.sh update

# 公式manifest・checksum・署名を検証してTWGのNix release lockだけを更新する
[group('反映・更新')]
teamwork-graph-cli-update:
    ./nix/scripts/update-teamwork-graph-cli.sh

# herdr-plugins.nix を使わないホストで、herdr プラグインを最新へ揃える
[group('反映・更新')]
herdr-plugins:
    herdr plugin install persiyanov/herdr-reviewr --yes
    herdr plugin list
