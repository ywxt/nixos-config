{ pkgs, ... }:

{
  programs.niri.enable = true;

  programs.uwsm.enable = true;

  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.udisks2.enable = true;
  security.polkit.enable = true;

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
        "JetBrain Mono"
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
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      material-symbols
      lxgw-wenkai-tc
    ];
  };
}
