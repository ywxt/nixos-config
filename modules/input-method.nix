{
  inputs,
  pkgs,
  ...
}:

let
  rimeHuma = pkgs.callPackage ../pkgs/rime-huma.nix {
    src = inputs.rime-huma;
    version = inputs.rime-huma.shortRev or "unstable";
  };

  fcitx5RimeHuma = pkgs.fcitx5-rime.override {
    rimeDataPkgs = [
      pkgs.rime-data
      rimeHuma
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
