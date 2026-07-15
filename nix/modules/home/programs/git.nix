{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "仙波 琉一朗 / Ryuichiro Semba";
        email = "86405487+lc-semba-ryuichiro@users.noreply.github.com";
      };

      init.defaultBranch = "main";

      color.ui = "auto";

      commit = {
        verbose = true;
        gpgsign = false;
      };

      pull.rebase = true;

      rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
      };

      merge.conflictStyle = "zdiff3";

      rerere = {
        enabled = true;
        autoupdate = true;
      };

      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };

      diff = {
        renames = true;
        algorithm = "histogram";
      };

      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      column.ui = "auto";

      core = {
        editor = "nvim";
        excludesFile = "~/.config/git/ignore";
      };

      url."https://github.com/".insteadOf = [
        "git@github.com:"
        "ssh://git@github.com/"
      ];

      ghq.root = "~/ghq";

      gtr.ai.default = "claude";
      gtr.editor.default = "zed";
    };
  };
}
