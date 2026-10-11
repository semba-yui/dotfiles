{ inputs }:

# nix/hosts/<LocalHostName>/ を置くだけで登録されるようにし、ホスト追加時の編集箇所を減らす。
builtins.mapAttrs (hostname: _: import ./${hostname} { inherit hostname inputs; }) (
  inputs.nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.)
)
