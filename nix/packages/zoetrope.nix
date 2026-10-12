{
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenvNoCC,
}:

# `zoe` 本体と、それを呼ぶ herdr プラグイン（share/herdr-plugin）を同じ版で配る。上流の [[build]] は
# zoe が PATH にない場合に brew か cargo で入れるだけなので、`plugin link` で省かれても困らない。
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "zoetrope";
  version = "0.2.0";

  src = fetchurl {
    url = "https://github.com/furkankly/zoetrope/releases/download/v${finalAttrs.version}/zoetrope-${finalAttrs.version}-aarch64-apple-darwin.tar.gz";
    hash = "sha256-S0f3tECoMUoYc1qJZKUTfqPqfFO95cygMc+NGkwV5BM=";
  };

  herdrPluginSource = fetchFromGitHub {
    owner = "furkankly";
    repo = "zoetrope";
    tag = "v${finalAttrs.version}";
    hash = "sha256-jfzbgtZNIbDyHpXqP5QxF9o71zdYKEbY862NIaPHujo=";
  };

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 zoe "$out/bin/zoe"
    mkdir -p "$out/share"
    cp -R "$herdrPluginSource/herdr-plugin" "$out/share/herdr-plugin"

    runHook postInstall
  '';

  meta = {
    description = "Watch a Claude Code or Codex session as a live flow graph";
    homepage = "https://github.com/furkankly/zoetrope";
    license = lib.licenses.mit;
    mainProgram = "zoe";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
