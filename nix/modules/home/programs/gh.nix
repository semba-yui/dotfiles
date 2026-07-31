{ pkgs, ... }:
let
  ghStackVersion = "0.1.0";

  # nixpkgs-unstable はまだ 0.0.4 で、apm.yml が取り込む skill が前提とする
  # merge / trunk を持たない。master にマージ済みの定義を当てて先回りする。
  # チャンネルが 0.1.0 を拾ったらこの let ごと削除する。
  gh-stack = pkgs.gh-stack.overrideAttrs {
    version = ghStackVersion;
    src = pkgs.fetchFromGitHub {
      owner = "github";
      repo = "gh-stack";
      tag = "v${ghStackVersion}";
      hash = "sha256-48JkOeqbvHlCZ2u3LnwJymw55xMQWLTPJLDbV44clGI=";
    };
    vendorHash = "sha256-0Xtr/MOpX4u5GnbRdNxKPA0GpSzi8PIbVc9MmP05De4=";
    # 0.1.0 のテストは git を実行する。
    nativeCheckInputs = [ pkgs.gitMinimal ];
  };
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
