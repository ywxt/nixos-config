{ pkgs, ... }:

{
  packages = [
    pkgs.rustbot-cli
    pkgs.nodejs
  ];
}
