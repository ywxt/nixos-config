{ pkgs, ... }:

let
  ohosSdk = pkgs.callPackage ../pkgs/ohos-sdk.nix { };
in
{
  environment.systemPackages = [ ohosSdk ];
}
