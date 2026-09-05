{ pkgs, ... }:

{
  packages = with pkgs; [
    # Thunar uses these helpers to launch its preferred applications.
    xfce4-exo
    xfce4-settings
    (thunar.override {
      thunarPlugins = [
        thunar-archive-plugin
        thunar-volman
      ];
    })
  ];

  xdg.config.files."xfce4/helpers.rc" = {
    clobber = true;
    text = ''
      [Helpers]
      TerminalEmulator=kitty
    '';
  };
}
