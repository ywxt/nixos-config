{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mesa-demos
    nvme-cli
    pciutils
    radeontop
    usbutils
    vulkan-tools
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva
      libvdpau-va-gl
    ];
  };
}
