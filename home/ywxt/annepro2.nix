{ pkgs, ... }:

{
  packages = [ (pkgs.callPackage ../../pkgs/obinskit.nix { }) ];
}
