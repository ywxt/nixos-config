{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.bashInteractive ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  programs.nix-ld.enable = true;
}
