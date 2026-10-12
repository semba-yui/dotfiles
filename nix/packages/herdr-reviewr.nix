{
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenvNoCC,
}:

# herdr が `plugin link` で読むプラグインのディレクトリを $out に組み立てる。上流の [[build]] は
# リリースのバイナリを bin/ へダウンロードするだけなので、同じバイナリを fetchurl で固定して置き換える。
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "herdr-reviewr";
  version = "0.46.0";

  src = fetchFromGitHub {
    owner = "persiyanov";
    repo = "herdr-reviewr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KJNzp6e7Uy3E1teheD/dMpB5Zqw7dqxEGnjJqvJgYaE=";
  };

  binaryArchive = fetchurl {
    url = "https://github.com/persiyanov/herdr-reviewr/releases/download/v${finalAttrs.version}/herdr-reviewr-aarch64-apple-darwin.tar.gz";
    hash = "sha256-LaufeqLYdhh0peRgvjdVurQ8zs29TQ3AethcPjCicxY=";
  };

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 herdr-plugin.toml "$out/herdr-plugin.toml"
    mkdir -p "$out/bin"
    tar -xzf "$binaryArchive" -C "$out/bin" herdr-reviewr

    runHook postInstall
  '';

  meta = {
    description = "herdr plugin to review agent-written diffs and send line comments back";
    homepage = "https://github.com/persiyanov/herdr-reviewr";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
