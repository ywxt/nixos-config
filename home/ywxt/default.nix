{ inputs, pkgs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
    ./input-method.nix
    ./packages.nix
    ./mime.nix
    ./niri.nix
    ./noctalia.nix
    ./qt.nix
    ./shell.nix
    ./xdg.nix
  ];

  home = {
    username = "ywxt";
    homeDirectory = "/home/ywxt";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
  xdg.enable = true;

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Tela-circle";
      package = pkgs.tela-circle-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };
    font = {
      name = "Adwaita Sans";
      package = pkgs.adwaita-fonts;
      size = 11;
    };
    gtk3.extraCss = ''
      @import url("noctalia.css");
    '';
    gtk4.extraCss = ''
      @import url("noctalia.css");
    '';
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };
}
