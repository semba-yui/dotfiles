{ inputs, lib, ... }:

let
  # 一覧を手で持つと、上流で in-progress から engineering へ移った skill が rev を上げたときに黙って抜ける。
  mattpocockEngineeringSkills = lib.attrNames (
    lib.filterAttrs (_: type: type == "directory") (
      builtins.readDir "${inputs.mattpocock-skills}/skills/engineering"
    )
  );
in
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
      # 同梱の検査スクリプトは python3 で動く。python3 は各ホストの home.packages が入れている。
      yomiyasu = {
        path = inputs.yomiyasu;
        subdir = "skills/yomiyasu";
        filter.maxDepth = 0;
      };

      # mattpocock/skills の skills/misc は上流で凍結され保守されていないため取り込まない。
      mattpocock-engineering = {
        path = inputs.mattpocock-skills;
        subdir = "skills/engineering";
        filter.maxDepth = 1;
      };
      mattpocock-in-progress = {
        path = inputs.mattpocock-skills;
        subdir = "skills/in-progress";
        filter.maxDepth = 1;
      };
      mattpocock-productivity = {
        path = inputs.mattpocock-skills;
        subdir = "skills/productivity";
        filter.maxDepth = 1;
      };

      # mizchi/skills の未選択の skill を取り込まないよう、skill ごとに subdir を指定する。
      ast-grep-practice = {
        path = inputs.mizchi-skills;
        subdir = "ast-grep-practice";
        filter.maxDepth = 0;
      };
      empirical-prompt-tuning = {
        path = inputs.mizchi-skills;
        subdir = "empirical-prompt-tuning";
        filter.maxDepth = 0;
      };
      extract-glossary = {
        path = inputs.mizchi-skills;
        subdir = "extract-glossary";
        filter.maxDepth = 0;
      };
      multi-agent-orchestration = {
        path = inputs.mizchi-skills;
        subdir = "multi-agent-orchestration";
        filter.maxDepth = 0;
      };
      optimizing-descriptions = {
        path = inputs.mizchi-skills;
        subdir = "optimizing-descriptions";
        filter.maxDepth = 0;
      };
      playwright-cli = {
        path = inputs.mizchi-skills;
        subdir = "playwright-cli";
        filter.maxDepth = 0;
      };
      playwright-test = {
        path = inputs.mizchi-skills;
        subdir = "playwright-test";
        filter.maxDepth = 0;
      };
    };

    skills = {
      enableAll = [
        "ast-grep-practice"
        "empirical-prompt-tuning"
        "extract-glossary"
        "gh-stack"
        "mattpocock-in-progress"
        "mattpocock-productivity"
        "multi-agent-orchestration"
        "optimizing-descriptions"
        "playwright-cli"
        "playwright-test"
        "yomiyasu"
      ];

      # Claude Code 組み込みの /code-review と名前がぶつかるため、code-review だけ explicit で配り分ける。
      enable = lib.remove "code-review" mattpocockEngineeringSkills;

      explicit = {
        code-review = {
          from = "mattpocock-engineering";
          path = "code-review";
          agents = [ "agents" ];
        };
        # ディレクトリ名だけ変えても frontmatter の name: code-review が残るため、name も書き換える。
        mattpocock-code-review = {
          from = "mattpocock-engineering";
          path = "code-review";
          agents = [ "claude" ];
          transform =
            { original, ... }:
            builtins.replaceStrings [ "\nname: code-review\n" ] [ "\nname: mattpocock-code-review\n" ] original;
        };
      };
    };
  };
}
