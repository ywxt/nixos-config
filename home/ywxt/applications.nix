{ pkgs, ... }:

{
  packages = with pkgs; [
    # Desktop applications
    fastfetch
    firefox
    imv
    nwg-look
    obs-studio
    telegram-desktop
    vlc
    vscode
    typst
    neovim

    # Graphical and command-line archive tools
    kdePackages.ark
    gnutar
    _7zz
    unzip
    zip

    # Development tools
    clang
    cmake
    gcc
    gnumake
    jdk21

    nixfmt
    nixfmt-tree
    pkg-config
    python3

  ];
}
