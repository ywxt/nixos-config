{ pkgs, ... }:

{
  packages = with pkgs; [
    ark
    firefox
    imv
    jetbrains.rider
    nwg-look
    obs-studio
    telegram-desktop
    (thunar.override {
      thunarPlugins = [
        thunar-archive-plugin
        thunar-volman
      ];
    })
    vlc
    vscode
  ];
}
