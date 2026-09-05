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
    # Use FFmpeg's full feature set for broad audio/video codec support.
    (vlc.override { ffmpeg_7 = ffmpeg_7-full; })
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
