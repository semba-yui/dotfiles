{
  claude-code,
  lib,
}:

# nixpkgs の claude-code は上流リリースから数日遅れて追随するため、公式 manifest を
# release lock として取り込み、derivation 本体だけ nixpkgs のものを再利用する。
# manifest は上流の JSON をそのまま保存する。加工しないことで、上流との差分を
# `curl | diff` だけで確認できる状態を保つ。
claude-code.override { manifest = lib.importJSON ./claude-code-release.json; }
