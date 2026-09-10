{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/hardware-intel.nix
    ../../modules/networking.nix
    ../../modules/audio.nix
    ../../modules/desktop.nix
    ../../modules/development.nix
    ../../modules/input-method.nix
    ../../modules/space-nav.nix
    ../../modules/monitor.nix
    ../../modules/nix-settings.nix
    ../../modules/ohos.nix
    ../../modules/sops.nix
    ../../modules/univpn.nix
    ../../home/ywxt/opencode.nix
  ];

  networking.hostName = "ywxt-work";
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  desktop.monitors = [
    {
      name = "DP-1";
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
