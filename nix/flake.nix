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
      pkgs = nixpkgs.legacyPackages.${system};
      darwinConfigurations = import ./hosts { inherit inputs; };

      # nix fmt 用の treefmt 設定。programs.nixfmt は RFC 準拠の nixfmt を使う。
      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.just.enable = true;
        programs.nixfmt.enable = true;
        programs.shellcheck.enable = true;
        programs.shfmt.enable = true;
      };
    in
    {
      inherit darwinConfigurations;

      formatter.${system} = treefmtEval.config.build.wrapper;
      packages.${system} = {
        inherit (pkgs) just oxfmt;
      };

      checks.${system} =
        nixpkgs.lib.mapAttrs' (
          hostname: configuration: nixpkgs.lib.nameValuePair "darwin-${hostname}" configuration.system
        ) darwinConfigurations
        // {
          formatting = treefmtEval.config.build.check self;
        };
    };
}
