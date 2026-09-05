{ pkgs, ... }:

{
  services.udev.packages = [ pkgs.annepro2-udev-rules ];
}
