{
  description = "Nix configuration for macOS";

  # Why:
  # - flake-parts は便利だが、今は抽象度を上げすぎないため採用しない。

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # コミット署名の秘密鍵を Secure Enclave の中に作り、端末の外へ持ち出せないようにする。
    nix-secure-enclave-key = {
      url = "github:ryoppippi/nix-secure-enclave-key";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixpkgs のファイル索引を毎週配布するもの。手元で索引を作ると数十分かかるため、配布版を使う。
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-k1low-tap = {
      url = "github:k1LoW/homebrew-tap";
      flake = false;
    };

    homebrew-stablyai-orca-tap = {
      url = "github:stablyai/homebrew-orca";
      flake = false;
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # git gtr (worktree管理CLI)。nixpkgs 未収載のためソースを直接取り込み、
    # home モジュール側で derivation 化する。
    git-worktree-runner = {
      url = "github:coderabbitai/git-worktree-runner";
      flake = false;
    };

    # Agent skill の配置は agent-skills-nix の Home Manager モジュールに任せる。
    # 上流は tag を打っていないため rev で固定する。
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix/dc122af897ab9a685c20ae54c639021619dbbb52";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 以下は skill の配布元。SHA で固定した上流を Nix store へ取り込み、選択と配置は
    # modules/home/programs/agent-skills.nix で行う。URL に rev を含めているため
    # `nix flake update` では動かず、更新は rev の書き換えで行う。

    # skill が指示するサブコマンドは gh-stack の版で変わる。gh.nix の pkgs.gh-stack を
    # 上げたら、この rev も対応する release へ合わせる。
    gh-stack = {
      url = "github:github/gh-stack/d4ab7ab47e5b3e3708a27c8c42abcdf4bc321419";
      flake = false;
    };

    mizchi-skills = {
      url = "github:mizchi/skills/62f580819410cb1d398e4d7f234bbd0aad1c1a15";
      flake = false;
    };

    orca = {
      url = "github:stablyai/orca/7faa9f7cd3bda68189646b1e9def6cc8aae3b1cb";
      flake = false;
    };

    stop-ai-slop-jp = {
      url = "github:iKora128/stop-ai-slop-jp/e09d32796f253a62693885757cea484c275d06f2";
      flake = false;
    };

    # root skill が参照する sibling skill を、packages/teamwork-graph-cli-release.json の
    # CLI 版と互換な commit へ揃える。CLI を上げたらこの rev も合わせる。
    twg-cli = {
      url = "github:atlassian/twg-cli/35710745f766fd19953d2a8a86e27cd193996598";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          package:
          builtins.elem (nixpkgs.lib.getName package) [
            "teamwork-graph-cli"
          ];
      };
      apmCliWithWebsocketsRuntimeDependency = pkgs.callPackage ./packages/apm-cli.nix { };
      darwinConfigurations = import ./hosts { inherit inputs; };
      teamworkGraphCli = pkgs.callPackage ./packages/teamwork-graph-cli.nix { };

      # nix fmt 用の treefmt 設定。programs.nixfmt は RFC 準拠の nixfmt を使う。
      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.deadnix.enable = true;
        programs.just.enable = true;
        programs.nixfmt.enable = true;
        programs.statix = {
          enable = true;
          # 関連する設定でも、理由のコメントごとに分けて書くほうが読みやすいため、キーの重複は許す。
          disabled-lints = [ "repeated_keys" ];
        };
        programs.shellcheck.enable = true;
        programs.shfmt.enable = true;
        # 増分検査では source 先が入力一覧に含まれないため、明示した参照先も検査する。
        settings.formatter.shellcheck.options = [ "-x" ];
        # statix と deadnix の書き換え結果を最終的なレイアウトに揃えるため、nixfmt を最後に実行する。
        settings.formatter.nixfmt.priority = 1;
      };
    in
    {
      inherit darwinConfigurations;

      formatter.${system} = treefmtEval.config.build.wrapper;
      packages.${system} = {
        inherit (pkgs) just oxfmt;
        teamwork-graph-cli = teamworkGraphCli;
      };

      checks.${system} =
        nixpkgs.lib.mapAttrs' (
          hostname: configuration: nixpkgs.lib.nameValuePair "darwin-${hostname}" configuration.system
        ) darwinConfigurations
        // {
          ai-cli-installation =
            pkgs.runCommand "ai-cli-installation-test"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.curl
                ];
              }
              ''
                mkdir scripts
                cp ${./scripts/ai-cli-installation.sh} scripts/ai-cli-installation.sh
                cp -R ${./tests} tests
                bash tests/ai-cli-installation-test.sh
                touch "$out"
              '';
          apm-cli = apmCliWithWebsocketsRuntimeDependency;
          # Fish を導入しないホストでも構文を検査できるよう、実行系ごと Nix で用意する。
          fish-syntax = pkgs.runCommand "fish-syntax-check" { nativeBuildInputs = [ pkgs.fish ]; } ''
            export HOME="$TMPDIR"
            cp -R ${../fish} fish
            fish -n fish/conf.d/*.fish fish/functions/*.fish
            touch "$out"
          '';
          formatting = treefmtEval.config.build.check self;
          teamwork-graph-cli-release =
            pkgs.runCommand "teamwork-graph-cli-release-test"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.jq
                ];
              }
              ''
                mkdir scripts
                cp ${./scripts/teamwork-graph-cli-release.sh} scripts/teamwork-graph-cli-release.sh
                cp -R ${./tests} tests
                bash tests/teamwork-graph-cli-release-test.sh
                touch "$out"
              '';
          teamwork-graph-cli = teamworkGraphCli;
        };
    };
}
