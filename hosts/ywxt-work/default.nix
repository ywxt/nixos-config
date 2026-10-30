{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/hardware-intel.nix
    ../../modules/networking.nix
    ../../modules/audio.nix
    ../../modules/desktop.nix
    ../../modules/development.nix
    ../../modules/input-method.nix
    ../../modules/space-nav.nix
    ../../modules/monitor.nix
    ../../modules/nix-settings.nix
    ../../modules/ohos.nix
    ../../modules/sops.nix
    ../../modules/univpn.nix
    ../../modules/blue-agent.nix
  ];

  networking.hostName = "ywxt-work";
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  desktop.monitors = [
    {
      name = "DP-1";
    }
  ];

  users.users.ywxt = {
    isNormalUser = true;
    description = "ywxt";
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "audio"
    ];
  };

  programs.fish.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # BlueZone asset heartbeat agent — unprivileged port of the Windows
  # BlueZoneAssetManager agent. The GitCode token and the hardcoded
  # registration (asset code + employee id) live encrypted in
  # secrets/ywxt-work-blue-agent.yaml and are rendered by sops-nix to
  # /run/secrets/rendered/blue-agent.json (0400, owned by the
  # auto-detected agent user).
  services.blue-agent.enable = true;

  system.stateVersion = "26.05";
}
