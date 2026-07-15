{ ... }:
{
  programs.gh = {
    enable = true;
    # Git の認証は GCM に一本化し、未ログインの gh が URL 単位で優先されることを防ぐ。
    gitCredentialHelper.enable = false;
  };
}
