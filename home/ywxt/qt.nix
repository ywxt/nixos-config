{ config, inputs, pkgs, ... }:

let
  colloidKvantum = pkgs.callPackage ../../pkgs/colloid-kvantum.nix {
    src = inputs.colloid-kde;
    version = inputs.colloid-kde.shortRev or "unstable";
  };

  qtctConfig = version: ''
    [Appearance]
    color_scheme_path=${config.xdg.configHome}/qt${version}ct/colors/noctalia.conf
    custom_palette=true
    icon_theme=Tela-circle
    standard_dialogs=default
    style=kvantum-dark

    [Fonts]
    fixed="Noto Sans,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
    general="Noto Sans,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"

    [Interface]
    activate_item_on_single_click=1
    buttonbox_layout=0
    cursor_flash_time=1000
    dialog_buttons_have_icons=2
    double_click_interval=400
    gui_effects=@Invalid()
    keyboard_scheme=2
    menus_have_icons=true
    show_shortcuts_in_context_menus=true
    stylesheets=@Invalid()
    toolbutton_style=4
    underline_shortcut=2
    wheel_scroll_lines=3

    [Troubleshooting]
    force_raster_widgets=1
    ignored_applications=@Invalid()
  '';
in
{
  home.packages = [ colloidKvantum ];

  xdg.configFile = {
    "qt5ct/qt5ct.conf".text = qtctConfig "5";
    "qt6ct/qt6ct.conf".text = qtctConfig "6";

    "Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Colloid
    '';
    "Kvantum/Colloid".source = "${colloidKvantum}/share/Kvantum/Colloid";
    "Kvantum/ColloidNord".source = "${colloidKvantum}/share/Kvantum/ColloidNord";
  };
}
