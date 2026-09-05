{ pkgs, ... }:

{
  packages = with pkgs; [
    kitty
    kitty-themes
    xdg-terminal-exec
  ];
  xdg.config.files = {
    "fish/conf.d/10-kitty-integration.fish" = {
      clobber = true;
      text = ''
        if set -q KITTY_INSTALLATION_DIR
          source ${pkgs.kitty.shell_integration}/fish/vendor_conf.d/kitty-shell-integration.fish
          set --prepend fish_complete_path ${pkgs.kitty.shell_integration}/fish/vendor_completions.d
        end
      '';
    };
    "xdg-terminals.list" = {
      clobber = true;
      text = "kitty.desktop\n";
    };
    "kitty/kitty.conf" = {
      clobber = true;
      text = ''
        font_family JetBrains Mono
        font_size 12
        confirm_os_window_close 0
        enable_audio_bell no
        shell_integration no-rc
        allow_remote_control yes
        listen_on unix:@mykitty
        background_opacity 0.88
        dynamic_background_opacity yes
        background_blur 32
      '';
    };
    "kitty/dark-theme.auto.conf" = {
      clobber = true;
      text = ''
        include ${pkgs.kitty-themes}/share/kitty-themes/themes/Catppuccin-Mocha.conf
      '';
    };
    "kitty/light-theme.auto.conf" = {
      clobber = true;
      text = ''
        include ${pkgs.kitty-themes}/share/kitty-themes/themes/Catppuccin-Latte.conf
      '';
    };
    "kitty/no-preference-theme.auto.conf" = {
      clobber = true;
      text = ''
        include ${pkgs.kitty-themes}/share/kitty-themes/themes/Catppuccin-Latte.conf
      '';
    };
  };
}
