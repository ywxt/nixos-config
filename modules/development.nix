{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    clang
    cmake
    gcc
    git
    git-lfs
    gnumake
    pkg-config
  ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  programs.nix-ld.enable = true;
}
