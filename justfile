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
    just teamwork-graph-cli-launcher-test
    just teamwork-graph-cli-release-test
    cd nix && nix flake check
    just worktree-fish-test
    lefthook validate
    just --justfile justfile --fmt --check
    oxfmt --check .

# TWG launcher が公式の認証情報保存方式を上書きしないことを検証する
[group('整形・検証')]
teamwork-graph-cli-launcher-test:
    ./nix/tests/teamwork-graph-cli-launcher-test.sh

# TWGの公開manifestからNixのrelease lockへ変換する境界を、ネットワークなしで検証する
[group('整形・検証')]
teamwork-graph-cli-release-test:
    ./nix/tests/teamwork-graph-cli-release-test.sh

# worktree 作成 UI の振る舞いと、リポジトリ管理下の Fish 構文を検証する
[group('整形・検証')]
worktree-fish-test:
    fish -n fish/conf.d/*.fish fish/functions/*.fish fish/tests/*.fish
    fish fish/tests/fzf_create_worktree_from_base_branch_test.fish

# グローバルAPMのmanifestとlockが一致し、再現可能かを変更せず検証する
# APM 0.21.0のauditはグローバル配置先をproject相対として検査するため、対応するまで使用しない
[group('整形・検証')]
ai-check:
    test -L "${HOME}/.apm"
    apm install --global --frozen --dry-run

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

# lefthook.ymlのhookを.git/hooksへ導入する（clone直後の一度だけ。hook種別を増やしたら再実行）
[group('反映・更新')]
hooks-install:
    lefthook install

# lock済みの公開AI依存をグローバル環境へ再現する
[group('反映・更新')]
ai-install:
    apm install --global --frozen

# apm.ymlで書き換えたrefを、グローバル環境のlockと生成物へ反映する
# apm updateは使わない。SHA固定の依存に対して上流のannotated tagを要求するが、依存先の
# 上流はannotated tagを打っておらず、twg-cliとgh-stackのSHA固定はCLI版との結合として
# 意図的に残すため、この検査を通過できる構成にはならない。
# --frozenを外しても書き換えていない依存はlockのcommitへ固定されたままになる。
[group('反映・更新')]
ai-update:
    apm install --global

# Flake入力を更新し、検証、反映、commitまで順番に実行する
[group('反映・更新')]
update:
    ./nix/scripts/update.sh

# 公式manifest・checksum・署名を検証してTWGのNix release lockだけを更新する
[group('反映・更新')]
teamwork-graph-cli-update:
    ./nix/scripts/update-teamwork-graph-cli.sh

# herdr プラグインを最新へ揃える（Nix 化できないため just で導入対象を固定する）
# 版は固定しない。herdr 本体もプラグインも更新が速く、herdr-browser のように tag を
# 一度も打たないプラグインもあるため、tag ピン留めは前提が成立しない。壊れたときは
# `herdr plugin list --json` の resolved_commit を --ref に渡して個別に戻す。
[group('反映・更新')]
herdr-plugins:
    herdr plugin install ogulcancelik/herdr-browser --yes
    herdr plugin install persiyanov/herdr-reviewr --yes
    herdr plugin install andrewchng/herdr-sessionizer --yes
    herdr plugin list
