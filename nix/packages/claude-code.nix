{
  fetchurl,
  lib,
  makeBinaryWrapper,
  procps,
  ripgrep,
  stdenvNoCC,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:

let
  release = builtins.fromJSON (builtins.readFile ./claude-code-release.json);
  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  artifact =
    if builtins.hasAttr platformKey release.platforms then
      release.platforms.${platformKey}
    else
      throw "claude-code: unsupported platform ${stdenvNoCC.hostPlatform.system}";
in
stdenvNoCC.mkDerivation {
  pname = "claude-code";
  inherit (release) version;

  # 公式の raw manifest と署名済み実行ファイルを一体の契約として固定するため、
  # 配布形式を内部実装に含む nixpkgs の claude-code derivation は再利用しない。
  src = fetchurl {
    url = "https://downloads.claude.ai/claude-code-releases/${release.version}/${platformKey}/${artifact.binary}";
    sha256 = artifact.checksum;
  };

  dontUnpack = true;
  dontBuild = true;
  __noChroot = stdenvNoCC.hostPlatform.isDarwin;

  # Developer ID 署名を壊した Mach-O は macOS が起動時に拒否するため、strip させない。
  dontStrip = true;

  nativeBuildInputs = [ makeBinaryWrapper ];

  strictDeps = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/claude"

    wrapProgram "$out/bin/claude" \
      --set DISABLE_AUTOUPDATER 1 \
      --set-default FORCE_AUTOUPDATE_PLUGINS 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --prefix PATH : ${
        lib.makeBinPath [
          procps
          ripgrep
        ]
      }

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    changelog = "https://github.com/anthropics/claude-code/blob/v${release.version}/CHANGELOG.md";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
