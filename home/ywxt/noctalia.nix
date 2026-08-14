{ ... }:

{
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    validateConfig = true;

    settings = {
      accessibility.ui_scale = 1.0;

      shell = {
        font_family = "sans-serif";
        time_format = "{:%H:%M}";
        date_format = "%A, %x";
        telemetry_enabled = false;
        settings_show_advanced = true;
        polkit_agent = true;
        clipboard_enabled = true;
        clipboard_history_max_entries = 100;
        launcher = {
          categories = true;
          show_icons = true;
          sort_by_usage = true;
        };
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Noctalia";
        templates = {
          enable_builtin_templates = true;
          builtin_ids = [ "gtk3" "gtk4" "qt" ];
        };
      };

      wallpaper = {
        enabled = true;
        directory = "~/Pictures/Wallpapers";
        fill_mode = "crop";
      };

      lockscreen = {
        enabled = true;
        blurred_desktop = true;
        blur_intensity = 0.5;
        tint_intensity = 0.3;
      };

      notification = {
        enable_daemon = true;
        show_actions = true;
      };

      idle = {
        pre_action_fade_seconds = 2.0;
        behavior = {
          lock = {
            timeout = 300;
            action = "lock";
            enabled = true;
          };
          "screen-off" = {
            timeout = 330;
            action = "screen_off";
            enabled = true;
          };
        };
      };

      bar.main = {
        position = "top";
        thickness = 34;
        background_opacity = 1.0;
        radius = 12;
        margin_edge = 5;
        margin_ends = 5;
        reserve_space = true;
        start = [ "launcher" "workspaces" ];
        center = [ "media" ];
        end = [
          "tray"
          "notifications"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "clock"
          "control-center"
          "session"
        ];
      };

      location = {
        auto_locate = false;
        address = "Shanghai";
      };
    };
  };
}
