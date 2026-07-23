{
  programs.lazygit = {
    enable = true;

    settings = {
      gui = {
        language = "ja";
        nerdFontsVersion = "3";
      };

      git.pagers = [
        {
          name = "delta";
          pager = "delta --paging=never";
        }
        {
          name = "builtin";
        }
      ];

      update.method = "never";
    };
  };
}
