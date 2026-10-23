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

  xdg.config.files = {
    "user-dirs.dirs" = {
      clobber = true;
      text = ''
        XDG_DESKTOP_DIR="$HOME/Desktop"
        XDG_DOCUMENTS_DIR="$HOME/Documents"
        XDG_DOWNLOAD_DIR="$HOME/Downloads"
        XDG_MUSIC_DIR="$HOME/Music"
        XDG_PICTURES_DIR="$HOME/Pictures"
        XDG_PUBLICSHARE_DIR="$HOME/Public"
        XDG_TEMPLATES_DIR="$HOME/Templates"
        XDG_VIDEOS_DIR="$HOME/Videos"
      '';
    };
    "xfce4/helpers.rc" = {
      clobber = true;
      text = ''
        [Helpers]
        TerminalEmulator=kitty
      '';
    };
  };
}
