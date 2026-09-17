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

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src.follows = "brew-src";
    };

    # nix-homebrew は brew 本体を自身の flake.lock でタグ固定しており、現在は 6.0.12。
    # 一方 cask の JSON API は 6.0.13 で追加された command_wrapper artifact を使う定義を
    # 配り始めていて（drawio など）、6.0.12 では定義を読めず activation が Homebrew bundle で
    # 失敗する。cask 側は選べないため brew を先に上げる。nix-homebrew が追いついたら
    # この入力と follows ごと削除する。
    # なお nix-homebrew は derivation 名を自身の lock から作るため、上書きしても
    # 名前は brew-6.0.12 のまま出る。実体はここで指定したバージョン。
    brew-src = {
      url = "github:Homebrew/brew/6.0.13";
      flake = false;
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
      url = "github:Kyure-A/agent-skills-nix/5133c874553c6c295654d8de4e3f62c95736b9c6";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 以下は skill の配布元。SHA で固定した上流を Nix store へ取り込み、選択と配置は
    # modules/home/programs/agent-skills.nix で行う。URL に rev を含めているため
    # `nix flake update` では動かず、更新は rev の書き換えで行う。

    # skill が指示するサブコマンドは gh-stack の版で変わる。gh.nix の pkgs.gh-stack を
    # 上げたら、この rev も対応する release へ合わせる。
    gh-stack = {
      url = "github:github/gh-stack/a1b4a3d4d0bcde9ec3a78ab99b2d63af121857a9";
      flake = false;
    };

    # herdr-browser プラグインが同梱する skill。CDP ゲートウェイの起動手順は上流の
    # src/cli.ts と一体なので、自作せず本体リポジトリからそのまま取り込む。
    herdr-browser = {
      url = "github:ogulcancelik/herdr-browser/be6888b71cf4eb5939ee79a746bd1a1c22ade046";
      flake = false;
    };

    mizchi-skills = {
      url = "github:mizchi/skills/aa223d8c85ba4313e2ec6fb9251cc65d46ed3291";
      flake = false;
    };

    orca = {
      url = "github:stablyai/orca/6a65d8406a0da7833c6eabbb2a4f2a149ebb5c2e";
      flake = false;
    };

    stop-ai-slop-jp = {
      url = "github:iKora128/stop-ai-slop-jp/e09d32796f253a62693885757cea484c275d06f2";
      flake = false;
    };

    # root skill が参照する sibling skill を、packages/teamwork-graph-cli-release.json の
    # CLI 版と互換な commit へ揃える。CLI を上げたらこの rev も合わせる。
    twg-cli = {
      url = "github:atlassian/twg-cli/81890e73d1169d28f400702a76f79fbbacc62414";
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
        programs.just.enable = true;
        programs.nixfmt.enable = true;
        programs.shellcheck.enable = true;
        programs.shfmt.enable = true;
        # 増分検査では source 先が入力一覧に含まれないため、明示した参照先も検査する。
        settings.formatter.shellcheck.options = [ "-x" ];
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
          formatting = treefmtEval.config.build.check self;
          teamwork-graph-cli = teamworkGraphCli;
        };
    };
}
