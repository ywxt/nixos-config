{ pkgs, ... }:

{
  programs.niri.enable = true;
  programs.uwsm.enable = true;

  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  xdg.portal.xdgOpenUsePortal = true;

  fonts = {
    fontDir.enable = true;
    fontconfig.defaultFonts = {
      sansSerif = [
        "Noto Sans"
        "Noto Sans CJK SC"
      ];
      serif = [
        "Noto Serif"
        "Noto Serif CJK SC"
      ];
      monospace = [
        "JetBrains Mono"
        "Noto Sans Mono CJK SC"
      ];
    };
    packages = with pkgs; [
      iosevka
      jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.symbols-only
      material-symbols
      lxgw-wenkai-tc
    ];
  };
}
