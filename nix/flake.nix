{
  description = "Home Manager configuration of semba macOS";

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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-worktree-runner = {
      url = "github:coderabbitai/git-worktree-runner";
      flake = false;
    };

    catppuccin-ghostty = {
      url = "github:catppuccin/ghostty";
      flake = false;
    };

    mo = {
      url = "github:k1LoW/mo";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      treefmt-nix,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      # nix fmt 用の treefmt 設定。programs.nixfmt は RFC 準拠の nixfmt を使う。
      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };
    in
    {
      homeConfigurations."semba" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./hosts/LCDEV0215/home.nix ];
      };

      formatter.${system} = treefmtEval.config.build.wrapper;

      checks.${system}.formatting = treefmtEval.config.build.check self;
    };
}
