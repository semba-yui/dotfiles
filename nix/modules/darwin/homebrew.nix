{
  inputs,
  username,
  ...
}:

# Homebrew の導入方法と運用方針だけを持つ。何を入れるか、宣言外を消すかはホストが決める。
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    mutableTaps = false;
    user = username;

    extraEnv = {
      # Homebrew はmacOSアプリと、上流がTapを公式配布するCLIに限定する。
      HOMEBREW_FORBIDDEN_TAPS = "homebrew/core";
      HOMEBREW_NO_ANALYTICS = "1";
    };
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      # 大きなアプリの取得中も止まって見えないよう、段階ごとの進捗を表示する。
      extraFlags = [ "--verbose" ];
    };
  };
}
