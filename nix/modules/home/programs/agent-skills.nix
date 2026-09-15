{ inputs, ... }:

{
  imports = [ inputs.agent-skills.homeManagerModules.default ];

  programs.agent-skills = {
    enable = true;

    # symlink-tree / copy-tree は配置先ディレクトリ全体に rsync --delete を掛けるため、
    # agents/README.md の方針で端末上だけに置いている自作 skill まで消える。link は
    # home.file 経由で自分が置いたエントリしか触らないので共存できる。
    # link の dest は $HOME 相対の静的パスに限られる（既定値のシェル変数形式は使えない）。
    targets = {
      agents = {
        enable = true;
        structure = "link";
        dest = ".agents/skills";
      };
      claude = {
        enable = true;
        structure = "link";
        dest = ".claude/skills";
      };
    };

    # ソース名は配置先ディレクトリ名と一致させる。root に SKILL.md を持つソースは
    # ID がソース名になるため、名前がそのまま配置先になる。
    sources = {
      gh-stack = {
        path = inputs.gh-stack;
        subdir = "skills";
        filter.maxDepth = 1;
      };
      herdr-browser = {
        path = inputs.herdr-browser;
        subdir = "skills";
        filter.maxDepth = 1;
      };
      orca = {
        path = inputs.orca;
        subdir = "skills";
        filter.maxDepth = 1;
      };
      stop-ai-slop-jp = {
        path = inputs.stop-ai-slop-jp;
        filter.maxDepth = 0;
      };
      twg-cli = {
        path = inputs.twg-cli;
        subdir = "skills";
        filter.maxDepth = 1;
      };

      # mizchi/skills は meta/ testing/ tooling/ の入れ子で、リポジトリごと拾うと ID が
      # meta/extract-glossary のような階層付きになり、1 段しか探索しない Claude Code から
      # 見えない。skill ごとに subdir を切って平坦化する。
      ast-grep-practice = {
        path = inputs.mizchi-skills;
        subdir = "tooling/ast-grep-practice";
        filter.maxDepth = 0;
      };
      empirical-prompt-tuning = {
        path = inputs.mizchi-skills;
        subdir = "meta/empirical-prompt-tuning";
        filter.maxDepth = 0;
      };
      extract-glossary = {
        path = inputs.mizchi-skills;
        subdir = "meta/extract-glossary";
        filter.maxDepth = 0;
      };
      optimizing-descriptions = {
        path = inputs.mizchi-skills;
        subdir = "meta/optimizing-descriptions";
        filter.maxDepth = 0;
      };
      playwright-cli = {
        path = inputs.mizchi-skills;
        subdir = "testing/playwright-cli";
        filter.maxDepth = 0;
      };
      playwright-test = {
        path = inputs.mizchi-skills;
        subdir = "testing/playwright-test";
        filter.maxDepth = 0;
      };
    };

    skills = {
      enableAll = [
        "ast-grep-practice"
        "empirical-prompt-tuning"
        "extract-glossary"
        "gh-stack"
        "herdr-browser"
        "optimizing-descriptions"
        "playwright-cli"
        "playwright-test"
        "stop-ai-slop-jp"
        "twg-cli"
      ];
      # Orca は Linear 連携の skill (linear-tickets, orca-linear) を同梱するが使わないため、
      # リポジトリ全体ではなく個別に選ぶ。
      enable = [
        "computer-use"
        "orca-cli"
        "orca-emulator"
        "orca-emulator-android"
        "orca-per-workspace-env"
        "orchestration"
      ];
    };
  };
}
