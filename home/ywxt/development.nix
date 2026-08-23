{ pkgs, ... }:

{
  packages = with pkgs; [
    clang
    cmake
    gcc
    gnumake
    jdk21
    neovim
    nixfmt
    nixfmt-tree
    pkg-config
    python3
    rustup
    typst
    uv
  ];
}
