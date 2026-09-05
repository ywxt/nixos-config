{ pkgs, ... }:

let
  annepro2UdevRules = pkgs.callPackage ../pkgs/annepro2-udev-rules.nix { };
in
{
  services.udev.packages = [ annepro2UdevRules ];
}
