{ inputs, pkgs, ... }:

let
  # nixpkgs 未収載のため、flake input のソースから自前でパッケージ化する。
  gitWorktreeRunner = pkgs.callPackage ../../../packages/git-worktree-runner.nix {
    src = inputs.git-worktree-runner;
  };
in
{
  home.packages = [ gitWorktreeRunner ];
}
