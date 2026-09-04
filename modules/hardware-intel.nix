{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    mesa-demos
    nvme-cli
    pciutils
    usbutils
    vulkan-tools
  ];

  services.thermald.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };
}
