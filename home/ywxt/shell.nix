{
  config,
  lib,
  pkgs,
  ...
}:

{
  packages = with pkgs; [
    bat
    bottom
    curl
    direnv
    nix-direnv
    starship
    wget
  ];

  xdg.config.files = {
    "fish/config.fish" = {
      clobber = true;
      source = ./fish/config.fish;
    };
    "direnv/direnvrc" = {
      clobber = true;
      source = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";
    };
    "fish/conf.d/00-environment.fish" = {
      clobber = true;
      text = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: value:
          "set --global --export ${lib.escapeShellArg name} ${lib.escapeShellArg (toString value)}"
        ) config.environment.sessionVariables
      );
    };
    "fish/conf.d/05-path.fish" = {
      clobber = true;
      text = ''
        fish_add_path --global $HOME/.local/bin
      '';
    };
  };
}
