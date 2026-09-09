{ pkgs, ... }:

{
  files = {
    ".ssh/config" = {
      type = "copy";
      permissions = "0600";
      text = ''
        Include config.d/*
      '';
    };

    ".ssh/config.d/univpn.conf" = {
      type = "copy";
      permissions = "0600";
      text = ''
        Host 192.168.41.50
          User wheel
          ProxyCommand ${pkgs.netcat-openbsd}/bin/nc -x 127.0.0.1:11080 -X 5 %h %p
      '';
    };
  };
}
