{pkgs, ... }:

{
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
    firewall.checkReversePath = "loose";
    firewall.trustedInterfaces = [ "Mihomo" ];
  };

  programs.clash-verge = {
    enable = true;
    package = pkgs.clash-verge-rev;
    autoStart = true;
    serviceMode = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.timesyncd.enable = true;

}
