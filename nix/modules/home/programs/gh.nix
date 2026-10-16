{ pkgs, ... }:
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
      pkgs.gh-stack
    ];
  };
}
