{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.bashInteractive
    pkgs.perf
  ];

  # Allow unprivileged users to run perf on their own processes
  boot.kernel.sysctl."kernel.perf_event_paranoid" = 1;

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
