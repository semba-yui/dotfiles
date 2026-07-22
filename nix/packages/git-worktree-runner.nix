{
  git,
  lib,
  makeWrapper,
  src,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "git-worktree-runner";
  # flake update と自動で同期させるため、上流のバージョン番号ではなく rev を使う。
  version = src.shortRev or "unknown";

  inherit src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  # bin/git-gtr は自身の位置を基点に lib/ adapters/ templates/ を source する
  # bash スクリプト群のため、リポジトリ全体を share/ へ配置し GTR_DIR で明示する。
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/git-worktree-runner $out/bin
    cp -R adapters bin completions lib templates $out/share/git-worktree-runner/
    patchShebangs $out/share/git-worktree-runner

    # git は `git gtr` 実行時に PATH から git-gtr を探すため、wrapper 名は変えない。
    makeWrapper $out/share/git-worktree-runner/bin/git-gtr $out/bin/git-gtr \
      --set GTR_DIR $out/share/git-worktree-runner \
      --prefix PATH : ${lib.makeBinPath [ git ]}

    runHook postInstall
  '';

  meta = {
    description = "Git worktree manager with editor/AI integration (git gtr)";
    homepage = "https://github.com/coderabbitai/git-worktree-runner";
    license = lib.licenses.mit;
    mainProgram = "git-gtr";
  };
}
