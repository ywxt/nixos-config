{ pkgs, ... }:

let
  gtkSettings = ''
    [Settings]
    gtk-theme-name=adw-gtk3
    gtk-icon-theme-name=Tela-circle
    gtk-font-name=Adwaita Sans 11
    gtk-cursor-theme-name=Adwaita
    gtk-cursor-theme-size=24
  '';
in
{
  packages = with pkgs; [
    adw-gtk3
    adwaita-fonts
    adwaita-icon-theme
    tela-circle-icon-theme
  ];

  xdg.config.files = {
    "gtk-3.0/settings.ini" = {
      clobber = true;
      text = gtkSettings;
    };
    "gtk-4.0/settings.ini" = {
      clobber = true;
      text = gtkSettings;
    };
    "gtk-3.0/gtk.css" = {
      clobber = true;
      text = ''@import url("noctalia.css");'';
    };
    "gtk-4.0/gtk.css" = {
      clobber = true;
      text = ''@import url("noctalia.css");'';
    };
  };

  files = {
    ".icons/Adwaita" = {
      clobber = true;
      source = "${pkgs.adwaita-icon-theme}/share/icons/Adwaita";
    };
    ".icons/default/index.theme" = {
      clobber = true;
      text = ''
        [Icon Theme]
        Inherits=Adwaita
      '';
    };
  };
}
