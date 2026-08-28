{ pkgs, ... }:

{
  # pkgs.alloyは5系を指すため、バージョンを明示したalloy6を使う。
  # Homebrew caskはGatekeeper検査に失敗し、formulaは許可していないhomebrew/coreにあるため、
  # JAR・Javaランタイム・起動コマンドをNixで一体管理する。
  home.packages = [ pkgs.alloy6 ];
}
