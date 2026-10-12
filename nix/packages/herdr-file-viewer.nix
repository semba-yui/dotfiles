{
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenvNoCC,
}:

# herdr が `plugin link` で読むプラグインのディレクトリを $out に組み立てる。上流の [[build]] は
# リリースのバイナリを target/release/ へダウンロードするだけなので、同じバイナリを fetchurl で固定して置き換える。
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "herdr-file-viewer";
  version = "1.18.0";

  src = fetchFromGitHub {
    owner = "smarzban";
    repo = "herdr-file-viewer";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rG15Aq6QVPqE5ndlQwUjMUVlbtdTKKSHdzpOPskd+ss=";
  };

  binary = fetchurl {
    url = "https://github.com/smarzban/herdr-file-viewer/releases/download/v${finalAttrs.version}/herdr-file-viewer-aarch64-apple-darwin";
    hash = "sha256-puDZUpybL47rLjg47SwqCVYezzf1qhr3YRXH59fmVZ0=";
  };

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 herdr-plugin.toml "$out/herdr-plugin.toml"
    cp -R scripts skills "$out/"
    install -Dm755 "$binary" "$out/target/release/herdr-file-viewer"

    runHook postInstall
  '';

  meta = {
    description = "Git-aware, read-only file viewer for herdr";
    homepage = "https://github.com/smarzban/herdr-file-viewer";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
