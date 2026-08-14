{ inputs, pkgs, ... }:

let
  rimeHuma = pkgs.callPackage ../../pkgs/rime-huma.nix {
    src = inputs.rime-huma;
    version = inputs.rime-huma.shortRev or "unstable";
  };

  fcitx5RimeHuma = pkgs.fcitx5-rime.override {
    rimeDataPkgs = [
      pkgs.rime-data
      rimeHuma
    ];
  };
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5RimeHuma
        fcitx5-gtk
        fcitx5-fluent
      ];

      settings = {
        globalOptions = {
          Hotkey = {
            EnumerateWithTriggerKeys = true;
            EnumerateSkipFirst = false;
            ModifierOnlyKeyTimeout = 250;
          };
          "Hotkey/TriggerKeys" = {
            "0" = "Control+space";
            "1" = "Zenkaku_Hankaku";
            "2" = "Hangul";
          };
          "Hotkey/ActivateKeys"."0" = "Hangul_Hanja";
          "Hotkey/DeactivateKeys"."0" = "Hangul_Romaja";
          "Hotkey/AltTriggerKeys"."0" = "Shift_L";
          "Hotkey/EnumerateGroupForwardKeys"."0" = "Super+space";
          "Hotkey/EnumerateGroupBackwardKeys"."0" = "Shift+Super+space";
          "Hotkey/PrevPage"."0" = "Up";
          "Hotkey/NextPage"."0" = "Down";
          "Hotkey/PrevCandidate"."0" = "Shift+Tab";
          "Hotkey/NextCandidate"."0" = "Tab";
          "Hotkey/TogglePreedit"."0" = "Control+Alt+P";
          Behavior = {
            ActiveByDefault = false;
            resetStateWhenFocusIn = "No";
            ShareInputState = "No";
            PreeditEnabledByDefault = true;
            ShowInputMethodInformation = true;
            showInputMethodInformationWhenFocusIn = false;
            CompactInputMethodInformation = true;
            ShowFirstInputMethodInformation = true;
            DefaultPageSize = 5;
            OverrideXkbOption = false;
            PreloadInputMethod = true;
            AllowInputMethodForPassword = false;
            ShowPreeditForPassword = false;
            AutoSavePeriod = 30;
          };
        };

        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "rime";
          };
          "Groups/0/Items/0" = {
            Name = "rime";
            Layout = "";
          };
          GroupOrder."0" = "Default";
        };

        addons.classicui.globalSection = {
          "Vertical Candidate List" = false;
          WheelForPaging = true;
          Font = "Sans 10";
          MenuFont = "Sans 10";
          TrayFont = "Sans Bold 10";
          TrayOutlineColor = "#000000";
          TrayTextColor = "#ffffff";
          PreferTextIcon = true;
          ShowLayoutNameInIcon = true;
          UseInputMethodLanguageToDisplayText = true;
          Theme = "FluentLight";
          DarkTheme = "FluentDark";
          UseDarkTheme = true;
          UseAccentColor = true;
          PerScreenDPI = false;
          ForceWaylandDPI = 0;
          EnableFractionalScale = true;
        };
      };
    };
  };

  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      schema_list:
        - schema: huma_trad
        - schema: luna_pinyin
  '';
}
