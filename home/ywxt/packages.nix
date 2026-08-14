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
    flclash
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
    typst
    unzip
    uv
    uwsm
    vlc
    vscode
    wget
    wl-clipboard
    xwayland-satellite
  ];

  xdg.configFile."autostart/flclash.desktop".source =
    "${pkgs.flclash}/share/applications/flclash.desktop";
}
