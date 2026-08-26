{
  fetchurl,
  lib,
  stdenvNoCC,
}:

let
  release = builtins.fromJSON (builtins.readFile ./teamwork-graph-cli-release.json);
  system = stdenvNoCC.hostPlatform.system;
  artifact =
    if builtins.hasAttr system release.artifacts then
      release.artifacts.${system}
    else
      throw "teamwork-graph-cli: unsupported platform ${system}";
in
stdenvNoCC.mkDerivation {
  pname = "teamwork-graph-cli";
  inherit (release) version;

  src = fetchurl {
    inherit (artifact) hash url;
  };

  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/twg"

    runHook postInstall
  '';

  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck

    version_output="$($out/bin/twg --version)"
    if [[ $version_output != "${release.version}" ]]; then
      echo "teamwork-graph-cli: expected version ${release.version}, got: $version_output" >&2
      exit 1
    fi

    runHook postInstallCheck
  '';

  meta = {
    description = "Command-line interface for Atlassian Teamwork Graph";
    homepage = "https://github.com/atlassian/twg-cli";
    license = lib.licenses.unfree;
    mainProgram = "twg";
    platforms = builtins.attrNames release.artifacts;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
