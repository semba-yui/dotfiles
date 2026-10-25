{
  fetchurl,
  installShellFiles,
  lib,
  stdenvNoCC,
}:

let
  version = "2026.10.17";

  # tarball に補完がないため、同じタグのリポジトリから取る。
  fetchCompletion =
    name: hash:
    fetchurl {
      url = "https://raw.githubusercontent.com/jdx/mise/v${version}/completions/${name}";
      inherit hash;
    };
  bashCompletion = fetchCompletion "mise.bash" "sha256-su8z3uvo/9ngnDlUdPKrC+aufQRXOZ0/eQerEtBwwz0=";
  fishCompletion = fetchCompletion "mise.fish" "sha256-slrzjbmj9RWe3CM38XkOeStjlw5SpaYJtTeP/k4tYfg=";
  zshCompletion = fetchCompletion "_mise" "sha256-rXE8PlGY9linJezVP2HVh0iDGVhpRNhExZEUhDVHew8=";
in
# 公式のビルド済みバイナリを包む。版を変えるときは、minisign で SHASUMS256.txt の署名を確かめ
# （公開鍵は jdx/mise の minisign.pub）、gh attestation verify --repo jdx/mise で tarball の出所を
# 確かめてからハッシュを書き換える。
stdenvNoCC.mkDerivation {
  pname = "mise";
  inherit version;

  src = fetchurl {
    url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-macos-arm64.tar.xz";
    hash = "sha256-jrR25W9oCpNHzik0Z2jYQXT2MaN+Axd1ni4qVlgwyl0=";
  };

  nativeBuildInputs = [ installShellFiles ];

  dontBuild = true;
  # Apple の公証済み署名を壊さないよう、バイナリには手を加えない。
  dontStrip = true;

  # share/fish/vendor_conf.d の自動有効化は入れない。Home Manager の programs.mise と二重に有効化される。
  installPhase = ''
    runHook preInstall

    install -Dm755 bin/mise "$out/bin/mise"
    installManPage man/man1/mise.1
    installShellCompletion --cmd mise \
      --bash ${bashCompletion} \
      --fish ${fishCompletion} \
      --zsh ${zshCompletion}

    # Nix のストアは書き換えられないため、nixpkgs の mise と同じく self-update を無効にする。
    install -Dm644 /dev/null "$out/lib/mise/.disable-self-update"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    version_output="$(HOME="$TMPDIR" "$out/bin/mise" --version)"
    if [[ $version_output != ${version}* ]]; then
      echo "mise: expected version ${version}, got: $version_output" >&2
      exit 1
    fi

    runHook postInstallCheck
  '';

  meta = {
    description = "Polyglot runtime manager";
    homepage = "https://mise.jdx.dev";
    license = lib.licenses.mit;
    mainProgram = "mise";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
