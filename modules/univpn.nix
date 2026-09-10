{
  config,
  lib,
  pkgs,
  ...
}:

let
  imageName = "localhost/univpn-proxy:2.3-microsocks";
  # Isolate the Docker context from the Flake source path. Otherwise any
  # unrelated repository change gives this service a new ExecStart store path
  # and nixos-rebuild unnecessarily restarts the active VPN container.
  buildContext = builtins.path {
    path = ../docker/univpn;
    name = "univpn-docker-context";
  };
  containerService = "docker-univpn";
in
{
  # NixOS generates /etc/ssh/ssh_config without an ssh_config.d wildcard.
  # Add the runtime SOPS fragment through the module's supported hook so both
  # command-line OpenSSH and clients invoking it with the system config see it.
  programs.ssh.extraConfig = ''
    Include /run/secrets/rendered/univpn-ssh.conf
  '';

  sops = {
    defaultSopsFile = ../secrets/ywxt-work-univpn.yaml;
    secrets = {
      "univpn/gateway" = { };
      "univpn/port" = { };
      "univpn/username" = { };
      "univpn/password" = { };
      "univpn/ssh-host" = { };
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

    templates."univpn-ssh.conf" = {
      mode = "0444";
      content = ''
        Host univpn-work
          HostName ${config.sops.placeholder."univpn/ssh-host"}
          User wheel
          ProxyCommand ${pkgs.netcat-openbsd}/bin/nc -x 127.0.0.1:11080 -X 5 %h %p
      '';
    };
  };

  systemd.services.univpn-image = {
    description = "Build the local headless UniVPN SOCKS image";
    wantedBy = [ "multi-user.target" ];
    before = [ "${containerService}.service" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    after = [
      "docker.service"
      "network-online.target"
    ];
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
    after = [
      "univpn-image.service"
      "sops-install-secrets.service"
    ];
    serviceConfig.Restart = lib.mkForce "always";
  };
}
