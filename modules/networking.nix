{
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
    firewall.checkReversePath = false;
    firewall.trustedInterfaces = [ "tun0" "utun+"];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;
  services.timesyncd.enable = true;
}
