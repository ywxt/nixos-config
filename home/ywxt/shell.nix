{ pkgs, ... }:

{
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        if status is-login
          if uwsm check may-start
            exec uwsm select
            exec uwsm start default
          end
        end
      '';
      shellAliases = {
        ll = "ls -alh";
        rebuild = "sudo nixos-rebuild switch --flake $HOME/nixos-config#(hostname)";
        update = "nix flake update --flake $HOME/nixos-config";
      };
    };

    starship.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      settings.user.name = "ywxt";
      settings.user.email = "ywxtcwh@gmail.com";
      settings.credential.helper = [ "oauth" ];
    };
    kitty = {
      enable = true;
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 12;
      };
      settings = {
        confirm_os_window_close = 0;
        enable_audio_bell = false;
      };
    };
  };

  home.sessionPath = [ "$HOME/.cargo/bin" "$HOME/.local/bin" ];
  home.sessionVariables = {
    BROWSER = "firefox";
    EDITOR = "nvim";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    TERMINAL = "kitty";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}
