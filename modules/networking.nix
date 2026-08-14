{
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;
  services.timesyncd.enable = true;
}
