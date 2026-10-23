{
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.noctalia.hjemModules.default ];

  # Used by the session_locked hook below to pause media players on lock.
  packages = [ pkgs.playerctl ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      hooks.session_locked = [ "playerctl pause" ];

      backdrop = {
        enabled = true;
        blur_intensity = 0.5; # 0.0 = no blur, 1.0 = maximum blur
        tint_intensity = 0.3; # 0.0 = no tint, 1.0 = fully opaque tint
      };

      accessibility.ui_scale = 1.0;

      bar.main = {
        background_opacity = 1.0;
        start = [
          "control-center"
          "workspaces"
          "cpu"
          "active_window"
        ];
        center = [
          "media"
          "spacer"
          "clock"
        ];
        end = [
          "tray"
          "wallhaven"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "notifications"
          "session"
        ];
        margin_edge = 0;
        margin_ends = 0;
        position = "top";
        radius = 9;
        radius_top_left = 0;
        radius_top_right = 0;
        reserve_space = true;
        thickness = 34;
      };

      brightness.enable_ddcutil = true;

      idle = {
        pre_action_fade_seconds = 2.0;
        behavior = {
          lock = {
            action = "lock";
            enabled = true;
            timeout = 300;
          };
          screen-off = {
            action = "screen_off";
            enabled = true;
            timeout = 330;
          };
          suspend = {
            action = "lock_and_suspend";
            enabled = true;
            timeout = 900;
          };
        };
      };

      location = {
        address = "Shanghai";
        auto_locate = false;
      };

      lockscreen = {
        blur_intensity = 0.5;
        blurred_desktop = true;
        enabled = true;
        tint_intensity = 0.3;
      };

      nightlight = {
        enabled = true;
        force = false;
        temperature_day = 6500;
        temperature_night = 4000;
      };

      notification = {
        enable_daemon = true;
        show_actions = true;
      };

      plugins = {
        auto_update = "all";
        enabled = [ "noctalia/wallhaven" ];
      };

      shell = {
        clipboard_enabled = true;
        clipboard_history_max_entries = 100;
        date_format = "%A, %x";
        font_family = "sans-serif";
        launch_apps_as_systemd_services = true;
        polkit_agent = true;
        settings_show_advanced = true;
        telemetry_enabled = false;
        time_format = "{:%H:%M}";

        panel = {
          clipboard_placement = "attached";
          open_near_click_control_center = true;
          open_near_click_clipboard = true;
          open_near_click_wallpaper = true;
        };

        launcher = {
          categories = true;
          show_icons = true;
          sort_by_usage = true;
        };

        screenshot = {
          confirm_region = true; # confirm region captures with Enter or Space
          annotate = true; # open the annotator before saving or copying
        };
      };

      theme = {
        builtin = "Noctalia";
        mode = "auto";
        source = "wallpaper";
        templates = {
          builtin_ids = [
            "gtk3"
            "gtk4"
            "qt"
          ];
          enable_builtin_templates = true;
        };
      };

      wallpaper = {
        directory = "~/Pictures/Wallpapers";
        enabled = true;
        fill_mode = "crop";
      };

      widget = {
        disk = {
          path = "/";
          stat = "disk_used_pct";
          type = "sysmon";
        };
        gpu = {
          stat = "gpu_usage";
          type = "sysmon";
        };
        wallhaven.type = "noctalia/wallhaven:wallhaven";
        spacer.anchor = true;
        clock = {
          format = "{:%H:%M} {:%d/%m}";
          vertical_format = "{:%H:%M}";
          tooltip_format = "{:%A, %B %d, %Y}";
        };
      };
    };
  };
}
