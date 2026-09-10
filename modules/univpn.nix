{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  imageName = "localhost/univpn-proxy:2.3-microsocks";
  buildContext = ../docker/univpn;
  containerService = "docker-univpn";

  editUniVpnSecrets = pkgs.writeShellApplication {
    name = "univpn-secrets";
    text = ''
      config_directory="''${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"
      secret_file="$config_directory/secrets/ywxt-work-univpn.yaml"

      if [[ ! -f $secret_file ]]; then
        echo "univpn-secrets: file not found: $secret_file" >&2
        echo "Set NIXOS_CONFIG_DIR if the repository is stored elsewhere." >&2
        exit 1
      fi

      export SOPS_AGE_KEY_CMD="sudo ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key"
      exec ${pkgs.sops}/bin/sops "$secret_file"
    '';
  };
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  environment.systemPackages = [
    pkgs.age
    pkgs.sops
    pkgs.ssh-to-age
    editUniVpnSecrets
  ];

  sops = {
    defaultSopsFile = ../secrets/ywxt-work-univpn.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "univpn/gateway" = { };
      "univpn/port" = { };
      "univpn/username" = { };
      "univpn/password" = { };
      "univpn/ssh-host".mode = "0444";
    };

    templates."univpn.env" = {
      mode = "0400";
      content = ''
        VPN_GATEWAY=${config.sops.placeholder."univpn/gateway"}
        VPN_PORT=${config.sops.placeholder."univpn/port"}
        VPN_USERNAME=${config.sops.placeholder."univpn/username"}
        VPN_PASSWORD=${config.sops.placeholder."univpn/password"}
        USER=root
        TZ=Asia/Shanghai
        TUN_DEVICE=cnem_vnic
        PROXY_DNS=1.1.1.1
      '';
    };
  };

  systemd.services.univpn-image = {
    description = "Build the local headless UniVPN SOCKS image";
    wantedBy = [ "multi-user.target" ];
    before = [ "${containerService}.service" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    after = [ "docker.service" "network-online.target" ];
    path = [ pkgs.docker ];
    script = ''
      docker build --pull=false --tag ${lib.escapeShellArg imageName} ${lib.escapeShellArg (toString buildContext)}
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.univpn = {
      image = imageName;
      pull = "never";
      environmentFiles = [ config.sops.templates."univpn.env".path ];
      ports = [ "127.0.0.1:11080:1080/tcp" ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun:/dev/net/tun"
      ];
    };
  };

  systemd.services.${containerService} = {
    requires = [ "univpn-image.service" ];
    after = [ "univpn-image.service" "sops-install-secrets.service" ];
    serviceConfig.Restart = lib.mkForce "always";
  };
}
