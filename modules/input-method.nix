{ pkgs, ... }:

let
  fcitx5RimeHuma = pkgs.fcitx5-rime.override {
    rimeDataPkgs = [
      pkgs.rime-data
      pkgs.rime-huma
    ];
  };
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5RimeHuma
        fcitx5-gtk
        fcitx5-fluent
      ];
    };
  };
}
