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
    ../../modules/input-method.nix
    ../../modules/space-nav.nix
    ../../modules/monitor.nix
    ../../modules/nix-settings.nix
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
  security.sudo.wheelNeedsPassword = true;

  system.stateVersion = "26.05";
}
