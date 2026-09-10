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
        Match exec "${pkgs.gnugrep}/bin/grep -Fxq -- %h /run/secrets/univpn/ssh-host"
          User wheel
          ProxyCommand ${pkgs.netcat-openbsd}/bin/nc -x 127.0.0.1:11080 -X 5 %h %p
      '';
    };
  };
}
