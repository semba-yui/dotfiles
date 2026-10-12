{
  hostname,
  inputs,
  lib,
  ...
}:

let
  # ssh-keygen で作る鍵と形式が違うため、ファイル名に作り方を含めて区別する。中身は秘密を含まない参照用のスタブ。
  keyFile = account: "~/.ssh/github-commit-signing-${account}-${lib.toLower hostname}-secure-enclave";

  identity = account: {
    keyFile = keyFile account;
    label = "github-commit-signing-${account}";
    # 秘密鍵は Secure Enclave から持ち出せないため、AI エージェントの commit など無人の署名を止めないことを優先する。
    protection = "none";
    # GitHub アカウントが増えても登録は端末とアカウントの組で 1 度きりのため、強い権限を gh に持たせず手作業で登録する。
    github.autoAdd = false;
  };
in
{
  imports = [ inputs.nix-secure-enclave-key.homeManagerModules.default ];

  dotfiles.git.signingKeyFile = keyFile;

  programs.nix-secure-enclave-key = {
    enable = true;

    identities = {
      lc-semba-ryuichiro = identity "lc-semba-ryuichiro";
      semba-yui = identity "semba-yui";
    };

    # どの include にも当てはまらないリポジトリでは、git.nix の既定の名義と同じアカウントの鍵で署名する。
    signingIdentity = "lc-semba-ryuichiro";
    signByDefault = true;
  };
}
