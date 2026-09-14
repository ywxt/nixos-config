{ pkgs, ... }:

{
  packages = [ pkgs.neovim ];
  xdg.config.files = {
    "nvim/init.lua" = {
      clobber = true;
      text = ''
        vim.opt.clipboard = "unnamedplus"
      '';
    };
  };
}
