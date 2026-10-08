{ pkgs, ... }:

{
  /*
    CLI tools only: nothing here may depend on a graphical environment.
    GUI applications belong in desktop.nix instead.
  */
  packages = with pkgs; [
    # Command-line applications
    fastfetch
    typst

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
