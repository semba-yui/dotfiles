{ pkgs, ... }:
let
  ghStackVersion = "0.2.0";

  # nixpkgs-unstable はまだ 0.1.1 で、flake.nix の gh-stack 入力が取り込む skill が前提とする
  # worktree 間のスタック共有を持たない。上流 release の定義を当てて先回りする。
  # チャンネルが 0.2.0 を拾ったらこの let ごと削除する。
  gh-stack = pkgs.gh-stack.overrideAttrs (prev: {
    version = ghStackVersion;
    src = pkgs.fetchFromGitHub {
      owner = "github";
      repo = "gh-stack";
      tag = "v${ghStackVersion}";
      hash = "sha256-70H1kOdvklTeB8OVFg7g6xQ4rn0gqv+zU7yjDYPd3vo=";
    };
    vendorHash = "sha256-Otstml5TSTJeYsP9o94aUperP1MgT2axa/wqALEnXYk=";
    # goModules は nativeBuildInputs の installAgentSkills を引き継ぐが pname を持たないため、
    # vendorHash が変わって再ビルドされると installPhase で落ちる。依存取得では skill は不要。
    # modifyview の insert 系テストは git.BranchExists をカレントディレクトリで呼ぶ。
    # 上流 CI は checkout 上で走るが、Nix のソースは tarball 展開で .git を持たないため失敗する。
    preCheck = (prev.preCheck or "") + ''
      git init -q
    '';
    passthru = prev.passthru // {
      overrideModAttrs = pkgs.lib.composeExtensions prev.passthru.overrideModAttrs (
        _: _: { dontInstallAgentSkills = true; }
      );
    };
  });
in
{
  programs.gh = {
    enable = true;
    # Git の認証は GCM に一本化し、未ログインの gh が URL 単位で優先されることを防ぐ。
    gitCredentialHelper.enable = false;

    # Home Manager は ~/.local/share/gh/extensions を store への symlink で置き換えるため、
    # 以降 `gh extension install` / `upgrade` は書き込めず、追加はこのリストでしか行えない。
    extensions = [
      pkgs.gh-dash
      pkgs.gh-poi
      gh-stack
    ];
  };
}
