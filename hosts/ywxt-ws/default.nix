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
    ../../modules/monitor.nix
    ../../modules/annepro2.nix
  ];

  networking.hostName = "ywxt-ws";
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  desktop.monitors = [
    {
      name = "DP-1";
      mode = "3840x2160";
      scale = 1.6667;
      transform = "normal";
      position = {
        x = 0;
        y = 0;
      };
    }
  ];

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
  services.teamviewer.enable = true;
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
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
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
