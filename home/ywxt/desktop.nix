{ pkgs, ... }:

{
  imports = [
    ./gaming.nix
    ./gtk.nix
    ./input-method.nix
    ./kitty.nix
    ./mime.nix
    ./niri.nix
    ./noctalia.nix
    ./qt.nix
    ./thunar.nix
  ];

  packages = with pkgs; [
    firefox
    imv
    nwg-look
    obs-studio
    telegram-desktop
    vlc
    vscode
    kdePackages.ark
  ];

  environment.sessionVariables = {
    BROWSER = "firefox";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    GLFW_IM_MODULE = "ibus";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_STYLE_OVERRIDE = "kvantum";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_IM_MODULE = "fcitx";
    TERMINAL = "kitty";
    XCURSOR_SIZE = "24";
    XCURSOR_THEME = "Adwaita";
    XMODIFIERS = "@im=fcitx";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  xdg.config.files = {
    "fish/conf.d/20-desktop-session.fish" = {
      clobber = true;
      text = ''
        if status is-login
          if uwsm check may-start
            if uwsm select
              exec uwsm start default
            end
          end
        end
      '';
    };
    "git/credentials.conf".text = ''
      [credential]
        helper = cache --timeout 2592000
        helper = oauth
    '';
  };
}
