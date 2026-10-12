{
  fetchurl,
  lib,
  makeWrapper,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "tode";
  version = "0.4.2";

  # 公式インストーラー（https://tode.sh/install）が取得し、sha256 を照合しているものと同じ tar.gz。
  src = fetchurl {
    url = "https://tode-releases.zenbu-labs.workers.dev/dl/stable/v${finalAttrs.version}/tode-darwin-arm64.tar.gz";
    hash = "sha256-BYoP8YZWyMk9IG55I31+SoaguUrwuueQ5VtnCbG/bxI=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  # 同梱の Electron.app はコード署名済みで、strip やパスの書き換えを入れると起動できなくなる。
  dontFixup = true;

  # 起動スクリプトは既定で ~/.local/lib/tode を本体の場所として参照するため、store を指させる。
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib"
    cp -R . "$out/lib/tode"
    makeWrapper "$out/lib/tode/bin/tode" "$out/bin/tode" \
      --set TODE_INSTALL_ROOT "$out/lib/tode"

    runHook postInstall
  '';

  meta = {
    description = "VS Code in the terminal";
    homepage = "https://github.com/zenbu-labs/terminal-code";
    license = lib.licenses.mit;
    mainProgram = "tode";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
