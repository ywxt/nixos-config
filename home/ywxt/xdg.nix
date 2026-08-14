{pkgs, ...}:

{
  xdg = {
    enable = true;
    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
	      pkgs.xdg-desktop-portal-gnome
      ];
      config = {
        common.default = [ "gtk" ];
      };
    };
  };
}
