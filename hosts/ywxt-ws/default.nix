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
  services.teamviewer.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # Allow the active desktop user to configure Anne Pro 2 keyboards over USB.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8008", GROUP:="users", MODE:="0660"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8008", GROUP:="users", MODE:="0660"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8009", GROUP:="users", MODE:="0660"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8009", GROUP:="users", MODE:="0660"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a292", GROUP:="users", MODE:="0660"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a292", GROUP:="users", MODE:="0660"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a293", GROUP:="users", MODE:="0660"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a293", GROUP:="users", MODE:="0660"
  '';

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
