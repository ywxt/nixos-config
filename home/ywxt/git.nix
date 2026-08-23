{ pkgs, ... }:

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
      credential.helper = [
        "cache --timeout 2592000"
        "oauth"
      ];
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };
  };
}
