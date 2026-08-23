{ config, lib, ... }:

let
  variables = {
    BROWSER = "firefox";
    EDITOR = "nvim";
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
    XDG_CACHE_HOME = "${config.directory}/.cache";
    XDG_CONFIG_HOME = "${config.directory}/.config";
    XDG_DATA_HOME = "${config.directory}/.local/share";
    XDG_STATE_HOME = "${config.directory}/.local/state";
    XMODIFIERS = "@im=fcitx";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
  environmentD = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "${name}=${value}") variables
  );
in
{
  environment.sessionVariables = variables;
  xdg.config.files."environment.d/10-home.conf" = {
    clobber = true;
    text = environmentD + "\n";
  };

  xdg = {
    cache.directory = "${config.directory}/.cache";
    config.directory = "${config.directory}/.config";
    data.directory = "${config.directory}/.local/share";
    state.directory = "${config.directory}/.local/state";
  };
}
