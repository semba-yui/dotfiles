{
  fetchurl,
  installShellFiles,
  lib,
  stdenvNoCC,
  versionCheckHook,
}:

let
  release = builtins.fromJSON (builtins.readFile ./codex-release.json);
  system = stdenvNoCC.hostPlatform.system;
  artifact =
    if builtins.hasAttr system release.artifacts then
      release.artifacts.${system}
    else
      throw "codex: unsupported platform ${system}";
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit (release) version;

  # nixpkgs の codex は Rust ソースからビルドするため、上流リリース当日には追随できない。
  # 公式インストーラと同じ署名済み配布物を取り込み、リリース直後から同じ版を使えるようにする。
  src = fetchurl {
    inherit (artifact) hash url;
  };

  # 配布物は単一の親ディレクトリを持たず bin/ などを直接含むため、展開先を明示する。
  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  # Developer ID 署名を壊した Mach-O は macOS が起動時に SIGKILL するため、strip させない。
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    # codex は自身の実行ファイルの実体パスを基点に codex-path/ と codex-resources/ を探すため、
    # 配布物のディレクトリ構造を崩さず配置し、PATH へは symlink だけを置く。
    mkdir -p "$out/lib/codex" "$out/bin"
    cp -R bin codex-package.json codex-path codex-resources "$out/lib/codex/"
    ln -s "$out/lib/codex/bin/codex" "$out/bin/codex"
    ln -s "$out/lib/codex/bin/codex-code-mode-host" "$out/bin/codex-code-mode-host"

    runHook postInstall
  '';

  postInstall = ''
    HOME="$TMPDIR" installShellCompletion --cmd codex \
      --bash <(HOME="$TMPDIR" "$out/bin/codex" completion bash) \
      --fish <(HOME="$TMPDIR" "$out/bin/codex" completion fish) \
      --zsh <(HOME="$TMPDIR" "$out/bin/codex" completion zsh)
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${release.version}";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames release.artifacts;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
