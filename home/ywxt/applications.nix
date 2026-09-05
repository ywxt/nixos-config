{ pkgs, ... }:

{
  packages = with pkgs; [
    # Command-line applications
    fastfetch
    typst
    neovim

    # Command-line archive tools
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
