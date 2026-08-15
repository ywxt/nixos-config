{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/hardware-amd.nix
    ../../modules/networking.nix
    ../../modules/audio.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix
    ../../modules/development.nix
  ];

  networking.hostName = "ywxt-ws";
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.ywxt = {
    isNormalUser = true;
    description = "ywxt";
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "audio"
    ];
  };

  programs.fish.enable = true;
  security.sudo.wheelNeedsPassword = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "ywxt" ];
      substituters = [
        "https://mirrors.cernet.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";
}
