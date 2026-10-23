{
  config,
  pkgs,
  ...
}:

let
  qtctConfig = version: ''
    [Appearance]
    color_scheme_path=${config.xdg.config.directory}/qt${version}ct/colors/noctalia.conf
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
  packages = [
    pkgs.libsForQt5.qt5ct
    pkgs.qt6Packages.qt6ct
    pkgs.kdePackages.qtstyleplugin-kvantum
    pkgs.colloid-kvantum
  ];

  xdg.config.files = {
    "qt5ct/qt5ct.conf" = {
      clobber = true;
      text = qtctConfig "5";
    };
    "qt6ct/qt6ct.conf" = {
      clobber = true;
      text = qtctConfig "6";
    };

    "Kvantum/kvantum.kvconfig" = {
      clobber = true;
      text = ''
        [General]
        theme=Colloid
      '';
    };
    "Kvantum/Colloid" = {
      clobber = true;
      source = "${pkgs.colloid-kvantum}/share/Kvantum/Colloid";
    };
    "Kvantum/ColloidNord" = {
      clobber = true;
      source = "${pkgs.colloid-kvantum}/share/Kvantum/ColloidNord";
    };
  };
}
