{
  config,
  lib,
  pkgs,
  ...
}:

let
  gitConfig = pkgs.formats.gitIni { listsAsDuplicateKeys = true; };
in
{
  packages = with pkgs; [
    git
    git-lfs
    git-credential-oauth
  ];
  xdg.config.files."git/config" = {
    clobber = true;
    source = gitConfig.generate "git-config" {
      user = {
        name = "ywxt";
        email = "ywxtcwh@gmail.com";
      };
      include.path = "${config.xdg.config.directory}/git/credentials.conf";
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };
  };
  xdg.config.files."git/credentials.conf" = {
    clobber = true;
    text = lib.mkDefault ''
      [credential]
        helper = cache --timeout 2592000
        helper = oauth -device
    '';
  };
}
