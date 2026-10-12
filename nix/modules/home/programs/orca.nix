{ inputs, ... }:

# Orca 本体は Homebrew の cask で入れる。ここでは Orca を操作するための skill を配る。
{
  imports = [ ./agent-skills.nix ];

  programs.agent-skills = {
    sources.orca = {
      path = inputs.orca;
      subdir = "skills";
      filter.maxDepth = 1;
    };
    # Orca は Linear 連携の skill (linear-tickets, orca-linear) を同梱するが使わないため、
    # リポジトリ全体ではなく個別に選ぶ。
    skills.enable = [
      "computer-use"
      "orca-cli"
      "orca-emulator"
      "orca-emulator-android"
      "orca-per-workspace-env"
      "orchestration"
    ];
  };
}
