{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ark
    bat
    bottom
    chezmoi
    cliphist
    curl
    firefox
    git-credential-oauth
    imv
    jdk21
    jetbrains.rider
    kitty
    neovim
    nwg-look
    obs-studio
    python3
    rustup
    telegram-desktop
    (thunar.override {
      thunarPlugins = [
        thunar-archive-plugin
        thunar-volman
      ];
    })
    typst
    unzip
    uv
    vlc
    vscode
    wget
    wl-clipboard
    xwayland-satellite
  ];
}
